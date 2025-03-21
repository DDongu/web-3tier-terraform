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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 👈 본인의 퍼블릭 IP 입력 (ex. 203.0.113.1/32)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
## 키
resource "aws_launch_template" "webapp_template" {
  image_id = "ami-062cddb9d94dcf95d"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.webapp_sg.id]
  key_name = "aws-practice-key"

  # IAM Instance Profile 추가
  iam_instance_profile {
    name = aws_iam_instance_profile.codedeploy_instance_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # 업데이트 및 Docker 설치
    sudo yum update -y
    sudo amazon-linux-extras enable docker
    sudo yum install -y docker

    # Docker 서비스 실행 및 부팅 시 자동 실행 설정
    sudo systemctl start docker
    sudo systemctl enable docker

    # ec2-user를 Docker 그룹에 추가 (sudo 없이 사용 가능)
    sudo usermod -aG docker ec2-user

    # docker compose 설치
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose


    # Health Check를 통과하기 위한 임시 Nginx 컨테이너 실행 (포트 3000)
    docker run -d -p 3000:80 --name temp-nginx nginx

    # CodeDeploy Agent 설치 (Amazon Linux 2 기준)
    sudo yum update -y
    sudo yum install -y ruby wget
    cd /home/ec2-user
    wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
    chmod +x ./install
    sudo ./install auto

    # CodeDeploy Agent 시작 및 자동 실행 설정
    sudo service codedeploy-agent start
    sudo systemctl enable codedeploy-agent
  EOF
  )
}

resource "aws_launch_template" "webserver_template" {
  image_id = "ami-062cddb9d94dcf95d"
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

}

# Auto Scaling Group(ASG) 작성
resource "aws_autoscaling_group" "webapp_asg" {
  vpc_zone_identifier = [ aws_subnet.pub_sub_1.id, aws_subnet.pub_sub_2.id]
  # vpc_zone_identifier = [ aws_subnet.prv_nat_sub_1.id, aws_subnet.prv_nat_sub_2.id ]
  target_group_arns = [ aws_lb_target_group.target_asg_app.arn ] # ALB와 대상그룹 지정
  health_check_type = "ELB"

  min_size = 2
  max_size = 3

  tag {
    key                 = "CodeDeploy"
    value               = "true"
    propagate_at_launch = true  # ASG에서 생성된 모든 인스턴스에 태그 적용
  }

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

  # IAM Role 변경 시 자동으로 인스턴스 교체
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

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