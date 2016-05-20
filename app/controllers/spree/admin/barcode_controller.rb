class Spree::Admin::BarcodeController < Spree::Admin::BaseController
  include Admin::BarcodeHelper

  before_action :load_variant, only: :print
  before_action :load_product_and_variants, only: :print_variants_barcodes
  layout :false
  rescue_from ActiveRecord::RecordNotFound, with: :resource_not_found

  def print_variants_barcodes
    if @variants.present?
      pdf = Spree::BarcodeGeneratorService.new.append_barcode_to_pdf_for_variants_of_product(@variants)
      send_data pdf.render, type: 'application/pdf', filename: "#{ @product.name }.pdf"
    else
      #just to have @variant so that print can be called directly without a request skipping load method
      @variant = @product.master
      print
    end
  end

  # moved to pdf as html has uncontrollable margins
  def print
    pdf = Spree::BarcodeGeneratorService.new.append_barcode_to_pdf_for_variant(@variant)
    send_data pdf.render, type: 'application/pdf', filename: "#{ @variant.name }.pdf"
  end

  private

  # leave this in here maybe for later, not used anymore
  # def code
  #   barcode = get_barcode
  #   return unless barcode
  #   send_data barcode.to_png(:xdim => 5) , :type => 'image/png', :disposition => 'inline'
  # end

  def load_variant
    @variant = Spree::Variant.find(params[:id])
  end

  def load_product_and_variants
    @product = Spree::Product.find(params[:id])
    @variants = @product.variants
  end

  def resource_not_found
    flash[:error] = flash_message_for(model_class.new, :not_found)
    redirect_to collection_url
  end
end
