module MembershipsHelper

  def amount_helper(amount)
    amount = amount.to_i / 100
    "$" + amount.to_s
  end

  def date_helper(datetime)
    datetime.strftime("%b %d, %Y")
  end

  # Subscriptions table page
  def amount_trialing_helper(subscription)
    if subscription.stripe_status=="trialing"
      "-"
    else
      amount_helper(subscription.amount)
    end
  end

  def date_trialing_helper(subscription)
    if subscription.stripe_status=="trialing"
      "-"
    else
      date_helper(subscription.updated_at)
    end
  end

  def status_trialing_helper(subscription)
    if (!subscription.canceled_at.nil? && subscription.cancel_at_period_end==true && subscription.state=="canceled")
      content_tag(:span, "Canceled on #{date_helper(subscription.canceled_at)}".html_safe, class: "badge badge-danger")
    elsif (!subscription.canceled_at.nil? && subscription.cancel_at_period_end==true && subscription.state=="active")
      content_tag(:span, "Active until #{date_helper(subscription.current_period_end)}".html_safe, class: "badge badge-success")
    elsif
      case
      when subscription.stripe_status == "trialing"
        content_tag(:span, "1 day free trial".html_safe, class: "badge badge-primary")
      when subscription.stripe_status == "active"
        content_tag(:span, "Active".html_safe, class: "badge badge-success")
      when subscription.stripe_status == "past_due"
        content_tag(:span, "Payment due".html_safe, class: "badge badge-warning")
      when subscription.stripe_status == "canceled"
        content_tag(:span, "Canceled on #{date_helper(subscription.canceled_at)}".html_safe, class: "badge badge-danger")
      when subscription.stripe_status == "errored"
        content_tag(:span, "Error".html_safe, class: "badge badge-default")
      end
    end
  end

  def update_credit_card_helper(subscription)
    if (subscription.cancel_at_period_end==false && subscription.state!="canceled")
      render "memberships/update_card",
        email: "#{current_member.email}",
        name: "Update credit card",
        panel_label: "Submit new card",
        guid: "#{subscription.guid}",
        button_text: "Update credit card".html_safe,
        button_class: "btn btn-outline-primary cursor-pointer"
    end
  end

  def cancel_button_helper(subscription)
    if (subscription.cancel_at_period_end==false && subscription.state!="canceled")
      subscription = subscription
      button_text = "Cancel".html_safe
      button_class = "btn btn-outline-danger cursor-pointer"
      confirm_text = "If you cancel, your membership will remain active until the end of the current billing period.\n\nAre you sure you want to cancel?"
      at_period_end = true
      disabled = !subscription.active?
      url = payola.cancel_subscription_path(subscription.guid)
      form_tag(url, method: 'delete', class: 'sweet-alert-from', data: { message: confirm_text }) do
        hidden_field_tag(:at_period_end, at_period_end) +
        button_tag( type: 'submit', class: button_class, disabled: disabled ) do
          content_tag(:span, button_text, class: 'payola-subscription-cancel-buton-text')
        end
      end
    else
      content_tag(:span, "Canceled".html_safe, class: "btn btn-danger disabled")
    end
  end

  def upgrade_button_helper(subscription)
    if (subscription.plan.stripe_id=="monthly" && subscription.state!="canceled")
      render 'payola/subscriptions/change_plan',
        subscription: subscription,
        button_text: "Upgrade plan to #{subscription.plan.upgrade_to_annual.name}
          ($#{subscription.plan.upgrade_to_annual.price_in_dollars}/#{subscription.plan.upgrade_to_annual.interval})",
        button_class: "btn btn-outline-success cursor-pointer",
        new_plan: subscription.plan.upgrade_to_annual,
        quantity: 1
    end
  end

  def upgrade_amount_helper(subscription)
    if (subscription.plan.stripe_id=="monthly" && subscription.state!="canceled")
      content_tag(:small) do
        content_tag(:i, class: "text-muted") do
          "You will only be charged: #{amount_helper(subscription.plan.upgrade_to_annual.amount - subscription.plan.amount)}".html_safe
        end
      end
    end
  end

  # thanks page
  def oto_upgrade_button_helper(subscription)
    render 'payola/subscriptions/change_plan',
      subscription: subscription,
      button_text: "Yes, upgrade me now&nbsp;&nbsp;&nbsp;<i class='fa fa-arrow-circle-right'></i>".html_safe,
      button_class: "btn btn-success cursor-pointer",
      new_plan: subscription.plan.oto_upgrade_to_annual,
      quantity: 1
  end

  def oto_upgrade_amount_helper(subscription)
    content_tag(:p, class: "") do
      # "You will be charged: #{amount_helper(subscription.plan.oto_upgrade_to_annual.amount - subscription.plan.amount)}".html_safe
      "Today pay only $#{subscription.plan.oto_upgrade_to_annual.price_in_dollars / 12}/month ($#{subscription.plan.oto_upgrade_to_annual.price_in_dollars} paid annually)".html_safe
    end
  end

  # Both subscriptions table & thanks page
  def display_updated_amount_helper(stripe_id)
    if stripe_id == "monthly"
      amount_helper(Membership.find_by(stripe_id: "monthly").amount)
    elsif stripe_id == "yearly"
      amount_helper(Membership.find_by(stripe_id: "yearly").amount)
    elsif stripe_id == "yearly_oto"
      amount_helper(Membership.find_by(stripe_id: "yearly_oto").amount)
    elsif stripe_id == "monthly_special"
      amount_helper(Membership.find_by(stripe_id: "monthly_special").amount)
    elsif stripe_id == "annual_special"
      amount_helper(Membership.find_by(stripe_id: "annual_special").amount)
    end
  end

end
