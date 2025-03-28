resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2-key"  # Name of the key pair in AWS
  public_key = tls_private_key.ec2_key.public_key_openssh

  provisioner "local-exec" {
    command = "chmod 400 ec2-key.pem"
  }
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
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo docker run -d -p 80:80 --name httpbin kennethreitz/httpbin
              # Ensure directories necessary for the installation of
              # a cloudflare CA signed cert exists 
              mkdir -p /etc/ssl/certs
              chown ec2-user:ec2-user /etc/ssl/certs
              chmod 755 /etc/ssl/certs
              EOF

  tags = {
    Name = "Origin-Server"
  }
}

resource "aws_vpc" "default" {
  cidr_block = "172.31.0.0/16"
}

resource "aws_subnet" "default_subnet" {
  vpc_id                  = aws_vpc.default.id 
  cidr_block              = "172.31.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Default-Subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "Main-IGW"
  }
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "Main-Route-Table"
  }
}

resource "aws_route_table_association" "main_assoc" {
  subnet_id      = aws_subnet.default_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.default.id 

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

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere, adjust as needed
  }

  # Egress: Allow outgoing traffic on port 443
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow to anywhere, adjust as needed
  }
}

resource "cloudflare_dns_record" "origin" {
  zone_id = var.zone_id 
  name    = "origina.${var.domain}"
  content = aws_instance.web.public_ip
  type    = "A"
  proxied = true  # Traffic proxied through Cloudflare
  ttl     = 1	    # Must be set to 1 when cloudflare is used as a proxy 
}
