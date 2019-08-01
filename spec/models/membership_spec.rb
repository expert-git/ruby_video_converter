describe Membership do

  before { @membership = FactoryBot.create(:membership) }
  subject { @membership }

  it { should respond_to(:name) }
  it { should respond_to(:stripe_id) }
  it { should respond_to(:interval) }
  it { should respond_to(:interval_count) }
  it { should respond_to(:amount) }
  it { should respond_to(:currency) }
  it { should respond_to(:trial_period_days) }

  it "has a valid factory" do
    should be_valid
  end

end