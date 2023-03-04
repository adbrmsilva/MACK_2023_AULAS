###
# Código acima define dois provedores, um para cada região. O alias atribui um nome ao provedor secundário para que possa ser referenciado mais tarde.
###

provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "secondary"
  region = "eu-west-1"
}

###
# Definição de recursos para criar a VPC, subnets e Internet Gateway na região primária, cria uma VPC com CIDR 10.0.0.0/16 e três subnets em cada zona.
###

resource "aws_vpc" "primary" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "primary_a" {
  vpc_id     = aws_vpc.primary.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "primary_b" {
  vpc_id     = aws_vpc.primary.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_subnet" "primary_c" {
  vpc_id     = aws_vpc.primary.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2c"
}

resource "aws_internet_gateway" "primary" {
  vpc_id = aws_vpc.primary.id
}

resource "aws_instance" "ec2_primary_a" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.primary_a.id
}

resource "aws_instance" "ec2_primary_b" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.primary_b.id
}

###
# Definição de recursos para criar as instâncias EC2, banco de dados RDS e balanceador de carga na região primária
###

resource "aws_db_instance" "postgres_primary" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "12.4"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "myuser"
  password             = "_password"
  skip_final_snapshot  = true
  subnet_group_name    = "postgres-subnet-group"
  vpc_security_group_ids = [aws_security_group.rds.id]
}

resource "aws_lb" "primary" {
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.primary_a.id, aws_subnet.primary_b.id, aws_subnet.primary_c.id]

  tags = {
    Name = "primary-lb"
  }
}

###
# Security Group para cada recurso utilizado no projeto
###
resource "aws_security_group" "ec2" {
  name_prefix = "ec2-sgrp-"
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "rds-sgrp-"
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb" {
  name_prefix = "lb-http-sgrp-"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb" {
  name_prefix = "lb-https-sgrp-"
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }
}