[
    {
      Effect = "Allow",
      Principal = {
        Service = "logs.${region}.amazonaws.com"
      },
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      Resource = ["*"],
      Condition = {
        ArnEquals = {
          "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${region}:${account_id}:*"
        }
      }
    }
]
