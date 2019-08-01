class CreateVideoService

  def create
  	Video.find_or_create_by!(ytid: "gvdf5n-zI14")
  end

end
