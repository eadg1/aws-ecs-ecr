provider "aws" {
  version = "~> 3.0"
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}


resource "aws_alb" "nginx-load-balancer" {
    name                = "nginx-load-balancer"
    subnets	        = [aws_subnet.public-subnet-us-east-1a.id, aws_subnet.public-subnet-us-east-1b.id]
    security_groups     = ["${aws_security_group.test_public_sg.id}"]
}


resource "aws_alb_target_group" "nginx-target-group" {
    name                = "nginx-target-group"
    port                = "80"
    protocol            = "HTTP"
    vpc_id              = aws_vpc.default.id
    depends_on          = [aws_alb.nginx-load-balancer]
}

resource "aws_alb_listener" "alb-listener" {
    load_balancer_arn = aws_alb.nginx-load-balancer.arn
    port              = "80"
    protocol          = "HTTP"
    default_action {
        target_group_arn = aws_alb_target_group.nginx-target-group.arn
        type             = "forward"
    }
}



resource "aws_launch_configuration" "nginx-launch-configuration" {
    name                        = "nginx-launch-configuration"
    image_id                    = "ami-09bee01cc997a78a6"
    instance_type               = "t2.micro"
    iam_instance_profile        = aws_iam_instance_profile.nginx-instance-profile.id
    root_block_device {
      volume_type = "standard"
      volume_size = 100
      delete_on_termination = true
    }

    lifecycle {
      create_before_destroy = true
    }

    security_groups             = [aws_security_group.test_public_sg.id]
    associate_public_ip_address = "true"
    key_name                    = var.key_name
    user_data                   = <<EOF
                                  #!/bin/bash
                                  echo ECS_CLUSTER=${aws_ecs_cluster.nginx-cluster.name}  >> /etc/ecs/ecs.config
                                  EOF
}

resource "aws_ecs_task_definition" "nginx-task" {
  family                = "application-stack"
  container_definitions = file("tasks/task-nginx.json")
  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }
}


resource "aws_ecs_cluster" "nginx-cluster" {
  name = "nginx-cluster-1"
}

resource "aws_autoscaling_group" "nginx-autoscaling-group" {
  name             = "nginx-autoscaling-group"
  max_size         = "1"
  min_size         = "1"
  desired_capacity = "1"
  vpc_zone_identifier = [aws_subnet.public-subnet-us-east-1a.id,aws_subnet.public-subnet-us-east-1b.id]
  launch_configuration = aws_launch_configuration.nginx-launch-configuration.name
  health_check_type    = "EC2"
  default_cooldown     = "300"
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_policy" "nginx-scale" {
  name                      = "nginx-scale-policy"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.nginx-autoscaling-group.name
  estimated_instance_warmup = 60

  target_tracking_configuration {
        predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = "70"
  }
}

resource "aws_ecs_service" "nginx-service" {
  name            = "nginx"
  cluster         = aws_ecs_cluster.nginx-cluster.id
  task_definition = aws_ecs_task_definition.nginx-task.arn
  desired_count   = 1
  launch_type     = "EC2"
  load_balancer {
	  target_group_arn  = aws_alb_target_group.nginx-target-group.arn
	  container_port    = 80
	  container_name    = "nginx"
    }

  depends_on = [aws_ecs_task_definition.nginx-task]

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }
}
