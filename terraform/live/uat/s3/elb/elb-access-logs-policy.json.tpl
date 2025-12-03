{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowELBLogDelivery",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "logdelivery.elasticloadbalancing.amazonaws.com",
          "delivery.logs.amazonaws.com"
        ]
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${bucket_name}/elb-logs/AWSLogs/${account_id}/*"
    },
    {
      "Sid": "AllowGetBucketAclForELBLogDelivery",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "logdelivery.elasticloadbalancing.amazonaws.com",
          "delivery.logs.amazonaws.com"
        ]
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${bucket_name}"
    }
  ]
}
