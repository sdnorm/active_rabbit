class ReportUsageJob < ApplicationJob
  queue_as :default

  def perform(account_id:, day: Date.current)
    account = Account.find_by(id: account_id)
    return unless account

    # Aggregate daily resource usage
    DailyResourceUsage.aggregate_for_account_and_day(account_id, day)
  end
end
