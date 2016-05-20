module Spree
  class BarcodeGeneratorService
    require 'barby'
    require 'barby/barcode/code_128'
    require 'barby/barcode/ean_13'
    require 'barby/outputter/png_outputter'
    require 'prawn'
    require 'prawn/measurement_extensions'

    def append_barcode_to_pdf_for_variants_of_product(variants)
      variants.inject(empty_pdf(height: 120)) { |pdf, variant| append_barcode_to_pdf_for_variant(variant, pdf) }
    end

    def append_barcode_to_pdf_for_variant(variant, pdf = empty_pdf)
      [ variant.name, variant.options_text, (variant.price.to_s + current_symbol) ].each { |item| pdf.text(item) }

      barcode = get_barcode(variant)
      pdf.image(StringIO.new(barcode.to_png(xdim: 5)), width: 50.mm, height: 10.mm, margin: 2.mm) if barcode
      pdf.text(' ')
      pdf
    end

    private

      def empty_pdf(layout = {})
        layout = { width: 54, height: 31, margin: 1 }.merge(layout)
        pdf = ::Prawn::Document.new( page_size: [ layout[:width].mm , layout[:height].mm ], margin: layout[:margin].mm )
      end

      def current_symbol
        currency = ::Spree::Config[:currency]
        currency == 'NGN' ? 'N' : ::Money::Currency.table.find { |key, value| value.has_value?(currency) }[1][:symbol]
      end

      def get_barcode(variant)
        code = variant.sku
        ::Barby::Code128B.new(code) if code
      end
  end
end
