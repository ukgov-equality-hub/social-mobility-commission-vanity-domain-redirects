
resource "aws_cloudfront_cache_policy" "cloudfront_cache_policy" {
  name = "${var.service_name_hyphens}--Cache-Policy"
  min_ttl = 0
  default_ttl = 60
  max_ttl = 600

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_distribution" "distribution_redirects" {
  // CloudFront distributions have to be created in the us-east-1 region (for some reason!)
  provider = aws.us-east-1

  for_each = local.domain_names_map

  comment = "${var.service_name_hyphens}--redirects-${each.value.domain}"

  origin {
    domain_name = "example.com"
    origin_id = "${var.service_name_hyphens}--redirects-origin-${each.key}"

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  price_class = "PriceClass_100"

  aliases = concat(
    [each.value.domain],  // The root domain name
    [for sub_domain in local.sub_domains_flattened : "${sub_domain.sub_domain}.${sub_domain.domain_name}" if sub_domain.domain_name == each.value.domain]  // The sub-domains for this domain
  )

  viewer_certificate {
    acm_certificate_arn = [
      for waiter
      in aws_acm_certificate_validation.certificate_validation_waiter :
        waiter.certificate_arn
      if anytrue([for fqdns in waiter.validation_record_fqdns : endswith(fqdns, each.value.domain)])
    ][0]
    cloudfront_default_certificate = false
    minimum_protocol_version = "TLSv1"
    ssl_support_method = "sni-only"
  }

  default_root_object = "index.html"

  enabled = true
  is_ipv6_enabled = true

  default_cache_behavior {
    cache_policy_id = aws_cloudfront_cache_policy.cloudfront_cache_policy.id
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "${var.service_name_hyphens}--redirects-origin-${each.key}"
    viewer_protocol_policy = "redirect-to-https"
    compress = true

    function_association {
      event_type = "viewer-request"
      function_arn = aws_cloudfront_function.redirect_function.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations = []
    }
  }
}

resource "aws_cloudfront_function" "redirect_function" {
  name    = "${var.service_name_hyphens}--redirect-function"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = <<EOT
function handler(event) {
    function create_redirect(redirect_to_url) {
        return {
            statusCode: 302,
            statusDescription: "Found",
            headers: {
                "location": {
                    value: redirect_to_url
                },
            },
        };
    }

    function urls_match(request_url, redirect_from_url, case_sensitive) {
        if (redirects[i].case_sensitive) {
            return (request_url === redirect_from_url);
        }
        else {
            return (request_url.toLowerCase() === redirect_from_url.toLowerCase());
        }
    }

    var redirects = ${local.redirects_json_text}

    for (var i = 0; i < redirects.length; i++) {
        if (urls_match(event.request.uri, redirects[i].from, redirects[i].case_sensitive)) {
            return create_redirect(redirects[i].to);
        }
    }

    // If we didn't find a specific redirect, then redirect to the SMC website homepage
    return create_redirect("${local.redirect_everything_else_to}");
}
EOT
}