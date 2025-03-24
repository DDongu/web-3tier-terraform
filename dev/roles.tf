# ✅ EC2용 IAM Role 생성 (CodeDeploy Agent 실행을 위해 필요)
resource "aws_iam_role" "codedeploy_ec2_role" {
  name = "CodeDeployEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ✅ EC2가 CodeDeploy와 S3에 접근할 수 있도록 권한 추가
resource "aws_iam_policy" "codedeploy_ec2_policy" {
  name        = "CodeDeployEC2Policy"
  description = "Allows EC2 instances to interact with CodeDeploy, S3, and Auto Scaling"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ✅ S3 접근 (CodeDeploy에서 S3를 사용 가능하도록 설정)
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::docker-image-storage-bucket",
          "arn:aws:s3:::docker-image-storage-bucket/*"
        ]
      },

      # ✅ CodeDeploy 관련 권한 추가
      {
        Effect   = "Allow"
        Action   = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:ListDeployments",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },

      # ✅ EC2 및 Auto Scaling 접근 (배포 중 인스턴스 정보 확인)
      {
        Effect   = "Allow"
        Action   = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeTags",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances"
        ]
        Resource = "*"
      },

      # ✅ 로그 저장 (CloudWatch Logs 연동을 위한 설정)
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },

      # ✅ AWS Systems Manager (SSM) 접근 (CodeDeploy에서 인스턴스 명령 실행 가능하도록 설정)
      {
        Effect   = "Allow"
        Action   = [
          "ssm:DescribeInstanceInformation",
          "ssm:GetCommandInvocation",
          "ssm:SendCommand"
        ]
        Resource = "*"
      },

      # ✅ IAM Role을 EC2가 사용할 수 있도록 PassRole 권한 추가
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
      },

      # SSM Parameter Store에 접근할 수 있도록 IAM Role을 설정
      {
        "Effect": "Allow",
        "Action": [
            "ssm:GetParameter"
        ],
        "Resource": "arn:aws:ssm:*:*:parameter/my-app/documentdb-uri"
      }
    ]
  })
}

# ✅ IAM Policy Attach (EC2 Role에 정책 연결)
resource "aws_iam_role_policy_attachment" "codedeploy_ec2_attach" {
  role       = aws_iam_role.codedeploy_ec2_role.name
  policy_arn = aws_iam_policy.codedeploy_ec2_policy.arn
}

# ✅ IAM Instance Profile 생성 (EC2에 연결할 Profile)
resource "aws_iam_instance_profile" "codedeploy_instance_profile" {
  name = "CodeDeployInstanceProfile"
  role = aws_iam_role.codedeploy_ec2_role.name
}
