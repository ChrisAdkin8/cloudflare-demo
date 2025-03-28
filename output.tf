output "scp_to_ec2_commands" {
  value = <<EOF
scp -i ec2-key.pem key.pem ec2-user@${aws_instance.web.public_ip}:/etc/ssl/certs/
scp -i ec2-key.pem cert.pem ec2-user@${aws_instance.web.public_ip}:/etc/ssl/certs/
scp -i ec2-key.pem httpd_bin.sh ec2-user@${aws_instance.web.public_ip}:/home/ec2_user/
EOF
}
