resource "aws_instance" "amazon_linux" {
  provider               = aws.dev
  ami                    = "ami-0323c3dd2da7fb37d"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.amazon_linux.id]
  key_name               = aws_key_pair.annas.key_name

  user_data = file("cloud-config/web_server_init.sh")


  tags = {
    Name = "web-server"
  }
  iam_instance_profile = aws_iam_instance_profile.s3_read.id
}

#add ssh key
resource "aws_key_pair" "annas" {
  provider   = aws.dev
  key_name   = "annas"
  public_key = var.ssh_key
}

#iam role to mark ec2 instance as trusted
resource "aws_iam_role" "s3_read" {
  provider           = aws.dev
  name               = "s3_read_only"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF    
}

#connect iam role to an instance profile
resource "aws_iam_instance_profile" "s3_read" {
  provider = aws.dev
  name     = "s3_read_only"
  role     = aws_iam_role.s3_read.name
}

#iam policy to allow read-only access to the s3 bucket
resource "aws_iam_role_policy" "s3_read" {
  provider = aws.dev
  name     = "s3_read_only_policy"
  role     = aws_iam_role.s3_read.id
  policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "${aws_s3_bucket.html.arn}/${aws_s3_bucket_object.html.key}"
        }
    ]
}
EOF

}