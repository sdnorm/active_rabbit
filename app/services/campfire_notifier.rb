# Placeholder service for Once Campfire notifications
# TODO: Implement when Campfire bot API is finalized
#
# Once Campfire is a self-hosted chat application with bot integration support.
# See: https://github.com/basecamp/once-campfire
#
# This service will replace Slack notifications for error alerts.
# Supports both project-level and account-level webhook URLs.
class CampfireNotifier
  # Initialize with either:
  # - project: Uses project.campfire_webhook_url (falls back to account default)
  # - webhook_url: Direct webhook URL
  def initialize(webhook_url: nil, project: nil, room_id: nil)
    @webhook_url = webhook_url || project&.campfire_webhook_url
    @room_id = room_id
    @project = project
  end

  def notify(message:, title: nil, level: :info)
    return { error: "not_configured", message: "Campfire webhook URL not configured" } if @webhook_url.blank?

    # TODO: Implement Campfire bot API call
    # The API format will depend on how Campfire's bot integration works.
    # Expected format (placeholder):
    #
    # POST @webhook_url
    # {
    #   "room_id": @room_id,
    #   "content": message,
    #   "metadata": { "title": title, "level": level }
    # }

    project_info = @project ? " for project #{@project.name}" : ""
    Rails.logger.info("[Campfire] Would send notification#{project_info}: #{title || 'Alert'} - #{message}")
    { status: "placeholder", message: "Campfire integration pending implementation" }
  rescue => e
    Rails.logger.error("[Campfire] Notification failed: #{e.class}: #{e.message}")
    { error: "notification_failed", message: e.message }
  end

  # Check if Campfire is configured for an account or project
  def self.configured?(resource)
    resource.campfire_webhook_url.present? if resource.respond_to?(:campfire_webhook_url)
  end
end
