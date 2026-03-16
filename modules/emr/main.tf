variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "emr_release" {
  type    = string
  default = "emr-7.0.0"
}

variable "core_min" {
  type    = number
  default = 2
}

variable "core_max" {
  type    = number
  default = 10
}

resource "aws_security_group" "emr_master" {
  name        = "ppd-${var.env}-emr-master-sg"
  description = "EMR master SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ppd-${var.env}-emr-master-sg"
    Environment = var.env
  }
}

resource "aws_security_group" "emr_core" {
  name        = "ppd-${var.env}-emr-core-sg"
  description = "EMR core SG"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ppd-${var.env}-emr-core-sg"
    Environment = var.env
  }
}

resource "aws_iam_role" "emr_service" {
  name = "ppd-${var.env}-emr-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "elasticmapreduce.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "emr_service" {
  role       = aws_iam_role.emr_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role" "emr_ec2" {
  name = "ppd-${var.env}-emr-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "emr_ec2" {
  role       = aws_iam_role.emr_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "emr_ec2" {
  name = "ppd-${var.env}-emr-ec2-instance-profile"
  role = aws_iam_role.emr_ec2.name
}

resource "aws_s3_bucket" "emr_logs" {
  bucket = "ppd-${var.env}-emr-logs"

  tags = {
    Name        = "ppd-${var.env}-emr-logs"
    Environment = var.env
  }
}

resource "aws_emr_cluster" "this" {
  name          = "ppd-${var.env}-batch-emr"
  release_label = var.emr_release
  applications  = ["Spark"]

  service_role = aws_iam_role.emr_service.arn

  ec2_attributes {
    instance_profile                  = aws_iam_instance_profile.emr_ec2.arn
    subnet_id                         = element(var.private_subnet_ids, 0)
    emr_managed_master_security_group = aws_security_group.emr_master.id
    emr_managed_slave_security_group  = aws_security_group.emr_core.id
  }

  master_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 1
  }

  core_instance_group {
    instance_type  = "m5.4xlarge"
    instance_count = var.core_min

    autoscaling_policy = jsonencode({
      Constraints = {
        MinCapacity = var.core_min
        MaxCapacity = var.core_max
      }
      Rules = [{
        Name        = "scale-out-yarn-memory"
        Description = "Scale out if YARNMemoryAvailablePercentage < 15"
        Action = {
          SimpleScalingPolicyConfiguration = {
            AdjustmentType    = "CHANGE_IN_CAPACITY"
            CoolDown          = 300
            ScalingAdjustment = 2
          }
        }
        Trigger = {
          CloudWatchAlarmDefinition = {
            ComparisonOperator = "LESS_THAN"
            EvaluationPeriods  = 1
            MetricName         = "YARNMemoryAvailablePercentage"
            Namespace          = "AWS/ElasticMapReduce"
            Period             = 300
            Statistic          = "AVERAGE"
            Threshold          = 15
            Unit               = "PERCENT"
          }
        }
      }]
    })
  }

  auto_termination_policy {
    idle_timeout = 3600
  }

  log_uri = "s3://${aws_s3_bucket.emr_logs.bucket}/emr-logs/"

  configurations_json = file("${path.module}/configs/emr-config.json")

  # Default EMR security configuration in us-east-1 (no explicit security_configuration)

  tags = {
    Environment = var.env
    ManagedBy   = "terraform"
  }
}
