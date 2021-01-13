resource "google_compute_security_policy" "security-policy-1" {
  name        = local.google_compute_security_policy_frontend_name
  project     = google_project.app1.project_id
  description = "web application security policy"

  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = local.google_compute_security_policy_sqli_rule_expression_list
      }
    }
    description = "Cloud Armor tuned WAF rules for SQL injection"
  }

  rule {
    action   = "deny(403)"
    priority = "2000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "Deny access to XSS attempts"
  }

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule"
  }
}
