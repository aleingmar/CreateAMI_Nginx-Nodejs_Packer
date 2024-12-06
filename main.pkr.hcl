# Plantilla de Packer para crear una imagen para AWS con Ubuntu 20.04, Nginx y Node.js

########################################################################################################################
# PLUGINS: Define los plugins necesarios para la plantilla
# Para descargar el plugin necesario para la plantilla, levantar la imagen en VirtualBox
# se puede instalar tambien directamente con # packer plugins install github.com/hashicorp/virtualbox

packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Variables externas
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}
variable "ami_name" {}
variable "instance_type" {}
variable "project_name" {}
variable "environment" {}
##########################################################################################################
# BUILDER: Define cómo se construye la AMI en AWS
# source{}--> define el sistema base sobre el que quiero crear la imagen (ISO ubuntu) y el proveeedor para el que creamos la imagen 
# (tecnologia con la que desplegará la imagen) --> AMAZON
source "amazon-ebs" "aws_builder" {
  access_key    = var.aws_access_key
  secret_key    = var.aws_secret_key
  region        = var.aws_region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners       = ["099720109477"]
    most_recent  = true
  }

  instance_type = var.instance_type
  ssh_username  = "ubuntu"
  ami_name      = "${var.ami_name}-${timestamp()}"
}


########################################################################################################################
# PROVISIONERS: Configura el sistema operativo y la aplicación
# build{}: Describe cómo se construirá la imagen --> Definir los provisioners para instalar y configurar software
build {
  name    = "aws-node-nginx"
  sources = ["source.amazon-ebs.aws_builder"]

  provisioner "shell" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y nginx",
      "curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -",
      "sudo apt install -y nodejs build-essential",
      "sudo npm install pm2@latest -g",
      "sudo ufw allow 'Nginx Full'",
      "sudo systemctl enable nginx"
    ]
  }

  provisioner "file" {
    source      = "provisioners/app.js"
    destination = "/home/ubuntu/app.js"
  }

  provisioner "shell" {
    inline = [
      "pm2 start /home/ubuntu/app.js",
      "pm2 save",
      "pm2 startup"
    ]
  }
}

####################################################################################################
##### PASOS PARA EJECUTAR
# packer validate template.pkr.hcl , VERIFICA SINTAXIS DE LA PLANTILLA
# packer inspect template.pkr.hcl, MUESTRA LA CONFIGURACIÓN DE LA PLANTILLA
# packer init template.pkr.hcl, descarga los plugins necesarios
# packer build -var-file=variables/variables.hcl main.pkr.hcl, GENERA LA IMAGEN A PARTIR DE LA PLANTILLA

