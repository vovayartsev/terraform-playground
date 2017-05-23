variable "region" { default="us-east-1" }
variable "dns_zone" { default="dockhero.tk" }

provider "aws" {
  region = "${var.region}"
}


provider "heroku" {
  email   = "vovayartsev@gmail.com"
}

terraform {
  backend "s3" {
    bucket = "dockhero-terraform-state"
    key    = "vovay-terraform-deployment"
    region = "us-east-1"
  }
}



# TODO: environments
# TODO: terraform has 2k issues - VS Cloud Formation???
# https://github.com/hashicorp/terraform/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aopen%20not%20destroyed%20





resource "aws_s3_bucket" "assets" {
  bucket = "aws-terraform-${terraform.env}"
  acl    = "private"
}

resource "aws_s3_bucket_object" "object" {
  bucket = "${aws_s3_bucket.assets.bucket}"
  key    = "hello.txt"
  content = "Hello ${terraform.env}"
  /*acl    = "public-read"*/
}











resource "heroku_app" "app" {
  name = "vovay-deployment-${terraform.env}"
  region = "us"
  config_vars {
    AWS_ACCESS_KEY_ID = "${aws_iam_access_key.user.id}"
    AWS_SECRET_ACCESS_KEY = "${aws_iam_access_key.user.secret}"
    BUCKET_NAME = "${aws_s3_bucket.assets.bucket}"
  }
}







resource "aws_iam_user" "user" {
  name = "heroku-terraform-${terraform.env}"
}

resource "aws_iam_access_key" "user" {
  user = "${aws_iam_user.user.name}"
}

data "aws_iam_policy_document" "s3" {
  statement {
    actions = [ "s3:GetObject" ]
    resources = [ "arn:aws:s3:::${aws_s3_bucket.assets.bucket}/*" ]
  }
}

resource "aws_iam_user_policy" "s3" {
  user = "${aws_iam_user.user.name}"
  policy = "${data.aws_iam_policy_document.s3.json}"
}

# TODO: а еще есть STS

# TODO: а если ключ спалили???  TAINT











data "template_file" "cloudconfig" {
  template = "${file("cloudconfig.tpl")}"
}

resource "aws_key_pair" "hh" {
  key_name = "aws-terraform-${terraform.env}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDU1yqcHOsZB1AmpMHt6Z8Qg4aeVVENpegv9VznxUFtC6Ygcm1R2pNxg+QkzeE/1TZWwTz3SZNlwRgG2+Mofl0zwEIb1ZrSSm4e5a8NI6Ss2OudAoW9uS75u7BkGRQbellWx25paqDjqGtvhT/9qgilFOfZCbY2t4VxjfXg+yGmDcltxNNHHsMi98JAZP2VhF6DXCXjiBEFLSupe0ZP29YFeSG3/YQkIrf1nbV9K17QANymoUQIDVoXGb4yKulmP8MrbTopJVF6YACE73De+gVEiqE8Eauk6WNuB2o8yLGt94Q75btn9vy3Bm4di694RW7NFWmZDnIRTOOg249lhp5v vovayartsev@Vladimirs-MacBook-Pro.local"
}

resource "aws_instance" "hh" {
  ami           = "ami-999f1a8f"
  instance_type = "t2.nano"
  user_data = "${data.template_file.cloudconfig.rendered}"
  key_name = "${aws_key_pair.hh.id}"
  security_groups = ["allow_all"]

  provisioner "local-exec" {
    command = "curl ${aws_instance.hh.public_ip}"
  }
}









# We will make EC2 instance assume the "instance" iam role below
# see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html

# NOTE: THE CONFIGURATION BELOW STILL DON'T WORK
# It's an extract from a different project
# I'll fix this example soon to have it as a reference

resource "aws_iam_role" "instance_role" {
  name               = "aws-terraform-${terraform.env}"
  assume_role_policy = "${data.aws_iam_policy_document.s3.json}"
}



resource "aws_iam_instance_profile" "instance_profile" {
  role = "${aws_iam_role.instance_role.name}"
}

resource "aws_iam_role_policy" "instance_policy" {
  role = "${aws_iam_role.instance_role.id}"
  policy = "${data.aws_iam_policy_document.s3.json}"
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}






/*BONUS*/

# Attach apps to Cloudflare domain automatically

provider "cloudflare" {
  email = "dockhero@castle.co"
}

resource "heroku_domain" "default" {
  app      = "${heroku_app.app.name}"
  hostname = "heroku-terraform-${terraform.env}.${var.dns_zone}"
}

resource "cloudflare_record" "my_dns_record" {
  domain = "${var.dns_zone}"
  name   = "@"
  value  = "${heroku_app.app.name}.herokuapp.com"
  type   = "CNAME"
  proxied = true
}

/*resource "cloudflare_record" "hh" {
  domain = "dockhero.tk"
  name   = "aws-terraform-${terraform.env}"
  value  = "${aws_instance.hh.public_ip}"
  type   = "A"
  proxied = true
}*/
