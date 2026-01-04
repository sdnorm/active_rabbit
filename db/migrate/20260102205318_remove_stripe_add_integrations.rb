class RemoveStripeAddIntegrations < ActiveRecord::Migration[8.0]
  def change
    # Remove Stripe billing columns from accounts
    remove_column :accounts, :trial_ends_at, :datetime
    remove_column :accounts, :billing_interval, :string
    remove_column :accounts, :overage_subscription_item_id, :string
    remove_column :accounts, :ai_overage_subscription_item_id, :string

    # Add admin-configurable quota limits (null = use plan default)
    add_column :accounts, :ai_summaries_limit, :integer
    add_column :accounts, :pull_requests_limit, :integer

    # Add Campfire notification settings
    add_column :accounts, :campfire_webhook_url, :string

    # Add Fizzy bug tracking settings
    add_column :accounts, :fizzy_board_id, :string
    add_column :accounts, :fizzy_enabled, :boolean, default: false
  end
end
