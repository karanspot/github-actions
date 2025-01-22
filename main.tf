provider "aws" {
  region = "us-west-2"  # Specify your desired AWS region here
}

resource "aws_instance" "example" {
  ami             = "ami-0c55b159cbfafe1f0"  # Replace with your desired AMI ID
  instance_type   = "t2.micro"               # Specify the instance type
  key_name        = var.key_name             # SSH key pair name
  security_groups = [aws_security_group.instance.id]  # Reference to the security group

  # Adding user data to run a script at launch
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello, World from $(hostname -f)" > /var/www/html/index.html
              EOF

  tags = {
    Name = "ExampleInstance"
  }
}

resource "aws_security_group" "instance" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (Not recommended for production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.example.id
}
