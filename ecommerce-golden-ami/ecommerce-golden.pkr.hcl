packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.3.0"
    }
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region where the Golden AMI will be created."
  default     = "ap-south-1"
}

source "amazon-ebs" "ecommerce" {
  region        = var.aws_region
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  ami_name = "ecommerce-golden-${formatdate("YYYYMMDD-hhmm", timestamp())}"

  tags = {
    Name        = "ecommerce-golden"
    Project     = "ecommerce-golden-ami"
    ManagedBy   = "Packer"
    ImageType   = "GoldenAMI"
  }
}

build {
  name    = "ecommerce-golden"
  sources = ["source.amazon-ebs.ecommerce"]

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx curl",
      "sudo mkdir -p /tmp/ecommerce-app && sudo chown ubuntu:ubuntu /tmp/ecommerce-app"
    ]
  }

  provisioner "file" {
    source      = "app/"
    destination = "/tmp/ecommerce-app/"
  }

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo cp -r /tmp/ecommerce-app/. /var/www/html/",
      "sudo nginx -t",
      "sudo systemctl enable nginx",
      "sudo systemctl restart nginx",
      "curl --fail http://127.0.0.1/health.html"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
