require "test_helper"

class PerformancePrControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!(name: "Test Account #{SecureRandom.hex(4)}")
    @user = User.create!(email: "test-#{SecureRandom.hex(4)}@example.com", password: "password", account: @account)
    login_as @user, scope: :user

    ActsAsTenant.with_tenant(@account) do
      @project = Project.create!(
        name: "Demo Project",
        slug: "demo-#{SecureRandom.hex(4)}",
        url: "http://example.com",
        environment: "production",
        user: @user,
        settings: {
          "github_repo" => "owner/repo",
          "github_pat" => "ghp_xxx"
        }
      )
    end
  end

  teardown do
    Warden.test_reset!
  end

  test "action_detail page renders successfully" do
    ActsAsTenant.with_tenant(@account) do
      get project_performance_action_detail_path(@project, target: "HomeController#index")
    end

    assert_response :success
    assert_includes @response.body, "HomeController#index"
  end

  test "action_detail page shows Open PR button when github is configured" do
    ActsAsTenant.with_tenant(@account) do
      get project_performance_action_detail_path(@project, target: "HomeController#index")
    end

    assert_response :success
    # GitHub is configured, so the Open PR button should be present
    assert_includes @response.body, "Open PR"
  end

  test "create_pr requires authentication" do
    logout :user

    ActsAsTenant.with_tenant(@account) do
      post project_performance_action_create_pr_path(@project, target: "HomeController#index")
    end

    assert_response :redirect
  end
end
