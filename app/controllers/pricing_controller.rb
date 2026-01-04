class PricingController < ApplicationController
  layout "admin"
  before_action :authenticate_user!

  def usage
    @account = current_user.account

    if @account
      set_usage_data
    end
  end

  private

  def set_usage_data
    return unless @account

    # Rolling 30-day usage window (for requests totals)
    window_start = 30.days.ago

    @events_last_30_days =
      Event.where("occurred_at > ?", window_start).count

    @ai_summaries_last_30_days =
      Issue.where("ai_summary_generated_at > ?", window_start).count

    @pull_requests_last_30_days =
      AiRequest.where(request_type: "pull_request")
               .where("occurred_at > ?", window_start)
               .count

    perf_requests_last_30_days =
      PerformanceEvent.where("occurred_at > ?", window_start).count

    @requests_total_last_30_days =
      @events_last_30_days + @ai_summaries_last_30_days + @pull_requests_last_30_days + perf_requests_last_30_days

    # Event/Error tracking usage (current billing period)
    @event_quota = @account.event_quota_value
    @events_used = @account.events_used_in_billing_period
    @events_remaining = [@event_quota - @events_used, 0].max

    # AI Summaries usage
    @ai_summaries_quota = @account.ai_summaries_quota
    @ai_summaries_used = @account.ai_summaries_used_in_period
    @ai_summaries_remaining = [@ai_summaries_quota - @ai_summaries_used, 0].max

    # Pull Requests usage
    @pull_requests_quota = @account.pull_requests_quota
    @pull_requests_used = @account.pull_requests_used_in_period
    @pull_requests_remaining = [@pull_requests_quota - @pull_requests_used, 0].max

    # Uptime Monitors usage
    @uptime_monitors_quota = @account.uptime_monitors_quota
    @uptime_monitors_used = @account.uptime_monitors_used
    @uptime_monitors_remaining = [@uptime_monitors_quota - @uptime_monitors_used, 0].max

    # Status Pages usage
    @status_pages_quota = @account.status_pages_quota
    @status_pages_used = @account.status_pages_used
    @status_pages_remaining = [@status_pages_quota - @status_pages_used, 0].max

    # Projects usage
    @projects_quota = @account.projects_quota
    @projects_used = @account.projects_used
    @projects_remaining = [@projects_quota - @projects_used, 0].max
  end
end
