resource "google_billing_budget" "project_budget" {
  billing_account = var.billing_account_id
  display_name    = "Monthly budget for ${var.project_id}"

  amount {
    specified_amount {
      currency_code = "GBP"
      units         = var.monthly_budget_amount
    }
  }

  budget_filter {
    calendar_period         = "MONTH"
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 0.9
  }

  threshold_rules {
    threshold_percent = 1.0
  }

  all_updates_rule {
    pubsub_topic                  = google_pubsub_topic.billing_alerts.id
    disable_default_iam_recipients = false
  }
}
