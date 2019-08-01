describe Member do

  before { @member = FactoryBot.create(:member) }  
  subject { @member }

  it { should respond_to(:email) }
  it { should respond_to(:password) }
  it { should respond_to(:encrypted_password) }
  it { should respond_to(:image) }

  it "has a valid factory" do
    should be_valid
  end

  context "is invalid without email" do
    before { @member.email = nil }
    it { should_not be_valid }
  end

  context "is invalid without password" do
    before { @member.password = nil }
    it { should_not be_valid }
  end

end
