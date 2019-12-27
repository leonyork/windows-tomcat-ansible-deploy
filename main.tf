provider "aws" {
  region = "${var.region}"
}

resource "random_uuid" "password" { }

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
  ami           = "${data.aws_ami.windows.id}"
  instance_type = "t2.micro"

  connection {
    type = "winrm"
    user = "Administrator"
    password = "${random_uuid.password.result}"
  }

  user_data = <<EOF
<powershell>
net user Administrator "${random_uuid.password.result}"
Invoke-WebRequest -Uri https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 -OutFile ConfigureRemotingForAnsible.ps1
powershell -ExecutionPolicy RemoteSigned .\ConfigureRemotingForAnsible.ps1
</powershell>
    EOF
}