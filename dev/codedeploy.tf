# CodeDeploy 애플리케이션 생성
resource "aws_codedeploy_app" "docker_app" {
  name = var.docker_webapp_codedeploy_name
  compute_platform = "Server"
}

resource "aws_codedeploy_app" "backend_codedeploy_app" {
  name = var.docker_backend_codedeploy_name
  compute_platform = "Server"
}

# CodeDeploy 배포 그룹 생성
## 프론트 CodeDeploy 배포 그룹 생성
resource "aws_codedeploy_deployment_group" "docker_deployment_webapp_group" {
  app_name              = aws_codedeploy_app.docker_app.name
  deployment_group_name = var.docker_webapp_codedeploy_group_name
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  # Auto Scaling Group을 배포 대상으로 추가
  autoscaling_groups = [aws_autoscaling_group.webapp_asg.name]

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
  }

  # ALB 연동
  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.target_asg_app.name
    }
  } 
}

## 백엔드 CodeDeploy 배포 그룹 생성
resource "aws_codedeploy_deployment_group" "backend_codedeploy_group" {
  app_name              = aws_codedeploy_app.backend_codedeploy_app.name
  deployment_group_name = var.docker_backend_codedeploy_group_name
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  # Auto Scaling Group을 배포 대상으로 추가
  autoscaling_groups = [aws_autoscaling_group.webserver_asg.name]

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
  }

  # ALB 연동
  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.target_asg_server.name
    }
  } 
}

# IAM Role for CodeDeploy
resource "aws_iam_role" "codedeploy_role" {
  name = "CodeDeployRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for CodeDeploy
resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_policy" "codedeploy_asg_policy" {
  name        = "CodeDeployASGPolicy"
  description = "Allows CodeDeploy to interact with ASG and EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeInstanceHealth",
          "autoscaling:DetachInstances",
          "autoscaling:AttachInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:TerminateInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_asg_policy_attach" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = aws_iam_policy.codedeploy_asg_policy.arn
}