module Admin::PosHelper

  def admin_pos_products_path
    "/admin/pos/find"
  end
  
  def item_total
    sum = 0 
    items.each do |id , price|
      sum += price
    end
    sum
  end 

  def items
    session[:items] || {}
  end
end
