resource "google_billing_budget" "project_budget" {
  provider        = google-beta
  billing_account = var.billing_account_id
  display_name    = "monthly-budget-${var.project_id}"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "GBP"
      units         = var.monthly_budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 0.8
  }

  threshold_rules {
    threshold_percent = 1.0
  }

  all_updates_rule {
    pubsub_topic                  = google_pubsub_topic.billing_alerts.id
    disable_default_iam_recipients = false
  }
}
