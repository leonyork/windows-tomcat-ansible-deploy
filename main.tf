provider "aws" {
  region = var.region
}

resource "random_password" "password" {
  length = 32
  special = false
}

data "aws_ami" "windows" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-2019*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "windows" {
  ami           = data.aws_ami.windows.id
  instance_type = "t2.micro"

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
# Download Java
Invoke-WebRequest -Uri https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u232-b09/OpenJDK8U-jdk_x64_windows_hotspot_8u232b09.zip -Outfile java.zip
Expand-Archive -LiteralPath .\java.zip -DestinationPath C:\Java
Remove-Item -path .\java.zip
# Download Tomcat
Invoke-WebRequest -Uri http://mirrors.ukfast.co.uk/sites/ftp.apache.org/tomcat/tomcat-8/v8.5.50/bin/apache-tomcat-8.5.50-windows-x64.zip -OutFile tomcat.zip
Expand-Archive -LiteralPath .\tomcat.zip -DestinationPath C:\Tomcat
Remove-Item -path .\tomcat.zip
# Set the approriate environment variables
$env:CATALINA_HOME = "C:\Tomcat\apache-tomcat-8.5.50"
$env:JAVA_HOME = "C:\Java\jdk8u232-b09"
$env:PATH = "$env:PATH;$env:JAVA_HOME\bin;$env:CATALINA_HOME\bin"
# Export these as user environment variables
[System.Environment]::SetEnvironmentVariable('CATALINA_HOME', $env:CATALINA_HOME, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', $env:JAVA_HOME, [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('PATH', $env:PATH, [System.EnvironmentVariableTarget]::User)
# Install the Tomcat service and set it to automatically start
service.bat install
tomcat8 //US//Tomcat8 --Startup=auto
# Actually start the Tomcat service
tomcat8 start
# Update Windows firewall to allow incoming connections on port 8080
netsh advfirewall firewall add rule name="Tomcat on port 8080" dir=in action=allow protocol=TCP localport=8080
</powershell>
    EOF
}