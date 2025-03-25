resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2-key"  # Name of the key pair in AWS
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.ec2_key.private_key_pem
  filename = "ec2-key.pem"
}

resource "aws_instance" "web" {
  ami                         = var.ami     # Amazon Linux 2 AMI (Change for your region)
  instance_type               = "t2.micro"
  key_name                    = "ec2-key"  # Ensure you have an SSH key
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.default_subnet.id
  vpc_security_group_ids      = [ aws_security_group.web_sg.id ] 

  user_data = <<-EOF
              #!/bin/bash
              yum install -y docker
              service docker start
              docker run -d -p 80:80 --name httpbin kennethreitz/httpbin
              EOF

  tags = {
    Name = "Origin-Server"
  }
}

resource "aws_subnet" "default_subnet" {
  vpc_id                  = "vpc-06264769314079f22"
  cidr_block              = "172.31.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Default-Subnet"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH"
  vpc_id      = "vpc-06264769314079f22"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["173.245.48.0/20",
                   "103.21.244.0/22",
                   "103.22.200.0/22",
                   "103.31.4.0/22",
                   "141.101.64.0/18",
                   "108.162.192.0/18",
                   "190.93.240.0/20",
                   "188.114.96.0/20",
                   "197.234.240.0/22",
                   "198.41.128.0/17",
                   "162.158.0.0/15",
                   "104.16.0.0/13",
                   "104.24.0.0/14",
                   "172.64.0.0/13",
                   "131.0.72.0/22" 
                  ]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict SSH access in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "cloudflare_dns_record" "origin" {
  zone_id = var.zone_id 
  name    = "origina.${var.domain}"
  content = aws_instance.web.public_ip
  type    = "A"
  proxied = true  # Traffic proxied through Cloudflare
  ttl     = 1	  # Muat be set to 1 when cloudflare is used as a proxy 
}
