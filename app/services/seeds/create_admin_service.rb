class CreateAdminService

  def create
    Member.find_or_create_by!(email: Rails.application.credentials[Rails.env.to_sym][:ADMIN_EMAIL]) do |member|
      member.password = Rails.application.credentials[Rails.env.to_sym][:ADMIN_PASSWORD]
      member.password_confirmation = Rails.application.credentials[Rails.env.to_sym][:ADMIN_PASSWORD]
      member.admin = true
    end
  end

end
