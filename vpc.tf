resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "nginx-aws-vpc"
  }
}



resource "aws_internet_gateway" "My_web_GW" {
 vpc_id = aws_vpc.default.id
 tags = {
        Name = "webGW"
  }
}

resource "aws_route_table" "My_web_route_table" {
 vpc_id = aws_vpc.default.id
 tags = {
        Name = "main"
 }
}

resource "aws_main_route_table_association" "MainRoutinTable" {
  vpc_id         = aws_vpc.default.id
  route_table_id = aws_route_table.My_web_route_table.id
}


resource "aws_route" "My_web_inet" {
  route_table_id         = aws_route_table.My_web_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.My_web_GW.id
}




resource "aws_subnet" "public-subnet-us-east-1a" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet_cidr-1
  availability_zone = "us-east-1a"
  tags = {
    Name = "Public Subnet-1"
  }
} 



resource "aws_subnet" "public-subnet-us-east-1b" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.public_subnet_cidr-2
  availability_zone = "us-east-1b"
  tags = {
    Name = "Public Subnet-2"
  }
} 

