require "test_helper"

class FizzyClientTest < ActiveSupport::TestCase
  # ============================================
  # Initialization Tests
  # ============================================

  test "initializes with board_id parameter" do
    client = FizzyClient.new(board_id: "board-123")

    assert_instance_of FizzyClient, client
  end

  test "initializes with project parameter" do
    account = create_test_account(fizzy_board_id: "account-board", fizzy_enabled: true)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: { "fizzy_board_id" => "project-board" }
      )

      client = FizzyClient.new(project: project)
      assert_instance_of FizzyClient, client
    end
  end

  test "prefers explicit board_id over project board_id" do
    account = create_test_account(fizzy_board_id: "account-board", fizzy_enabled: true)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: { "fizzy_board_id" => "project-board" }
      )

      # When both are provided, explicit board_id wins
      client = FizzyClient.new(board_id: "explicit-board", project: project)
      result = client.create_card(title: "Test", description: "Test")

      assert_equal "placeholder", result[:status]
    end
  end

  test "accepts api_token parameter" do
    client = FizzyClient.new(board_id: "board-123", api_token: "custom-token")

    assert_instance_of FizzyClient, client
  end

  # ============================================
  # Create Card Tests
  # ============================================

  test "create_card returns placeholder status when board is configured" do
    client = FizzyClient.new(board_id: "board-123")
    result = client.create_card(title: "Test Bug", description: "Bug description")

    assert_equal "placeholder", result[:status]
    assert_equal "Fizzy integration pending implementation", result[:message]
  end

  test "create_card returns error when board_id is blank" do
    client = FizzyClient.new(board_id: nil)
    result = client.create_card(title: "Test Bug", description: "Bug description")

    assert_equal "not_configured", result[:error]
    assert_equal "Fizzy board ID not configured", result[:message]
  end

  test "create_card returns error when board_id is empty string" do
    client = FizzyClient.new(board_id: "")
    result = client.create_card(title: "Test Bug", description: "Bug description")

    assert_equal "not_configured", result[:error]
  end

  test "create_card accepts column parameter" do
    client = FizzyClient.new(board_id: "board-123")
    result = client.create_card(
      title: "Test Bug",
      description: "Bug description",
      column: "In Progress"
    )

    assert_equal "placeholder", result[:status]
  end

  test "create_card accepts tags parameter" do
    client = FizzyClient.new(board_id: "board-123")
    result = client.create_card(
      title: "Test Bug",
      description: "Bug description",
      tags: ["critical", "backend"]
    )

    assert_equal "placeholder", result[:status]
  end

  test "create_card uses default Triage column when not specified" do
    client = FizzyClient.new(board_id: "board-123")

    # Default column should be "Triage"
    assert_equal "Triage", FizzyClient::DEFAULT_COLUMN
  end

  # ============================================
  # List Columns Tests
  # ============================================

  test "list_columns returns placeholder status when board is configured" do
    client = FizzyClient.new(board_id: "board-123")
    result = client.list_columns

    assert_equal "placeholder", result[:status]
    assert_includes result[:columns], "Triage"
    assert_includes result[:columns], "In Progress"
    assert_includes result[:columns], "Done"
  end

  test "list_columns returns error when board_id is blank" do
    client = FizzyClient.new(board_id: nil)
    result = client.list_columns

    assert_equal "not_configured", result[:error]
  end

  # ============================================
  # Class Method Tests
  # ============================================

  test "configured? returns true for account with board_id and fizzy_enabled" do
    account = create_test_account(fizzy_board_id: "board-123", fizzy_enabled: true)

    assert FizzyClient.configured?(account)
  end

  test "configured? returns false for account without board_id" do
    account = create_test_account(fizzy_board_id: nil, fizzy_enabled: true)

    refute FizzyClient.configured?(account)
  end

  test "configured? returns false for account with fizzy disabled" do
    account = create_test_account(fizzy_board_id: "board-123", fizzy_enabled: false)

    refute FizzyClient.configured?(account)
  end

  test "configured? returns true for project with board_id and fizzy enabled" do
    account = create_test_account(fizzy_board_id: "account-board", fizzy_enabled: true)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {
          "fizzy_board_id" => "project-board",
          "fizzy_enabled" => true
        }
      )

      assert FizzyClient.configured?(project)
    end
  end

  test "configured? returns true for project using account defaults" do
    account = create_test_account(fizzy_board_id: "account-board", fizzy_enabled: true)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      assert FizzyClient.configured?(project)
    end
  end

  test "configured? returns false for project with fizzy disabled at project level" do
    account = create_test_account(fizzy_board_id: "account-board", fizzy_enabled: true)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: { "fizzy_enabled" => false }
      )

      refute FizzyClient.configured?(project)
    end
  end

  # ============================================
  # Project Fallback Tests
  # ============================================

  test "uses project board_id when set" do
    account = create_test_account(fizzy_board_id: "account-board", fizzy_enabled: true)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: { "fizzy_board_id" => "project-board" }
      )

      client = FizzyClient.new(project: project)
      result = client.create_card(title: "Test", description: "Test")

      assert_equal "placeholder", result[:status]
    end
  end

  test "falls back to account board_id when project board_id is not set" do
    account = create_test_account(fizzy_board_id: "account-board", fizzy_enabled: true)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      client = FizzyClient.new(project: project)
      result = client.create_card(title: "Test", description: "Test")

      assert_equal "placeholder", result[:status]
    end
  end

  test "returns error when neither project nor account has board_id" do
    account = create_test_account(fizzy_board_id: nil, fizzy_enabled: true)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      client = FizzyClient.new(project: project)
      result = client.create_card(title: "Test", description: "Test")

      assert_equal "not_configured", result[:error]
    end
  end

  test "logs project name when project is provided" do
    account = create_test_account(fizzy_board_id: "account-board", fizzy_enabled: true)
    user = create_test_user(account: account)

    with_tenant(account) do
      project = Project.create!(
        name: "My Test Project",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      )

      client = FizzyClient.new(project: project)

      assert_nothing_raised do
        client.create_card(title: "Test Bug", description: "Bug description")
      end
    end
  end
end
