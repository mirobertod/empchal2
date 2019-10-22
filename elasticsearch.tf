resource "aws_elasticsearch_domain" "elasticlog" {
  domain_name           = "elasticlog"
  elasticsearch_version = "7.1"

  cluster_config {
    instance_type = "t2.small.elasticsearch"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = {
    Domain = "elasticlog"
  }

  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.lambda-logstream-role.arn}"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain}/*"
    }
  ]
}
POLICY
}

variable "domain" {
  default = "elasticlog"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

output "elastic_endpoint" {
  value       =  "${aws_elasticsearch_domain.elasticlog.endpoint}"
  description = "The public endpoint for Elasticsearch."
}