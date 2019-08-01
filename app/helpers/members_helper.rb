module MembersHelper

  def navbar_member_badge_helper(member)
    if member.subscriptions.where(stripe_status: "active").present?
      link_to subscriptions_path do
        content_tag(:li, class: "nav-link") do
          content_tag(:h5) do
            content_tag(:span, class: "badge badge-success") do
              content_tag(:i, "<i class='fa fa-user-circle'></i>&nbsp;&nbsp;Member".html_safe)
            end
          end
        end
      end
    else
      link_to new_membership_path do
        content_tag(:li, class: "nav-item") do
            # = link_to "Create Account".html_safe, new_membership_path,
          content_tag(:button, "<i class='fa fa-exclamation-triangle'></i>&nbsp;&nbsp;Create Account".html_safe)
          # content_tag(:i, "<i class='fa fa-exclamation-triangle'></i>&nbsp;&nbsp;No membership".html_safe)
        end
      end
    end
  end

  def member_image_helper(member)
    if member.provider == ("facebook" || "google_oauth2")
      member.image
    else
      gravatar_url(member, secure: true)
    end
  end

end
