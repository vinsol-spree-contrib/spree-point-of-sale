Spree::Product.class_eval do
  self.whitelisted_ransackable_associations << 'product_properties'
end
