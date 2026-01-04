class LifecycleMailer < ApplicationMailer
  def welcome(account:)
    @account = account
    mail to: account.users.first.email, subject: "Welcome to ActiveRabbit"
  end

  def activation_tip(account:)
    @account = account
    mail to: account.users.first.email, subject: "Ship your first alert"
  end

  def quota_nudge(account:, percent:)
    @account = account
    @percent = percent
    mail to: account.users.first.email, subject: "You're at #{@percent}% of your monthly quota"
  end
end
