require 'barby'
require 'prawn'
require 'prawn/measurement_extensions'
require 'barby/barcode/code_128'
require 'barby/barcode/ean_13'
require 'barby/outputter/png_outputter'
class Spree::Admin::BarcodeController < Spree::Admin::BaseController
  before_filter :load 
  layout :false
  
  # moved to pdf as html has uncontrollable margins
  def print
    pdf = Prawn::Document.new( :page_size => [ 54.mm , 25.mm ] , :margin => 1.mm )
    name = @variant.name
    name += " #{@variant.option_values.first.presentation}" if @variant.option_values.first
    pdf.text( name )
    price = @variant.price 
    pdf.text( "#{price} €"  , :align => :right )
    if barcode = get_barcode
      pdf.image( StringIO.new( barcode.to_png(:xdim => 5)) , :width => 50.mm , 
            :height => 10.mm , :at => [ 0 , 10.mm])
    end
    send_data pdf.render , :type => "application/pdf" , :filename => "#{name}.pdf"
  end
    
  # leave this in here maybe for later, not used anymore
  def code
    barcode = get_barcode
    return unless barcode
    send_data barcode.to_png(:xdim => 5) , :type => 'image/png', :disposition => 'inline'
  end
  
  private
  #get the barby barcode object from the id, or nil if something goes wrong
  def get_barcode
    code = nil
    code = @variant.ean if @variant.respond_to?(:ean) 
    code = @variant.sku if (code == nil) or (code == "")
    return nil if (code == nil) or (code == "")
    if code.length == 12
      return ::Barby::EAN13.new( code )
    else
      return ::Barby::Code128B.new( code  )
    end
  end
  
  def load
    @variant = Spree::Variant.find params[:id]
  end

end

