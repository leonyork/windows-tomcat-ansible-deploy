output "public_ip" {
  value = "${aws_instance.windows.public_ip}"
}
output "password" {
  value = "${random_password.password.result}"
  sensitive = true
}