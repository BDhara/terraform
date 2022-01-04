terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-east-1"
}

resource "aws_s3_bucket" "tfmbucket" {
  bucket = "www.terraformdemo.com"
  acl    = "public-read"
  
  website {
    index_document = "index.html"
    error_document = "error404.html"
  }

  tags = {
    Name        = "TFM-Bucket"    
  }
}

resource "aws_s3_bucket_object" "tfmfiles" {
    for_each    = fileset("./dist/", "*")
    bucket      = "${aws_s3_bucket.tfmbucket.id}"
    key         = each.value
    source      = "./dist/${each.value}"
    content_type = "text/html"
    acl         = "public-read"
    etag        = filemd5("./dist/${each.value}")
}

resource "aws_instance" "tfm_instance" {
  ami           = "ami-026e94842bffe7c42"
  instance_type = "t2.micro"
  subnet_id     = "subnet-4555b42c"
  iam_instance_profile = "${aws_iam_instance_profile.tfm_instance_profile.name}"

  tags = {
    Name = "tfm-instance-demo"
  }
}


resource "aws_iam_role" "tfm_role" {
    name = "tfm_role"
    assume_role_policy = jsonencode({  
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
    })
    

    tags = {
      tag-key = "tfmrole"
  }
}

resource "aws_iam_instance_profile" "tfm_instance_profile" {
    name = "tfm_profile"
    role = "${aws_iam_role.tfm_role.name}"
}

resource "aws_iam_role_policy" "tfm_policy" {
  name = "tfm_policy"
  role = "${aws_iam_role.tfm_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}