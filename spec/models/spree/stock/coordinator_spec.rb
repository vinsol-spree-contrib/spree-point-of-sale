require 'spec_helper'

describe Spree::Stock::Coordinator do
  let(:order) { Spree::Order.create! }
  let(:country) { Spree::Country.create!(:name => 'mk_country', :iso_name => "mk") }
  let(:state) { country.states.create!(:name => 'mk_state') }
  
  describe 'build_packages' do
    before do
      @stock_location = Spree::StockLocation.create!(:name => 'stock', :store => false, :active => true, :address1 => "home", :address2 => "town", :city => "delhi", :zipcode => "110034", :country_id => country.id, :state_id => state.id, :phone => "07777676767")
      @active_store = Spree::StockLocation.create!(:name => 'store', :store => true, :active => true, :address1 => "home", :address2 => "town", :city => "delhi", :zipcode => "110034", :country_id => country.id, :state_id => state.id, :phone => "07777676767")
      @inactive_store = Spree::StockLocation.create!(:name => 'inactive-store', :store => true, :active => false, :address1 => "home", :address2 => "town", :city => "delhi", :zipcode => "110034", :country_id => country.id, :state_id => state.id, :phone => "07777676767")
      @coordinator = Spree::Stock::Coordinator.new(order)
      @packer = Spree::Stock::Packer.new(@stock_location, order)
      @package = Spree::Stock::Package.new(@stock_location, order)
      @packer.stub(:packages).and_return([@package])
      @coordinator.stub(:build_packer).with(@stock_location, order).and_return(@packer)
    end

    describe 'build packages for only active stock locations' do
      it { @packer.should_receive(:packages).and_return([@package]) }
      it { @coordinator.should_receive(:build_packer).with(@stock_location, order).and_return(@packer) }
      it { @coordinator.should_not_receive(:build_packer).with(@inactive_store, order) }
      it { @coordinator.should_not_receive(:build_packer).with(@active_store, order) }

      after { @coordinator.build_packages([]) }
    end

    it { @coordinator.build_packages([]).should eq([@package]) }
  end
end