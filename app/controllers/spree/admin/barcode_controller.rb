require 'barby'
require 'prawn'
require 'prawn/measurement_extensions'
require 'barby/barcode/code_128'
require 'barby/barcode/ean_13'
require 'barby/outputter/png_outputter'

class Spree::Admin::BarcodeController < Spree::Admin::BaseController
  include Admin::BarcodeHelper

  before_action :load, only: :print
  before_action :load_product_and_variants, only: :print_variants_barcodes
  layout :false
  rescue_from ActiveRecord::RecordNotFound, with: :resource_not_found

  def print_variants_barcodes
    if @variants.present?
      pdf = @variants.inject(empty_pdf(height: 120)) { |pdf, variant| append_barcode_to_pdf_for_variant(variant, pdf) }
      send_data pdf.render, type: 'application/pdf', filename: "#{@product.name}.pdf"
    else
      #just to have @variant so that print can be called directly without a request skipping load method
      @variant = @product.master
      print
    end
  end

  # moved to pdf as html has uncontrollable margins
  def print
    pdf = append_barcode_to_pdf_for_variant(@variant)
    send_data pdf.render, type: 'application/pdf', filename: "#{@variant.name}.pdf"
  end

  private

  # leave this in here maybe for later, not used anymore
  # def code
  #   barcode = get_barcode
  #   return unless barcode
  #   send_data barcode.to_png(:xdim => 5) , :type => 'image/png', :disposition => 'inline'
  # end

  def load
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
