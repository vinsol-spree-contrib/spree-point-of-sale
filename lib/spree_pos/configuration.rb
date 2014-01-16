require "spree/core"
module SpreePos
  class Configuration < Spree::Preferences::Configuration
    preference :pos_shipping, :string
    preference :pos_printing, :string , :default => "/admin/invoice/number/receipt"
  end
end