require 'barby'
require 'barby/barcode/code_128'
class Spree::Admin::BarcodeController < Spree::Admin::BaseController
  include Admin::BarcodeHelper
  
  before_filter :load, :only => [:print]
  before_filter :load_product_and_variants, :only => [:print_variants_barcodes]
  layout :false
  
  def print_variants_barcodes
    if @variants.present?
      pdf = @variants.inject(empty_pdf({:height => 120})) { |pdf, variant| append_barcode_to_pdf_for_variant(variant, pdf) }
      send_data pdf.render , :type => "application/pdf" , :filename => "#{@product.name}.pdf"
    else
      #just to have @variant so that print can be called directly without a request skipping load method
      @variant = @product.master
      print
    end
  end
  
  # moved to pdf as html has uncontrollable margins
  def print
    pdf = append_barcode_to_pdf_for_variant(@variant)
    send_data pdf.render , :type => "application/pdf" , :filename => "#{@variant.name}.pdf"
  end
  
  private

  # leave this in here maybe for later, not used anymore
  # def code
  #   barcode = get_barcode
  #   return unless barcode
  #   send_data barcode.to_png(:xdim => 5) , :type => 'image/png', :disposition => 'inline'
  # end

  def load
    @variant = Spree::Variant.where(:id => params[:id]).first
  end

  def load_product_and_variants
    @product = Spree::Product.where(:id => params[:id]).first
    @variants = @product.variants
  end
end