output "password" {
  value = "${random_uuid.password.result}"
}
output "public_ip" {
  value = "${aws_instance.windows.public_ip}"
}