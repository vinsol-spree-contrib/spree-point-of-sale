require 'spec_helper'

describe Spree::Shipment do
  before do
    @shipment = Spree::Shipment.new
  end

  describe '#finalize_pos' do
    before do
      @inventory_unit = mock_model(Spree::InventoryUnit)
      @inventory_unit.stub(:ship!).and_return(true)
      @inventory_units = [@inventory_unit]
      @shipment.stub(:inventory_units).and_return(@inventory_units)
      @shipment.stub(:state=).with('shipped').and_return(true)
      @shipment.stub(:touch).with(:delivered_at).and_return(true)
      @shipment.stub(:save).and_return(true)
    end

    it { @shipment.should_receive(:state=).with('shipped').and_return(true) }
    it { @shipment.should_receive(:inventory_units).and_return(@inventory_units) }
    it { @inventory_unit.should_receive(:ship!).and_return(true) }
    it { @shipment.should_receive(:touch).with(:delivered_at).and_return(true) }
    it { @shipment.should_receive(:save).and_return(true) }
    after { @shipment.finalize_pos }
  end
end