module Admin::PosHelper

  def admin_pos_variants_path
    "/admin/pos/find"
  end
  
  def item_total
    sum = 0 
    items.each do |id , item|
      sum += item.price * item.quantity
    end
    sum
  end 

  def items
    session[:items] || {}
  end
end
