output "public_ip" {
  value = "${aws_instance.windows.public_ip}"
}
output "password" {
  value = "${random_password.password.result}"
  sensitive = true
}
output "tomcat_location" {
  value = "${local.tomcat_location}"
}
output "tomcat_executable" {
  value = "${local.tomcat_executable}"
}