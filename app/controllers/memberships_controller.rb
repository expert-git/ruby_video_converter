class MembershipsController < ApplicationController
  before_action :authenticate_member!, only: [:thanks, :subscriptions]
  # before_action :set_membership, only: [:show]

  def new
    if current_member && current_member.subscriptions.active.any?
      redirect_to subscriptions_path
    end
  end

  def new_special
    if current_member && current_member.subscriptions.active.any?
      redirect_to subscriptions_path
    end
  end

  def thanks
    # referred from new membership page
    if request.referrer.present? && (URI(request.referrer).path == "/membership/new" || URI(request.referrer).path == "/membership/new/special")
      flash[:success] = "Success: Membership signup complete."
      @subscription = current_member.subscriptions.active.first

      # if not monthly membership, don't show thanks page and redirect to subscriptions path
      if !(@subscription.plan.stripe_id == "monthly")
        redirect_to subscriptions_path
        return
      end

    # referred from membership page
    elsif request.referrer.present? && URI(request.referrer).path == "/membership"

      if current_member.subscriptions.active.any?
        @subscription = current_member.subscriptions.active.first

        # cancel button clicked
        if (@subscription.cancel_at_period_end? || @subscription.canceled_at?)
          flash[:error] = "Success: Membership has been canceled."
          redirect_to root_path
          return
        end

        # membership upgrade or update credit card button clicked
        redirect_to subscriptions_path
      end

    # referred from thanks page because oto upgrade button clicked
    elsif request.referrer.present? && URI(request.referrer).path == "/thanks"
      @subscription = current_member.subscriptions.active.first
      redirect_to subscriptions_path

    # trying to access thanks page without a membership
    else
      # @subscription = current_member.subscriptions.active.first
      flash[:error] = "Error: You do not have access."
      redirect_back(fallback_location: root_path)
    end
  end

  # def show
  # end

  def subscriptions
    subscriptions = current_member.subscriptions.all.order('created_at DESC')
    @subscriptions = subscriptions.paginate(:page => params[:page], :per_page => 10)
  end

  # private
  # def set_membership
  #   @membership = Membership.find(params[:id])
  # end

end
