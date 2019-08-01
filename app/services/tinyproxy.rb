class Tinyproxy

  def initialize
    @ec2_client = Aws::EC2::Client.new(region: Rails.application.credentials[Rails.env.to_sym][:AWS_REGION],
                    access_key_id: Rails.application.credentials[Rails.env.to_sym][:AWS_ACCESS_KEY_ID],
                    secret_access_key: Rails.application.credentials[Rails.env.to_sym][:AWS_SECRET_ACCESS_KEY]
                  )
    @ec2_resource = Aws::EC2::Resource.new(region: Rails.application.credentials[Rails.env.to_sym][:AWS_REGION],
                      access_key_id: Rails.application.credentials[Rails.env.to_sym][:AWS_ACCESS_KEY_ID],
                      secret_access_key: Rails.application.credentials[Rails.env.to_sym][:AWS_SECRET_ACCESS_KEY]
                    )
    @instance_id_one =  Rails.application.credentials[Rails.env.to_sym][:TINYPROXY_AWS_INSTANCE_1]
    @instance_id_two =  Rails.application.credentials[Rails.env.to_sym][:TINYPROXY_AWS_INSTANCE_2]
    @proxy_port = Rails.application.credentials[Rails.env.to_sym][:TINYPROXY_PORT]
  end

  def get_instance_private_ip(instance_number = "one")
    instance = get_ectwo_instance(instance_number)
    private_ip_address = instance.private_ip_address
    return private_ip_address
  end

  def get_proxy(rotate_ip = false, instance_number = "one", rotate_instance = false)
    allocate_address(instance_number) if rotate_ip
    if rotate_instance
      proxy = get_next_proxy()
    else
      instance = get_ectwo_instance(instance_number)
      instance_name = instance_number == "one" ? "TINYPROXY 1" : "TINYPROXY 2"
      proxy = {
        "proxy" => "#{instance.private_ip_address}:#{@proxy_port}",
        "ip" => instance.private_ip_address,
        "instance_name" => instance_name
      }
    end
    return proxy
  end

  def get_ectwo_instance(instance_number)
    instance_id = instance_variable_get("@" + "instance_id_#{instance_number}")
    return @ec2_resource.instance(instance_id)
  end

  def allocate_address(instance_number, tinyproxy = nil)
    association_id, public_ip_address = get_association_id(instance_number)
    instance_id = instance_variable_get("@" + "instance_id_#{instance_number}")
    disassociate_address(association_id, public_ip_address)
    allocate_address_result = @ec2_client.allocate_address({
      domain: "vpc"
    })
    add_name_tag_to_elastic_ip(allocate_address_result.allocation_id, instance_number)
    associate_address_result = @ec2_client.associate_address({
      allocation_id: allocate_address_result.allocation_id,
      instance_id: instance_id,
    })
    release_address(tinyproxy) unless tinyproxy.blank?
  end

  def get_association_id(instance_number)
    ip_address = get_proxy(false, instance_number)["ip"]
    association_id = nil
    public_ip_address = nil
    instance_id = instance_variable_get("@" + "instance_id_#{instance_number}")
    describe_addresses_result = @ec2_client.describe_addresses({
      filters: [
        {
          name: "instance-id",
          values: [ instance_id ]
        }
      ]
    })
    if describe_addresses_result.addresses.count == 0
      instance = get_ectwo_instance(instance_number)
      public_ip_address = instance.public_ip_address
    else
      describe_addresses_result.addresses.each do |address|
        if address.private_ip_address == ip_address
          association_id = address.association_id
          break
        end
      end
    end
    return [association_id, public_ip_address]
  end

  def disassociate_address(association_id, public_ip_address)
    if association_id.blank?
      options = {public_ip: public_ip_address}
    else
      options = {association_id: association_id}
    end
    @ec2_client.disassociate_address(options)
  end

  def release_address(tinyproxy)
    ip_address = tinyproxy.ip_address.to_s
    release_address, allocation_id = release_address_available?(ip_address)
    if release_address
      @ec2_client.release_address({
        allocation_id: allocation_id
      })
    end
  end

  def release_address_available?(ip_address)
    status = false
    allocation_id = nil
    addresses = @ec2_client.describe_addresses.addresses
    addresses.each do |address|
      if address.private_ip_address == ip_address && address.domain == "vpc"
        status = true
        allocation_id = address.allocation_id
        break
      end
    end
    return [status, allocation_id]
  end

  def add_name_tag_to_elastic_ip(association_id, instance_number)
    tag_value = instance_number == "one" ? "gafv-tinyproxy-1" : "gafv-tinyproxy-2"
    @ec2_client.create_tags({
      resources: [
        association_id
      ],
      tags: [
        {
          key: "Name",
          value: tag_value
        }
      ]
    })
  end

  def get_next_proxy
    tinyproxy_instance_one_proxy = get_proxy(false, "one")
    tp_one_ip = tinyproxy_instance_one_proxy["ip"]
    tinyproxy_instance_two_proxy = get_proxy(false, "two")
    tp_two_ip = tinyproxy_instance_two_proxy["ip"]
    tinyproxy_one = TinyproxyIp.where("ip_address = ?", tp_one_ip).order('last_used_at ASC').last
    tinyproxy_two = TinyproxyIp.where("ip_address = ?", tp_two_ip).order('last_used_at ASC').last
    if tinyproxy_one.blank? && tinyproxy_two.blank?
      proxy = time_interval_check("tiny_one") ? tinyproxy_instance_two_proxy : tinyproxy_instance_one_proxy
    elsif tinyproxy_one.blank?
      proxy = limit_reached?(tinyproxy_two, "tiny_two") ? tinyproxy_instance_one_proxy : tinyproxy_instance_two_proxy
    elsif tinyproxy_two.blank?
      proxy = limit_reached?(tinyproxy_one, "tiny_one") ? tinyproxy_instance_two_proxy : tinyproxy_instance_one_proxy
    elsif !tinyproxy_one.blank? && !tinyproxy_two.blank?
      proxy = limit_reached?(tinyproxy_one, "tiny_one") ? limit_reached?(tinyproxy_two, "tiny_two", true) ? tinyproxy_instance_one_proxy : tinyproxy_instance_two_proxy : tinyproxy_instance_one_proxy
    end
    return proxy
  end

  def limit_reached?(tinyproxy, proxy_number, validate_both = false)
    time_limit = time_interval_check(proxy_number)
    request_limit = (tinyproxy.total_requests.to_f % Rails.application.credentials[Rails.env.to_sym][:TINYPROXY_REQUEST_LIMIT].to_f) == 0.0
    if validate_both
      status = time_limit && request_limit
    else
      status = time_limit || request_limit
    end
    tinyproxy_ip = TinyproxyIp.where("ip_address = ? and download_status = ?", tinyproxy.ip_address.to_s, "in_progress").last
    rotate_ip_status = tinyproxy_ip.blank? ? true : ((Time.now.utc - tinyproxy_ip.created_at) / 60.0).round > 30
    if status && rotate_ip_status
      tinyproxy_ip.update_attribute(:download_status, 'failed') unless tinyproxy_ip.blank?
      instance_number = proxy_number.split("_").last
      allocate_address(instance_number, tinyproxy)
    end
    status
  end

  def time_interval_check(proxy_number)
    time_now_minutes = Time.now.utc.strftime("%M").to_i
    time_now_minutes = 60 if time_now_minutes == 0
    intervals = []
    i = 1
    loop do
      value = i * Rails.application.credentials[Rails.env.to_sym][:TINYPROXY_USAGE_MINUTES].to_i
      intervals.push(value)
      i = i + 1
      break if value == 60
    end
    set_one_minutes = []
    set_two_minutes = []
    intervals.each_with_index do |interval, index|
      interval_value = ((interval - (Rails.application.credentials[Rails.env.to_sym][:TINYPROXY_USAGE_MINUTES].to_i - 1))..interval).to_a
      if ((index + 1) % 2 == 0)
        set_two_minutes.push(interval_value)
      else
        set_one_minutes.push(interval_value)
      end
    end
    if proxy_number == "tiny_one"
      time_limit = !set_one_minutes.flatten.include?(time_now_minutes)
    elsif proxy_number == "tiny_two"
      time_limit = !set_two_minutes.flatten.include?(time_now_minutes)
    end
    time_limit
  end

end
