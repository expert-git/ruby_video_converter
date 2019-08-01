class Membership < ApplicationRecord
  include Payola::Plan

  # validates :stripe_id, inclusion: { in: Membership.pluck('DISTINCT stripe_id'), message: "Error: not a valid membership plan" }

  def price_in_dollars
    self.amount.to_i / 100
  end

  def downgrade_to_monthly
    Membership.find_by(stripe_id: "monthly")
  end

  def upgrade_to_annual
    Membership.find_by(stripe_id: "yearly")
  end

  def oto_upgrade_to_annual
    Membership.find_by(stripe_id: "yearly_oto")
  end

  def redirect_path(subscription)
    # you can return any path here, possibly referencing the given subscription
    # thanks_path => from routes.rb: get "thanks", to: "memberships#thanks", as: :thanks
    "/thanks"
  end

end
