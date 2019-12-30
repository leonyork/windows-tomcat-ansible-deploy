variable "region" {
  default = "us-east-1"
}
variable "instance_type" {
  default = "t3a.medium"
}
variable "chocolatey_version" {
}
variable "java_version" {
}
variable "tomcat_version" {
}
variable "windows_version" {
}
variable "winrm_rdp_access_cidr" {
  default = "0.0.0.0/0"
}
