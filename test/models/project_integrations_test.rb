require "test_helper"

class ProjectIntegrationsTest < ActiveSupport::TestCase
  setup do
    @account = create_test_account(
      campfire_webhook_url: "https://account.campfire.com/webhook",
      fizzy_board_id: "account-board-123",
      fizzy_enabled: true
    )
    @user = create_test_user(account: @account)
  end

  # ============================================
  # Campfire Integration Tests
  # ============================================

  test "campfire_webhook_url returns project-specific URL when set" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: { "campfire_webhook_url" => "https://project.campfire.com/webhook" }
      )

      assert_equal "https://project.campfire.com/webhook", project.campfire_webhook_url
    end
  end

  test "campfire_webhook_url falls back to account default when project URL is blank" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: {}
      )

      assert_equal "https://account.campfire.com/webhook", project.campfire_webhook_url
    end
  end

  test "campfire_webhook_url returns nil when neither project nor account has URL" do
    account_without_campfire = create_test_account(campfire_webhook_url: nil)
    user = create_test_user(account: account_without_campfire)

    with_tenant(account_without_campfire) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      assert_nil project.campfire_webhook_url
    end
  end

  test "campfire_configured? returns true when webhook URL is present" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: { "campfire_webhook_url" => "https://project.campfire.com/webhook" }
      )

      assert project.campfire_configured?
    end
  end

  test "campfire_configured? returns true when account has default webhook URL" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: {}
      )

      assert project.campfire_configured?
    end
  end

  test "campfire_configured? returns false when no webhook URL is set" do
    account_without_campfire = create_test_account(campfire_webhook_url: nil)
    user = create_test_user(account: account_without_campfire)

    with_tenant(account_without_campfire) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      refute project.campfire_configured?
    end
  end

  test "notify_via_campfire? returns true when all conditions are met" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: {
          "campfire_webhook_url" => "https://project.campfire.com/webhook",
          "notifications" => {
            "enabled" => true,
            "channels" => { "campfire" => true }
          }
        }
      )

      assert project.notify_via_campfire?
    end
  end

  test "notify_via_campfire? returns false when notifications are disabled" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: {
          "campfire_webhook_url" => "https://project.campfire.com/webhook",
          "notifications" => {
            "enabled" => false,
            "channels" => { "campfire" => true }
          }
        }
      )

      refute project.notify_via_campfire?
    end
  end

  test "notify_via_campfire? returns false when campfire channel is disabled" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: {
          "campfire_webhook_url" => "https://project.campfire.com/webhook",
          "notifications" => {
            "enabled" => true,
            "channels" => { "campfire" => false }
          }
        }
      )

      refute project.notify_via_campfire?
    end
  end

  test "notify_via_campfire? returns false when campfire is not configured" do
    account_without_campfire = create_test_account(campfire_webhook_url: nil)
    user = create_test_user(account: account_without_campfire)

    with_tenant(account_without_campfire) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {
          "notifications" => {
            "enabled" => true,
            "channels" => { "campfire" => true }
          }
        }
      )

      refute project.notify_via_campfire?
    end
  end

  # ============================================
  # Fizzy Integration Tests
  # ============================================

  test "fizzy_board_id returns project-specific board ID when set" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: { "fizzy_board_id" => "project-board-456" }
      )

      assert_equal "project-board-456", project.fizzy_board_id
    end
  end

  test "fizzy_board_id falls back to account default when project board ID is blank" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: {}
      )

      assert_equal "account-board-123", project.fizzy_board_id
    end
  end

  test "fizzy_board_id returns nil when neither project nor account has board ID" do
    account_without_fizzy = create_test_account(fizzy_board_id: nil)
    user = create_test_user(account: account_without_fizzy)

    with_tenant(account_without_fizzy) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      assert_nil project.fizzy_board_id
    end
  end

  test "fizzy_enabled? returns project-specific value when set to true" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: { "fizzy_enabled" => true }
      )

      assert project.fizzy_enabled?
    end
  end

  test "fizzy_enabled? returns project-specific value when set to false" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: { "fizzy_enabled" => false }
      )

      refute project.fizzy_enabled?
    end
  end

  test "fizzy_enabled? falls back to account default when not set on project" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: {}
      )

      # Account has fizzy_enabled: true
      assert project.fizzy_enabled?
    end
  end

  test "fizzy_enabled? returns false when account default is false and project has no override" do
    account_fizzy_disabled = create_test_account(fizzy_enabled: false)
    user = create_test_user(account: account_fizzy_disabled)

    with_tenant(account_fizzy_disabled) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      refute project.fizzy_enabled?
    end
  end

  test "fizzy_configured? returns true when board ID is present and fizzy is enabled" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: {
          "fizzy_board_id" => "project-board-456",
          "fizzy_enabled" => true
        }
      )

      assert project.fizzy_configured?
    end
  end

  test "fizzy_configured? returns false when board ID is missing" do
    account_without_fizzy = create_test_account(fizzy_board_id: nil, fizzy_enabled: true)
    user = create_test_user(account: account_without_fizzy)

    with_tenant(account_without_fizzy) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: { "fizzy_enabled" => true }
      )

      refute project.fizzy_configured?
    end
  end

  test "fizzy_configured? returns false when fizzy is disabled" do
    with_tenant(@account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: {
          "fizzy_board_id" => "project-board-456",
          "fizzy_enabled" => false
        }
      )

      refute project.fizzy_configured?
    end
  end
end
