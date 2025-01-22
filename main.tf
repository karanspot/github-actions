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

# GitHub credentials  

github_user=<Your GitHub User>

github_repo=<Your GitHub Repository>

PAT=<Your GitHub Token>

# Download jq for extracting the Token  

yum install jq -y  

# Create and move to the working directory  

mkdir /actions-runner && cd /actions-runner  

# Download the latest runner package

curl -o actions-runner-linux-x64-2.304.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.304.0/actions-runner-linux-x64-2.304.0.tar.gz

# Extract the installer  

tar xzf ./actions-runner-linux-x64-2.304.0.tar.gz

# Change the owner of the directory to ec2-user  

chown ec2-user -R /actions-runner  

# Get instance id to set it as a runner name  

MetadataToken=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

instance_id=$(curl -H "X-aws-ec2-metadata-token: $MetadataToken" http://169.254.169.254/latest/meta-data/instance-id)

echo "$instance_id"

# Get the runner's token  

token=$(curl -s -XPOST -H "authorization: token $PAT" https://api.github.com/repos/$github_user/$github_repo/actions/runners/registration-token | jq -r .token)  

# Create the runner and start the configuration experience  

sudo -u ec2-user ./config.sh --url https://github.com/${github_user}/${github_repo} --token $token --name "${instance_id}" --labels spot --unattended

# Create the runner's service  

./svc.sh install  

# Start the service  

./svc.sh start
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
