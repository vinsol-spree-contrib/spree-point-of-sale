Spree::Stock::Coordinator.class_eval do
  #overwrite the spree method to not use stores to build packages
  def build_packages(packages = Array.new)
    ::Spree::StockLocation.active.not_store.each do |stock_location|
      packer = build_packer(stock_location, inventory_units)
      packages += packer.packages
    end
    packages
  end
end
