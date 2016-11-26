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
          cidr_blocks = ["45.48.86.41/32"]
  }
    egress {
         from_port = 0
         to_port = 0
         protocol = "-1"
         cidr_blocks = ["0.0.0.0/0"]

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

#create security group for RDS instances

resource "aws_security_group" "rds_sg" {
    ingress {
          from_port = 3306
          to_port = 3306
          protocol = "tcp"
          cidr_blocks = ["172.31.0.0/16"]
  }


}

#create private subnet group

resource "aws_db_subnet_group" "db_sub_group" {
    name = "main"
    subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]

    tags {
      Name = "db_sub_group"
  }
}

#create database instance

resource "aws_db_instance" "rds_db" {
    identifier           = "rds-db"
    engine               = "mariadb"
    engine_version       = "10.0.24"
    instance_class       = "db.t2.micro"
    multi_az             = false
    storage_type         = "gp2"
    allocated_storage    = 5
    username             = "jzd914"
    password             = "${var.rds_passwd}"
    db_subnet_group_name = "${aws_db_subnet_group.db_sub_group.id}"
    vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]

    tags {
       Name = "RDS_db" 
 }

}

#create security group for web instances

resource "aws_security_group" "web_sg" {
    name = "web-sg"
    ingress {
          from_port = 80
          to_port = 80
          protocol = "tcp"
          cidr_blocks = ["172.31.0.0/16"]
 }

    ingress {
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = ["172.31.0.0/16"]
 }
     egress {
         from_port = 0
         to_port = 0
         protocol = "-1"
         cidr_blocks = ["0.0.0.0/0"]

 }


}

#create security group for elastic load balancer 

resource "aws_security_group" "elb_sg" {
    name = "elb-sg"

    ingress {
          from_port = 80
          to_port = 80
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
 }
    egress {
         from_port = 0
         to_port = 0
         protocol = "-1"
         cidr_blocks = ["0.0.0.0/0"]

 }
}

#create elastic load balancer for web public subnets

resource "aws_elb" "web_elb" {
    name = "web-elb"
    subnets = ["${aws_subnet.public_subnet_b.id}", "${aws_subnet.public_subnet_c.id}"]
    security_groups = ["${aws_security_group.elb_sg.id}"]
 
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
} 
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "http:80/"
    interval = 30
} 

  instances = ["${aws_instance.web_2b.id}", "${aws_instance.web_2c.id}"]
  connection_draining = true
  connection_draining_timeout = 60

 
  tags {
    Name = "Load Balancer"

 }
}

#create webserver 2b instance

resource "aws_instance" "web_2b" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.private_subnet_b.id}"
    key_name = "cit360"
    associate_public_ip_address = false
    vpc_security_group_ids = ["${aws_security_group.web_sg.id}"]
    tags {
        Name = "web_2b"
        Service = "curriculum"
 }

}

#create webserver 2c instance

resource "aws_instance" "web_2c" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    key_name = "cit360"
    associate_public_ip_address = false
    vpc_security_group_ids = ["${aws_security_group.web_sg.id}"]
    tags {
        Name = "web_2c"
        Service = "curriculum"
 }

}

