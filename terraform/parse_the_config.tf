
locals {
  //  The contents of the file "configure_the_redirects.json" SHOULD be valid JSON
  //  If it's not valid JSON, then the CloudFront function will fail
  //  So we want to validate the JSON *BEFORE* we update the CloudFront function
  //  A simple way of validating the JSON is to decode and encode it
  config_file_text = file("${path.module}/configure_the_redirects.json")
  config = jsondecode(local.config_file_text)
  redirects_json_text = jsonencode(local.config.redirects)

  domain_names_map = {
    for i, domain_name in local.config.domain_names: domain_name.domain => {
      domain = domain_name.domain
      sub_domains = domain_name.sub_domains
    }
  }

  sub_domains_flattened = flatten([
    for domain_name in local.config.domain_names : [
      for sub_domain in domain_name.sub_domains : {
        domain_name = domain_name.domain
        sub_domain = sub_domain
      }
    ]
  ])

  redirect_everything_else_to = local.config.redirect_everything_else_to
}
