# Add your VPC ID to default below
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-03485467"
}


provider "aws" {
  region = "us-west-2"
}

#create internet gateway

resource "aws_internet_gateway" "gw" {
    vpc_id = "${var.vpc_id}"

    tags = {
      Name = "default_ig"
  }
}

#create public routing table

resource "aws_route_table" "public_routing_table" {
    vpc_id = "${var.vpc_id}"
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

    tags {
     Name = "public_routing_table"
  }
}

#create public subnet a

resource "aws_subnet" "public_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.0.0/24"
    availability_zone = "us-west-2a"

    tags {
      Name = "public_a"
    }
}

#create public subnet b

resource "aws_subnet" "public_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.1.0/24"
    availability_zone = "us-west-2b"

    tags {
        Name = "public_b"
    }
}

#create public subnet c

resource "aws_subnet" "public_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.2.0/24"
    availability_zone = "us-west-2c"

    tags {
        Name = "public_c"
    }
}

# create route association for public subnets

resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_b.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_c.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

#create eip for nat gateway

resource "aws_eip" "nat_eip" {
    vpc = true
}

#create NAT gateway

resource "aws_nat_gateway" "nat" {
    allocation_id = "${aws_eip.nat_eip.id}"
    subnet_id = "${aws_subnet.private_subnet_a.id}"
}

#create private routing table

resource "aws_route_table" "private_routing_table" {
    vpc_id = "${var.vpc_id}"
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_nat_gateway.nat.id}"
  }

    tags {
      Name = "private_routing_table"
  }
}

#create private subnet a

resource "aws_subnet" "private_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.4.0/22"
    availability_zone = "us-west-2a"

    tags {
        Name = "private_a"
    }
}

#create private subnet b

resource "aws_subnet" "private_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.8.0/22"
    availability_zone = "us-west-2b"

    tags {
        Name = "private_b"
    }
}

#create private subnet c

resource "aws_subnet" "private_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.12.0/22"
    availability_zone = "us-west-2c"

    tags {
        Name = "private_c"
    }
}

#create route association subnet tables

resource "aws_route_table_association" "private_subnet_a_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_a.id}"
    route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_b_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_b.id}"
    route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_c_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    route_table_id = "${aws_route_table.private_routing_table.id}"
}

#create security to allow access from current ip address on port 22

resource "aws_security_group" "ssh" {
    name = "ssh"

    ingress {
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = ["192.168.0.4/29"]
  }
   
}

#create bastion instance

resource "aws_instance" "bastion" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    security_groups = ["${aws_security_group.ssh.id}"]
    key_name = "cit360"
    associate_public_ip_address = true
}
