# Attach apps to Cloudflare domain automatically

provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
  version = "~> 1.11"
}

resource "cloudflare_record" "prod" {
  domain = "${var.prod_dns_zone}"
  name   = "@"
  value  = "${heroku_app.prod.name}.herokuapp.com"
  type   = "CNAME"
  proxied = true
}
resource "cloudflare_record" "staging" {
    count = "${var.create_staging}"
    domain = "${var.staging_dns_zone}"
    name   = "@"
    value  = "${heroku_app.staging.name}.herokuapp.com"
    type   = "CNAME"
    proxied = true
}