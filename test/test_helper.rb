ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"

# Enable Warden test mode for Devise
Warden.test_mode!

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  # Helper to create a test account
  def create_test_account(attributes = {})
    Account.create!({
      name: "Test Account #{SecureRandom.hex(6)}",
      active: true,
      current_plan: "developer"
    }.merge(attributes))
  end

  # Helper to create a test user with account
  def create_test_user(account: nil, attributes: {})
    account ||= create_test_account
    User.create!({
      email: "test-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      account: account
    }.merge(attributes))
  end

  # Helper to create a test project
  def create_test_project(account: nil, user: nil, attributes: {})
    account ||= create_test_account
    user ||= create_test_user(account: account)

    ActsAsTenant.with_tenant(account) do
      Project.create!({
        name: "Test Project #{SecureRandom.hex(4)}",
        url: "https://example.com",
        environment: "production",
        user: user,
        settings: {}
      }.merge(attributes))
    end
  end

  # Run block with a specific tenant
  def with_tenant(account, &block)
    ActsAsTenant.with_tenant(account, &block)
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  teardown do
    Warden.test_reset!
  end

  # Alternative sign-in method using Warden directly
  def sign_in_user(user)
    login_as(user, scope: :user)
  end
end
