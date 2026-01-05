require "test_helper"

class ProjectSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!(
      name: "Test Account",
      active: true,
      current_plan: "developer",
      campfire_webhook_url: "https://account.campfire.com/webhook",
      fizzy_board_id: "account-board-123",
      fizzy_enabled: true
    )

    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      account: @account
    )

    ActsAsTenant.with_tenant(@account) do
      @project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: @user,
        settings: {}
      )

      # Create default API token
      @project.generate_api_token!

      # Create default alert rules for notification preferences
      @project.create_default_alert_rules!
    end

    login_as @user, scope: :user
  end

  teardown do
    Warden.test_reset!
  end

  # ============================================
  # Show Action Tests
  # ============================================

  test "show renders project settings page" do
    ActsAsTenant.with_tenant(@account) do
      get project_settings_path(@project)
    end

    assert_response :success
  end

  # ============================================
  # Update Campfire Settings Tests
  # ============================================

  test "update saves project-specific campfire webhook URL" do
    ActsAsTenant.with_tenant(@account) do
      put project_settings_path(@project), params: {
        project: {
          campfire_webhook_url: "https://project.campfire.com/webhook"
        }
      }
    end

    assert_redirected_to project_settings_path(@project)

    @project.reload
    assert_equal "https://project.campfire.com/webhook", @project.settings["campfire_webhook_url"]
  end

  test "update clears campfire webhook URL when blank" do
    ActsAsTenant.with_tenant(@account) do
      # First set a value
      @project.settings["campfire_webhook_url"] = "https://old.campfire.com/webhook"
      @project.save!

      # Then clear it
      put project_settings_path(@project), params: {
        project: {
          campfire_webhook_url: ""
        }
      }
    end

    assert_redirected_to project_settings_path(@project)

    @project.reload
    assert_nil @project.settings["campfire_webhook_url"]
  end

  test "update enables campfire notifications channel" do
    ActsAsTenant.with_tenant(@account) do
      put project_settings_path(@project), params: {
        project: {
          notifications: {
            enabled: "1",
            channels: {
              campfire: "1"
            }
          }
        }
      }
    end

    assert_redirected_to project_settings_path(@project)

    @project.reload
    assert @project.settings.dig("notifications", "channels", "campfire")
  end

  test "update disables campfire notifications channel" do
    ActsAsTenant.with_tenant(@account) do
      # First enable it
      @project.settings["notifications"] = {
        "enabled" => true,
        "channels" => { "campfire" => true }
      }
      @project.save!

      # Then disable it
      put project_settings_path(@project), params: {
        project: {
          notifications: {
            enabled: "1",
            channels: {
              campfire: "0"
            }
          }
        }
      }
    end

    @project.reload
    refute @project.settings.dig("notifications", "channels", "campfire")
  end

  # ============================================
  # Update Fizzy Settings Tests
  # ============================================

  test "update saves project-specific fizzy board ID" do
    ActsAsTenant.with_tenant(@account) do
      put project_settings_path(@project), params: {
        project: {
          fizzy_board_id: "project-board-456"
        }
      }
    end

    assert_redirected_to project_settings_path(@project)

    @project.reload
    assert_equal "project-board-456", @project.settings["fizzy_board_id"]
  end

  test "update clears fizzy board ID when blank" do
    ActsAsTenant.with_tenant(@account) do
      # First set a value
      @project.settings["fizzy_board_id"] = "old-board"
      @project.save!

      # Then clear it
      put project_settings_path(@project), params: {
        project: {
          fizzy_board_id: ""
        }
      }
    end

    assert_redirected_to project_settings_path(@project)

    @project.reload
    assert_nil @project.settings["fizzy_board_id"]
  end

  test "update enables fizzy for project" do
    ActsAsTenant.with_tenant(@account) do
      put project_settings_path(@project), params: {
        project: {
          fizzy_enabled: "1"
        }
      }
    end

    assert_redirected_to project_settings_path(@project)

    @project.reload
    assert @project.settings["fizzy_enabled"]
  end

  test "update disables fizzy for project" do
    ActsAsTenant.with_tenant(@account) do
      # First enable it
      @project.settings["fizzy_enabled"] = true
      @project.save!

      # Then disable it
      put project_settings_path(@project), params: {
        project: {
          fizzy_enabled: "0"
        }
      }
    end

    @project.reload
    refute @project.settings["fizzy_enabled"]
  end

  # ============================================
  # Combined Settings Update Tests
  # ============================================

  test "update saves both campfire and fizzy settings together" do
    ActsAsTenant.with_tenant(@account) do
      put project_settings_path(@project), params: {
        project: {
          campfire_webhook_url: "https://combined.campfire.com/webhook",
          fizzy_board_id: "combined-board",
          fizzy_enabled: "1"
        }
      }
    end

    assert_redirected_to project_settings_path(@project)

    @project.reload
    assert_equal "https://combined.campfire.com/webhook", @project.settings["campfire_webhook_url"]
    assert_equal "combined-board", @project.settings["fizzy_board_id"]
    assert @project.settings["fizzy_enabled"]
  end

  test "update preserves other settings when updating integrations" do
    ActsAsTenant.with_tenant(@account) do
      # Set some existing settings
      @project.settings["github_repo"] = "owner/repo"
      @project.save!

      # Update campfire settings
      put project_settings_path(@project), params: {
        project: {
          campfire_webhook_url: "https://project.campfire.com/webhook"
        }
      }
    end

    @project.reload
    # GitHub settings should be preserved
    assert_equal "owner/repo", @project.settings["github_repo"]
    # Campfire settings should be updated
    assert_equal "https://project.campfire.com/webhook", @project.settings["campfire_webhook_url"]
  end

  # ============================================
  # Notification Channel Tests
  # ============================================

  test "update saves all notification channels together" do
    ActsAsTenant.with_tenant(@account) do
      put project_settings_path(@project), params: {
        project: {
          notifications: {
            enabled: "1",
            channels: {
              slack: "1",
              email: "1",
              campfire: "1"
            }
          }
        }
      }
    end

    @project.reload
    assert @project.settings.dig("notifications", "enabled")
    assert @project.settings.dig("notifications", "channels", "slack")
    assert @project.settings.dig("notifications", "channels", "email")
    assert @project.settings.dig("notifications", "channels", "campfire")
  end

  test "update disables all notification channels" do
    ActsAsTenant.with_tenant(@account) do
      # First enable all
      @project.settings["notifications"] = {
        "enabled" => true,
        "channels" => { "slack" => true, "email" => true, "campfire" => true }
      }
      @project.save!

      # Then disable all
      put project_settings_path(@project), params: {
        project: {
          notifications: {
            enabled: "0",
            channels: {}
          }
        }
      }
    end

    @project.reload
    refute @project.settings.dig("notifications", "enabled")
  end

  # ============================================
  # Authentication Tests
  # ============================================

  test "redirects to login when not authenticated" do
    logout :user

    ActsAsTenant.with_tenant(@account) do
      get project_settings_path(@project)
    end

    assert_response :redirect
  end
end
