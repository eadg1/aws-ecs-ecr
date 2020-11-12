resource "aws_security_group" "test_public_sg" {
  vpc_id=aws_vpc.default.id
  name="allow_http"
  ingress {
    protocol   = "tcp"
    from_port=0
    to_port    = 65535
    cidr_blocks = ["10.10.14.0/24","10.10.15.0/24"]
  }

  ingress {
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    protocol   = "tcp"
    from_port  = 0
    to_port    = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_iam_role" "ecs-service-role" {
    name                = "ecs-service-role"
    path                = "/"
    assume_role_policy  = data.aws_iam_policy_document.ecs-service-policy.json
}


resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
    role       = aws_iam_role.ecs-service-role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
    }

data "aws_iam_policy_document" "ecs-service-policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type        = "Service"
            identifiers = ["ecs.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "ecs-instance-role" {
    name                = "ecs-instance-role"
    path                = "/"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
       {
          "Action": "sts:AssumeRole",
          "Principal": {
          "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
     }
    ]
}
   EOF
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
    role       = aws_iam_role.ecs-instance-role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "nginx-instance-profile" {
    name = "ecs-instance-profile"
    path = "/"
    role = aws_iam_role.ecs-instance-role.name
}