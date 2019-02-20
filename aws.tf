provider "aws" {
    version = "~> 1.59"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region     = "${var.aws_region}"
}


# ## S3
resource "aws_s3_bucket" "prod" {
  bucket = "prod-${var.aws_public_bucket_name}"
  acl    = "public-read"
}
resource "aws_s3_bucket" "staging" {
  count = "${var.create_staging}"
  bucket = "staging-${var.aws_public_bucket_name}"
  acl    = "public-read"
}


## RDS
data "aws_vpc" "default" {
  default = true
}
data "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
  name   = "default"
}

# DB
resource "aws_db_instance" "prod" {
  depends_on             = ["data.aws_security_group.default"]
  identifier             = "prod-${var.project_name}"
  allocated_storage      = "20"
  engine                 = "postgres"
  engine_version         = "10.6"
  instance_class         = "db.t2.micro"
  name                   = "${var.aws_rds_db_name}"
  username               = "${var.aws_rds_username}"
  password               = "${var.aws_rds_password}"
  vpc_security_group_ids = ["${data.aws_security_group.default.id}"]
  # db_subnet_group_name   = ["${data.aws_subnet_ids.all.ids}"]
  publicly_accessible = "true"
}
resource "aws_db_instance" "staging" {
  count = "${var.create_staging}"
  depends_on             = ["data.aws_security_group.default"]
  identifier             = "staging-${var.project_name}"
  allocated_storage      = "20"
  engine                 = "postgres"
  engine_version         = "10.6"
  instance_class         = "db.t2.micro"
  name                   = "${var.aws_rds_db_name}"
  username               = "${var.aws_rds_username}"
  password               = "${var.aws_rds_password}"
  vpc_security_group_ids = ["${data.aws_security_group.default.id}"]
  # db_subnet_group_name   = ["${data.aws_subnet_ids.all.ids}"]
  publicly_accessible = "true"
}


## Create user
resource "aws_iam_user" "prod" {
    name = "heroku-prod-${var.project_name}"
}
resource "aws_iam_access_key" "prod" {
    user = "${aws_iam_user.prod.name}"
}
resource "aws_iam_user_policy" "s3-prod" {
    name = "prod"
    user = "${aws_iam_user.prod.name}"
    policy = "${data.aws_iam_policy_document.s3.json}"
}

resource "aws_iam_user" "staging" {
  count = "${var.create_staging}"
    name = "heroku-staging-${var.project_name}"
}
resource "aws_iam_access_key" "staging" {
    count = "${var.create_staging}"
    user = "${aws_iam_user.staging.name}"
}
resource "aws_iam_user_policy" "s3-staging" {
    count = "${var.create_staging}"
    name = "staging"
    user = "${aws_iam_user.staging.name}"
    policy = "${data.aws_iam_policy_document.s3.json}"
}

data "aws_iam_policy_document" "s3" {
  statement {
    actions = [ "s3:List*",
                "s3:Get*",
                "s3:Put*",
                "s3:Delete*"
              ]
    effect = "Allow"
    resources = ["*"]
  }
}