# frozen_string_literal: true

require "test_helper"

class ResourceQuotasTest < ActiveSupport::TestCase
  setup do
    @account = create_test_account(current_plan: "team")
  end

  # ============================================================================
  # PLAN_QUOTAS constant tests
  # ============================================================================

  test "PLAN_QUOTAS defines quotas for all plans" do
    assert_includes ResourceQuotas::PLAN_QUOTAS.keys, :free
    assert_includes ResourceQuotas::PLAN_QUOTAS.keys, :team
    assert_includes ResourceQuotas::PLAN_QUOTAS.keys, :business
  end

  test "PLAN_QUOTAS includes all resource types for each plan" do
    ResourceQuotas::PLAN_QUOTAS.each do |_plan, quotas|
      assert_includes quotas.keys, :events
      assert_includes quotas.keys, :ai_summaries
      assert_includes quotas.keys, :pull_requests
      assert_includes quotas.keys, :uptime_monitors
      assert_includes quotas.keys, :status_pages
    end
  end

  # ============================================================================
  # Event quota tests
  # ============================================================================

  test "event_quota_value returns 5000 for free plan" do
    @account.update!(current_plan: "free")
    assert_equal 5_000, @account.event_quota_value
  end

  test "event_quota_value returns 50000 for team plan" do
    @account.update!(current_plan: "team")
    assert_equal 50_000, @account.event_quota_value
  end

  test "event_quota_value returns 100000 for business plan" do
    @account.update!(current_plan: "business")
    assert_equal 100_000, @account.event_quota_value
  end

  test "event_quota_value defaults to free plan for unknown plan" do
    @account.update!(current_plan: "unknown")
    assert_equal 5_000, @account.event_quota_value
  end

  test "event_quota_value handles different casing" do
    @account.update!(current_plan: "TEAM")
    assert_equal 50_000, @account.event_quota_value

    @account.update!(current_plan: "Team")
    assert_equal 50_000, @account.event_quota_value
  end

  # ============================================================================
  # AI summaries quota tests
  # ============================================================================

  test "ai_summaries_quota returns 5 for free plan" do
    @account.update!(current_plan: "free", ai_summaries_limit: nil)
    assert_equal 5, @account.ai_summaries_quota
  end

  test "ai_summaries_quota returns 300 for team plan" do
    @account.update!(current_plan: "team", ai_summaries_limit: nil)
    assert_equal 300, @account.ai_summaries_quota
  end

  test "ai_summaries_quota returns 500 for business plan" do
    @account.update!(current_plan: "business", ai_summaries_limit: nil)
    assert_equal 500, @account.ai_summaries_quota
  end

  test "ai_summaries_quota uses admin override when set" do
    @account.update!(current_plan: "free", ai_summaries_limit: 999)
    assert_equal 999, @account.ai_summaries_quota
  end

  # ============================================================================
  # Pull requests quota tests
  # ============================================================================

  test "pull_requests_quota returns 5 for free plan" do
    @account.update!(current_plan: "free", pull_requests_limit: nil)
    assert_equal 5, @account.pull_requests_quota
  end

  test "pull_requests_quota returns 100 for team plan" do
    @account.update!(current_plan: "team", pull_requests_limit: nil)
    assert_equal 100, @account.pull_requests_quota
  end

  test "pull_requests_quota returns 250 for business plan" do
    @account.update!(current_plan: "business", pull_requests_limit: nil)
    assert_equal 250, @account.pull_requests_quota
  end

  test "pull_requests_quota uses admin override when set" do
    @account.update!(current_plan: "free", pull_requests_limit: 777)
    assert_equal 777, @account.pull_requests_quota
  end

  # ============================================================================
  # Other quota tests
  # ============================================================================

  test "uptime_monitors_quota returns correct values for each plan" do
    { "free" => 0, "team" => 20, "business" => 5 }.each do |plan, expected|
      @account.update!(current_plan: plan)
      assert_equal expected, @account.uptime_monitors_quota, "Failed for plan: #{plan}"
    end
  end

  test "status_pages_quota returns correct values for each plan" do
    { "free" => 0, "team" => 5, "business" => 1 }.each do |plan, expected|
      @account.update!(current_plan: plan)
      assert_equal expected, @account.status_pages_quota, "Failed for plan: #{plan}"
    end
  end

  test "projects_quota returns correct values for each plan" do
    { "free" => 1, "team" => 10, "business" => 50 }.each do |plan, expected|
      @account.update!(current_plan: plan)
      assert_equal expected, @account.projects_quota, "Failed for plan: #{plan}"
    end
  end

  # ============================================================================
  # within_quota? tests
  # ============================================================================

  test "within_quota? returns true when under quota" do
    @account.update!(current_plan: "team")

    # Stub the usage methods
    @account.stub(:events_used_in_billing_period, 25_000) do
      assert @account.within_quota?(:events)
    end
  end

  test "within_quota? returns false when at quota limit" do
    @account.update!(current_plan: "team", ai_summaries_limit: nil)

    @account.stub(:ai_summaries_used_in_period, 300) do
      refute @account.within_quota?(:ai_summaries)
    end
  end

  test "within_quota? returns false when over quota" do
    @account.update!(current_plan: "team")

    @account.stub(:events_used_in_billing_period, 60_000) do
      refute @account.within_quota?(:events)
    end
  end

  test "within_quota? returns false for invalid resource type" do
    refute @account.within_quota?(:invalid_resource)
  end

  # ============================================================================
  # usage_percentage tests
  # ============================================================================

  test "usage_percentage returns 50.0 when usage is 50%" do
    @account.update!(current_plan: "team", ai_summaries_limit: nil)

    @account.stub(:ai_summaries_used_in_period, 150) do
      assert_equal 50.0, @account.usage_percentage(:ai_summaries)
    end
  end

  test "usage_percentage returns 0.0 when usage is 0%" do
    @account.update!(current_plan: "team", pull_requests_limit: nil)

    @account.stub(:pull_requests_used_in_period, 0) do
      assert_equal 0.0, @account.usage_percentage(:pull_requests)
    end
  end

  test "usage_percentage returns percentage over 100 when over quota" do
    @account.update!(current_plan: "team", ai_summaries_limit: nil)

    @account.stub(:ai_summaries_used_in_period, 450) do
      assert_equal 150.0, @account.usage_percentage(:ai_summaries)
    end
  end

  test "usage_percentage returns 0.0 for invalid resource type" do
    assert_equal 0.0, @account.usage_percentage(:invalid_resource)
  end

  # ============================================================================
  # usage_summary tests
  # ============================================================================

  test "usage_summary returns hash with all resource types" do
    @account.update!(current_plan: "team", ai_summaries_limit: nil, pull_requests_limit: nil)

    @account.stub(:events_used_in_billing_period, 10_000) do
      @account.stub(:ai_summaries_used_in_period, 25) do
        @account.stub(:pull_requests_used_in_period, 3) do
          @account.stub(:uptime_monitors_used, 2) do
            @account.stub(:status_pages_used, 1) do
              @account.stub(:projects_used, 2) do
                summary = @account.usage_summary

                assert_equal %i[events ai_summaries pull_requests uptime_monitors status_pages projects].sort,
                             summary.keys.sort
              end
            end
          end
        end
      end
    end
  end

  test "usage_summary includes correct quota values" do
    @account.update!(current_plan: "team", ai_summaries_limit: nil, pull_requests_limit: nil)

    @account.stub(:events_used_in_billing_period, 10_000) do
      @account.stub(:ai_summaries_used_in_period, 25) do
        @account.stub(:pull_requests_used_in_period, 3) do
          @account.stub(:uptime_monitors_used, 2) do
            @account.stub(:status_pages_used, 1) do
              @account.stub(:projects_used, 2) do
                summary = @account.usage_summary

                assert_equal 50_000, summary[:events][:quota]
                assert_equal 300, summary[:ai_summaries][:quota]
                assert_equal 100, summary[:pull_requests][:quota]
              end
            end
          end
        end
      end
    end
  end

  test "usage_summary includes correct used values" do
    @account.update!(current_plan: "team", ai_summaries_limit: nil, pull_requests_limit: nil)

    @account.stub(:events_used_in_billing_period, 10_000) do
      @account.stub(:ai_summaries_used_in_period, 25) do
        @account.stub(:pull_requests_used_in_period, 3) do
          @account.stub(:uptime_monitors_used, 2) do
            @account.stub(:status_pages_used, 1) do
              @account.stub(:projects_used, 2) do
                summary = @account.usage_summary

                assert_equal 10_000, summary[:events][:used]
                assert_equal 25, summary[:ai_summaries][:used]
                assert_equal 3, summary[:pull_requests][:used]
              end
            end
          end
        end
      end
    end
  end

  test "usage_summary calculates remaining correctly" do
    @account.update!(current_plan: "team", ai_summaries_limit: nil, pull_requests_limit: nil)

    @account.stub(:events_used_in_billing_period, 10_000) do
      @account.stub(:ai_summaries_used_in_period, 25) do
        @account.stub(:pull_requests_used_in_period, 3) do
          @account.stub(:uptime_monitors_used, 2) do
            @account.stub(:status_pages_used, 1) do
              @account.stub(:projects_used, 2) do
                summary = @account.usage_summary

                assert_equal 40_000, summary[:events][:remaining]
                assert_equal 275, summary[:ai_summaries][:remaining]
                assert_equal 97, summary[:pull_requests][:remaining]
              end
            end
          end
        end
      end
    end
  end

  test "usage_summary shows remaining as 0 when over quota" do
    @account.update!(current_plan: "team", ai_summaries_limit: nil, pull_requests_limit: nil)

    @account.stub(:events_used_in_billing_period, 10_000) do
      @account.stub(:ai_summaries_used_in_period, 350) do
        @account.stub(:pull_requests_used_in_period, 3) do
          @account.stub(:uptime_monitors_used, 2) do
            @account.stub(:status_pages_used, 1) do
              @account.stub(:projects_used, 2) do
                summary = @account.usage_summary

                assert_equal 0, summary[:ai_summaries][:remaining]
                assert_equal false, summary[:ai_summaries][:within_quota]
              end
            end
          end
        end
      end
    end
  end

  # ============================================================================
  # effective_plan_name tests
  # ============================================================================

  test "effective_plan_name returns titleized plan name" do
    @account.update!(current_plan: "team")
    assert_equal "Team", @account.effective_plan_name

    @account.update!(current_plan: "free")
    assert_equal "Free", @account.effective_plan_name

    @account.update!(current_plan: "business")
    assert_equal "Business", @account.effective_plan_name
  end
end
