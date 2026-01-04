# Placeholder service for Fizzy bug tracking integration
# TODO: Implement when Fizzy API/CLI is finalized
#
# Fizzy is a Kanban tracking tool for issues and ideas by 37signals.
# See: https://github.com/basecamp/fizzy
# CLI reference: https://github.com/robzolkos/fizzy-skill
#
# This service will create cards on a Fizzy board when errors are detected.
# Supports both project-level and account-level board IDs.
class FizzyClient
  DEFAULT_COLUMN = "Triage".freeze

  # Initialize with either:
  # - project: Uses project.fizzy_board_id (falls back to account default)
  # - board_id: Direct board ID
  def initialize(board_id: nil, project: nil, api_token: nil)
    @board_id = board_id || project&.fizzy_board_id
    @api_token = api_token || ENV["FIZZY_API_TOKEN"]
    @project = project
  end

  def create_card(title:, description:, column: DEFAULT_COLUMN, tags: [])
    return { error: "not_configured", message: "Fizzy board ID not configured" } if @board_id.blank?

    # TODO: Implement Fizzy API/CLI call
    # Options:
    # 1. Use Fizzy CLI via system command
    # 2. Use Fizzy API directly when available
    #
    # Expected CLI format (placeholder):
    #   fizzy cards create --board @board_id --title "title" --description "description" --column "column"
    #
    # Expected API format (placeholder):
    #   POST https://fizzy.do/api/v1/boards/@board_id/cards
    #   { "title": title, "description": description, "column": column, "tags": tags }

    project_info = @project ? " for project #{@project.name}" : ""
    Rails.logger.info("[Fizzy] Would create card on board #{@board_id}#{project_info}: #{title}")
    { status: "placeholder", message: "Fizzy integration pending implementation" }
  rescue => e
    Rails.logger.error("[Fizzy] Card creation failed: #{e.class}: #{e.message}")
    { error: "card_creation_failed", message: e.message }
  end

  def list_columns
    return { error: "not_configured", message: "Fizzy board ID not configured" } if @board_id.blank?

    # TODO: Implement Fizzy API call to list columns
    Rails.logger.info("[Fizzy] Would list columns for board #{@board_id}")
    { status: "placeholder", columns: ["Triage", "In Progress", "Done"] }
  end

  # Check if Fizzy is configured for an account or project
  def self.configured?(resource)
    resource.fizzy_board_id.present? && resource.fizzy_enabled? if resource.respond_to?(:fizzy_board_id)
  end
end
