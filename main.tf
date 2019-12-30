provider "aws" {
  region = var.region
  version = "2.43"
}

provider "random" {
  version = "2.2"
}

resource "random_uuid" "security_group_unique_id" { }

resource "aws_security_group" "windows_tomcat" {
  name        = "windows-tomcat-${random_uuid.security_group_unique_id.result}"
  description = "Allow RDP, WinRM to Windows and port 8080 for Tomcat"
  # Add to the default VPC for now - if required change to be a different VPC
  #vpc_id      = "${aws_vpc.main.id}"

  # Tomcat webserver
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  # WinRM
  ingress {
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks  = ["${var.winrm_rdp_access_cidr}"]
  }

  # RDP
  # TODO: Ideally disable RDP and remove this ingress rule - however it's useful for testing/debugging
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${var.winrm_rdp_access_cidr}"]
  }

  # Currently need to allow egress to internet as we need to download java,tomcat, etc.
  # TODO: Create an AMI separately and use it here, then disallow egress
  egress {
    from_port         = 0
    to_port           = 0 #from_port (0) and to_port (65535) must both be 0 to use the 'ALL' "-1" protocol!
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }
}

resource "random_password" "password" {
  length = 32
  special = false
}

data "aws_ami" "windows" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.windows_version]
  }

  filter {
    name   = "platform"
    values = ["windows"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# Since the user_data script is run after the instance is created, we need to define these up-front so we can output
# them and use the later 
locals {
  tomcat_major_version = regex("^\\d+", var.tomcat_version)
  tomcat_location = "C:\\apache-tomcat-${var.tomcat_version}"
  tomcat_executable = "tomcat${local.tomcat_major_version}"
}

# TODO: Remove all the default deployed wars (e.g. ROOT, Manager). Need to update tests that will expect 200 back from
# curling 8080
resource "aws_instance" "windows" {
  ami           = data.aws_ami.windows.id
  instance_type = var.instance_type
  security_groups = ["${aws_security_group.windows_tomcat.name}"]

  connection {
    type = "winrm"
    user = "Administrator"
    password = random_password.password.result
  }

  user_data = <<EOF
<powershell>
# Set the administrator password
net user Administrator "${random_password.password.result}"

# By default Windows uses TLS v1. We should use v1.2 (Note that some sites will not allow connections with v1)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Allow ansible access over winrm
Invoke-WebRequest -Uri https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 -OutFile ConfigureRemotingForAnsible.ps1
powershell -ExecutionPolicy RemoteSigned .\ConfigureRemotingForAnsible.ps1
Remove-Item -path .\ConfigureRemotingForAnsible.ps1

# Install Chocolatey to make further installations easier
$env:chocolateyVersion = '${var.chocolatey_version}'
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Java
$version='${var.java_version}'
# Get the major version number
$version -match '^(\d+)+'
$major_version=$matches[0]
choco install openjdk$major_version --version $version -y
refreshenv

# Download Tomcat - Unable to install using choco at the minute
$version='${var.tomcat_version}'
$major_version='${local.tomcat_major_version}'
Invoke-WebRequest -Uri http://mirrors.ukfast.co.uk/sites/ftp.apache.org/tomcat/tomcat-$${major_version}/v$${version}/bin/apache-tomcat-$${version}-windows-x64.zip -OutFile tomcat.zip
Expand-Archive -LiteralPath .\tomcat.zip -DestinationPath C:\
Remove-Item -path .\tomcat.zip

# Set the approriate environment variables
$env:CATALINA_HOME = "${local.tomcat_location}"
$env:JAVA_HOME = Get-ChildItem -Path 'C:\Program Files\OpenJDK' -Directory | Select-Object FullName | foreach {$_.FullName}
$env:PATH = "$env:PATH;$env:JAVA_HOME\bin;$env:CATALINA_HOME\bin"

# Export these as user environment variables
[System.Environment]::SetEnvironmentVariable('CATALINA_HOME', $env:CATALINA_HOME, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', $env:JAVA_HOME, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('PATH', $env:PATH, [System.EnvironmentVariableTarget]::User)

# Install the Tomcat service and set it to automatically start
service.bat install
${local.tomcat_executable} //US// --Startup=auto
# Actually start the Tomcat service
${local.tomcat_executable} start

# Update Windows firewall to allow incoming connections on port 8080
netsh advfirewall firewall add rule name="Tomcat on port 8080" dir=in action=allow protocol=TCP localport=8080
</powershell>
    EOF
}