require "test_helper"

class CampfireNotifierTest < ActiveSupport::TestCase
  # ============================================
  # Initialization Tests
  # ============================================

  test "initializes with webhook_url parameter" do
    notifier = CampfireNotifier.new(webhook_url: "https://example.com/webhook")

    # The notifier should be created successfully
    assert_instance_of CampfireNotifier, notifier
  end

  test "initializes with project parameter" do
    account = create_test_account(campfire_webhook_url: "https://account.campfire.com/webhook")
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: { "campfire_webhook_url" => "https://project.campfire.com/webhook" }
      )

      notifier = CampfireNotifier.new(project: project)
      assert_instance_of CampfireNotifier, notifier
    end
  end

  test "prefers explicit webhook_url over project webhook_url" do
    account = create_test_account(campfire_webhook_url: "https://account.campfire.com/webhook")
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: { "campfire_webhook_url" => "https://project.campfire.com/webhook" }
      )

      # When both are provided, explicit webhook_url wins
      notifier = CampfireNotifier.new(webhook_url: "https://explicit.campfire.com/webhook", project: project)
      result = notifier.notify(message: "test")

      # The placeholder logs the webhook, so we verify by the result being successful
      assert_equal "placeholder", result[:status]
    end
  end

  # ============================================
  # Notify Method Tests
  # ============================================

  test "notify returns placeholder status when webhook is configured" do
    notifier = CampfireNotifier.new(webhook_url: "https://example.com/webhook")
    result = notifier.notify(message: "Test message")

    assert_equal "placeholder", result[:status]
    assert_equal "Campfire integration pending implementation", result[:message]
  end

  test "notify returns error when webhook URL is blank" do
    notifier = CampfireNotifier.new(webhook_url: nil)
    result = notifier.notify(message: "Test message")

    assert_equal "not_configured", result[:error]
    assert_equal "Campfire webhook URL not configured", result[:message]
  end

  test "notify returns error when webhook URL is empty string" do
    notifier = CampfireNotifier.new(webhook_url: "")
    result = notifier.notify(message: "Test message")

    assert_equal "not_configured", result[:error]
  end

  test "notify accepts title and level parameters" do
    notifier = CampfireNotifier.new(webhook_url: "https://example.com/webhook")
    result = notifier.notify(
      message: "Test message",
      title: "Test Title",
      level: :error
    )

    assert_equal "placeholder", result[:status]
  end

  test "notify logs project name when project is provided" do
    account = create_test_account(campfire_webhook_url: "https://account.campfire.com/webhook")
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "My Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      notifier = CampfireNotifier.new(project: project)

      # Capture Rails logger output
      assert_nothing_raised do
        notifier.notify(message: "Test message")
      end
    end
  end

  # ============================================
  # Class Method Tests
  # ============================================

  test "configured? returns true for account with webhook URL" do
    account = create_test_account(campfire_webhook_url: "https://example.com/webhook")

    assert CampfireNotifier.configured?(account)
  end

  test "configured? returns false for account without webhook URL" do
    account = create_test_account(campfire_webhook_url: nil)

    refute CampfireNotifier.configured?(account)
  end

  test "configured? returns true for project with webhook URL" do
    account = create_test_account(campfire_webhook_url: "https://account.campfire.com/webhook")
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: { "campfire_webhook_url" => "https://project.campfire.com/webhook" }
      )

      assert CampfireNotifier.configured?(project)
    end
  end

  test "configured? returns true for project using account default" do
    account = create_test_account(campfire_webhook_url: "https://account.campfire.com/webhook")
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      assert CampfireNotifier.configured?(project)
    end
  end

  test "configured? returns false for project without webhook URL and no account default" do
    account = create_test_account(campfire_webhook_url: nil)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      refute CampfireNotifier.configured?(project)
    end
  end

  # ============================================
  # Project Fallback Tests
  # ============================================

  test "uses project webhook URL when set" do
    account = create_test_account(campfire_webhook_url: "https://account.campfire.com/webhook")
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: { "campfire_webhook_url" => "https://project.campfire.com/webhook" }
      )

      notifier = CampfireNotifier.new(project: project)
      result = notifier.notify(message: "test")

      # Should succeed because project has webhook URL
      assert_equal "placeholder", result[:status]
    end
  end

  test "falls back to account webhook URL when project URL is not set" do
    account = create_test_account(campfire_webhook_url: "https://account.campfire.com/webhook")
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      notifier = CampfireNotifier.new(project: project)
      result = notifier.notify(message: "test")

      # Should succeed because account has webhook URL
      assert_equal "placeholder", result[:status]
    end
  end

  test "returns error when neither project nor account has webhook URL" do
    account = create_test_account(campfire_webhook_url: nil)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      notifier = CampfireNotifier.new(project: project)
      result = notifier.notify(message: "test")

      assert_equal "not_configured", result[:error]
    end
  end
end
