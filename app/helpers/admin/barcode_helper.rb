module Admin::BarcodeHelper

  def product_barcode_url
    "/admin/barcode/code/#{@product.id}"
  end
  #"http://generator.onbarcode.com/linear.aspx?SHOW-START-STOP-IN-TEXT=false&X=3&Y=75&TYPE=7&DATA=<%=@product.sku%>" 
end
