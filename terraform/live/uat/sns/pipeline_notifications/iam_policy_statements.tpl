[
  {
    Effect = "Allow",
    Principal = {
      Service ="codestar-notifications.amazonaws.com"
    },
    Action = ["sns:Publish"],
    Resource = ["arn:aws:sns:${region}:${account_id}:${name}"]
  }
]
