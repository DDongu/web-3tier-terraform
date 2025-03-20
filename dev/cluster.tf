# cluster.tf

# 보안 그룹 생성
## 인스턴스 보안그룹
resource "aws_security_group" "webapp_sg" {
  name = "webapp-sg-tobyN"
  vpc_id = aws_vpc.dev_vpc.id

  ingress {
    from_port = var.app_port
    to_port = var.app_port
    protocol = "tcp"
    security_groups = [ aws_security_group.alb_sg_app.id ]
  }
}

resource "aws_security_group" "webserver_sg" {
  name = "webserver-sg-tobyN"
  vpc_id = aws_vpc.dev_vpc.id

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    security_groups = [ aws_security_group.alb_sg_server.id ]
  }
}

## ALB 보안그룹
resource "aws_security_group" "alb_sg_app" {
  name = var.app_alb_security_group_name
  vpc_id = aws_vpc.dev_vpc.id

  ingress {
    from_port = var.app_port
    to_port = var.app_port
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

    ### HTTPS 설정 추가 필요

  egress {
    from_port = 0                   # 모든 트래픽 허용
    to_port = 0                     # 모든 트래픽 허용
    protocol = "-1"                 # 모든 프로토콜 허용
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_security_group" "alb_sg_server" {
  name = var.server_alb_security_group_name
  vpc_id = aws_vpc.dev_vpc.id

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    security_groups = [ aws_security_group.webapp_sg.id ]
  }

  egress {
    from_port = 0                   # 모든 트래픽 허용
    to_port = 0                     # 모든 트래픽 허용
    protocol = "-1"                 # 모든 프로토콜 허용
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

# 시작 템플릿 생성
resource "aws_launch_template" "webapp_template" {
  image_id = "ami-0dcb222f6a75cf8bd"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.webapp_sg.id]
}

resource "aws_launch_template" "webserver_template" {
  image_id = "ami-0dcb222f6a75cf8bd"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
}

# Auto Scaling Group(ASG) 작성
resource "aws_autoscaling_group" "webapp_asg" {
  vpc_zone_identifier = [ aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id ]
  target_group_arns = [ aws_lb_target_group.target_asg_app.arn ] # ALB와 대상그룹 지정
  health_check_type = "ELB"

  min_size = 2
  max_size = 3
  launch_template {                # 확장 시 생성될 템플릿 지정
    id = aws_launch_template.webapp_template.id
    version = "$Latest"            # 가장 최신 버전의 템플릿 사용
  }
  depends_on = [ aws_vpc.dev_vpc, aws_subnet.pub_sub_1, aws_subnet.pub_sub_2 ]
}

resource "aws_autoscaling_group" "webserver_asg" {
  vpc_zone_identifier = [ aws_subnet.prv_nat_sub_1.id, aws_subnet.prv_nat_sub_2.id ]
  target_group_arns = [ aws_lb_target_group.target_asg_server.arn ] # ALB와 대상그룹 지정
  health_check_type = "ELB"

  min_size = 2
  max_size = 3
  launch_template {                # 확장 시 생성될 템플릿 지정
    id = aws_launch_template.webserver_template.id
    version = "$Latest"            # 가장 최신 버전의 템플릿 사용
  }
  depends_on = [ aws_vpc.dev_vpc, aws_subnet.prv_nat_sub_1, aws_subnet.prv_nat_sub_2 ]
}

# ALB 생성
## ALB 설정
resource "aws_lb" "webapp_alb" {
  name = var.app_alb_name
  load_balancer_type = "application"
  subnets = [ aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id ]
  security_groups = [ aws_security_group.alb_sg_app.id ]
}

resource "aws_lb" "webserver_alb" {
  name = var.server_alb_name
  load_balancer_type = "application"
  subnets = [ aws_subnet.prv_nat_sub_1.id, aws_subnet.prv_nat_sub_2.id ]
  security_groups = [ aws_security_group.alb_sg_server.id ]
}

## ALB 타겟 그룹
resource "aws_lb_target_group" "target_asg_app" {
  name = var.app_alb_name
  port = var.app_port
  protocol = "HTTP"
  vpc_id = aws_vpc.dev_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "target_asg_server" {
  name = var.server_alb_name
  port = var.server_port
  protocol = "HTTP"
  vpc_id = aws_vpc.dev_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

## 리스너
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webapp_alb.arn
  port = var.app_port
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_asg_app.arn
  }
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.webserver_alb.arn
  port = var.server_port
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_asg_server.arn
  }
}

## 리스너 규칙 지정
resource "aws_lb_listener_rule" "webapp_asg_rule" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
          values = ["*"]
        }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.target_asg_app.arn
    }
}

resource "aws_lb_listener_rule" "webserver_asg_rule" {
    listener_arn = aws_lb_listener.api.arn
    priority = 100

    condition {
        path_pattern {
          values = ["*"]
        }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.target_asg_server.arn
    }
}