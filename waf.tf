# Web Application Firewall (wafv2)
# require "umotif-public/waf-webaclv2/aws"

module "waf" {
  source  = "umotif-public/waf-webaclv2/aws"
  version = "4.6.1"

  name_prefix = "waf-gtp-app-uat"
  alb_arn     = aws_lb.gtp_uat_app.arn

  scope = "REGIONAL"

  create_alb_association = true

  allow_default_action = true # set to allow if not specified

  visibility_config = {
    metric_name = "waf-gtp-app-uat-metrics"
  }

  rules = [
    {
      name     = "AWSManagedRulesCommonRuleSet-rule-1"
      priority = "1"

      override_action = "none"

      visibility_config = {
        metric_name = "AWSManagedRulesCommonRuleSet-metric"
      }

      managed_rule_group_statement = {
        # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html#aws-managed-rule-groups-baseline-crs
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        rule_action_overrides = [
          {
            action_to_use = {
              count = {}
            }

            name = "SizeRestrictions_QUERYSTRING"
          },
          {
            action_to_use = {
              count = {}
            }

            name = "SizeRestrictions_BODY"
          },
          {
            action_to_use = {
              count = {}
            }

            name = "GenericRFI_QUERYARGUMENTS"
          }
        ]
      }
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet-rule-2"
      priority = "2"

      override_action = "count"

      visibility_config = {
        metric_name = "AWSManagedRulesKnownBadInputsRuleSet-metric"
      }

      managed_rule_group_statement = {
        # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html#aws-managed-rule-groups-baseline-known-bad-inputs
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesPHPRuleSet-rule-3"
      priority = "3"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "AWSManagedRulesPHPRuleSet-metric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-use-case.html#aws-managed-rule-groups-use-case-php-app
        name        = "AWSManagedRulesPHPRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesAmazonIpReputationList-rule-4"
      priority = "4"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "AWSManagedRulesAmazonIpReputationList-metric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-ip-rep.html#aws-managed-rule-groups-ip-rep-amazon
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesSQLiRuleSet-rule-5"
      priority = "5"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "AWSManagedRulesSQLiRuleSet-metric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-use-case.html#aws-managed-rule-groups-use-case-sql-db
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "GeoMatc-rule-6"
      priority = "6"

      action = "allow"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "GeoMatchRule-metric"
        sampled_requests_enabled   = false
      }

      geo_match_statement = {
        country_codes = ["MY"]
      }
    }
  ]

  tags = {
    "Name" = "waf-gtp-app-uat"
    "Env"  = "UAT"
  }
}
