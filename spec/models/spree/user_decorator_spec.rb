require 'spec_helper'

describe Spree::User do
  let(:user) { Spree::User.new(:email => 'test-user@pos.com', :password => 'testuser') }
  let(:order) { mock_model(Spree::Order) }
  describe 'pending_pos_orders' do
    before do
      @orders = [order]
      user.stub(:orders).and_return(@orders)
      @orders.stub(:pending_pos_order).and_return(@orders)
    end

    it { user.should_receive(:orders).and_return(@orders) }
    it { @orders.should_receive(:pending_pos_order).and_return(@orders) }

    after { user.pending_pos_orders }
  end

  describe '.create_with_random_password' do
    before do
      Spree::User.stub(:create).and_return(user)
    end

    it 'creates a new user' do
      Spree::User.should_receive(:create).and_return(user)
      Spree::User.create_with_random_password('test_user@pos.com')
    end
  end
end