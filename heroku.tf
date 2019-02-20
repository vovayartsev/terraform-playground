provider "heroku" {
  email   = "${var.heroku_email}"
  api_key = "${var.heroku_api_key}"
  version = "~> 1.7"
}

resource "heroku_app" "prod" {
  depends_on = ["aws_db_instance.prod"]

  name = "prod-${var.project_name}"
  region = "us"

  config_vars {
    AWS_ACCESS_KEY_ID = "${aws_iam_access_key.prod.id}"
    AWS_SECRET_ACCESS_KEY = "${aws_iam_access_key.prod.secret}"
    BUCKET_NAME = "${aws_s3_bucket.prod.bucket_domain_name}"
    DATABASE_URL= "postgres://${var.aws_rds_username}:${var.aws_rds_password}@${aws_db_instance.prod.endpoint}/${var.aws_rds_db_name}"
  }
}

resource "heroku_app" "staging" {
    depends_on = ["aws_db_instance.staging"]

    count = "${var.create_staging}"
    name = "staging-${var.project_name}"
    region = "us"

    config_vars {
        AWS_ACCESS_KEY_ID = "${aws_iam_access_key.staging.id}"
        AWS_SECRET_ACCESS_KEY = "${aws_iam_access_key.staging.secret}"
        BUCKET_NAME = "${aws_s3_bucket.staging.bucket_domain_name}"
        DATABASE_URL= "postgres://${var.aws_rds_username}:${var.aws_rds_password}@${aws_db_instance.staging.endpoint}/${var.aws_rds_db_name}"
    }
}


# Add domain
resource "heroku_domain" "prod" {
  app      = "${heroku_app.prod.name}"
  hostname = "heroku.${var.prod_dns_zone}"
}

resource "heroku_domain" "staging" {
  count = "${var.create_staging}"
  app      = "${heroku_app.staging.name}"
  hostname = "heroku.${var.staging_dns_zone}"
}


# Create a Heroku pipeline
resource "heroku_pipeline" "pipeline" {
    count = "${var.create_staging}"
    name = "pipeline"
}

# Couple apps to different pipeline stages
resource "heroku_pipeline_coupling" "staging" {
    count = "${var.create_staging}"
    app      = "${heroku_app.staging.name}"
    pipeline = "${heroku_pipeline.pipeline.id}"
    stage    = "staging"
}

resource "heroku_pipeline_coupling" "prod" {
    count = "${var.create_staging}"
    app      = "${heroku_app.prod.name}"
    pipeline = "${heroku_pipeline.pipeline.id}"
    stage    = "production"
}