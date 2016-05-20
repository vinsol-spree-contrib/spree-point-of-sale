module Admin::BarcodeHelper

  def product_barcode_url
    admin_barcode_code_path(@product.id)
  end
end
