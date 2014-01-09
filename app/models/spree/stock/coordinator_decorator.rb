# Spree::Stock::Coordinator.class_eval do
#   #overwrite the spree method to not use stores to build packages
#   def build_packages(packages)
#     ::Spree::StockLocation.active.not_store.each do |stock_location|
#       packer = build_packer(stock_location, order)
#       packages += packer.packages
#     end
#     packages
#   end
# end