# Step 1: Create the IAM Role Execution Block
resource "aws_iam_role" "ec2_role" {
  name = "ec2-application-execution-role"

  # Trust policy allowing EC2 instances to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Step 2: Define and Attach the S3 Policy (Least-Privilege)
resource "aws_iam_policy" "s3_read_write_policy" {
  name        = "s3-app-data-policy"
  description = "Strict permissions for Donal's app to access Vanrith's specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.main.arn}",
          "${aws_s3_bucket.main.arn}/*"
        ]
      }
    ]
  })
}

# Attach S3 Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "s3_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}

# Step 3: Attach the CloudWatch Agent Policy (Omrin's requirement)
resource "aws_iam_role_policy_attachment" "cloudwatch_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Step 4: Attach the SSM Managed Instance Policy (for AWS Systems Manager access)
resource "aws_iam_role_policy_attachment" "ssm_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Step 5: Create the IAM Instance Profile
# NOTE FOR DARA: Reference 'aws_iam_instance_profile.ec2_profile.name' in compute.tf
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
