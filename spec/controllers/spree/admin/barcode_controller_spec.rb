require 'spec_helper'

describe Spree::Admin::BarcodeController do
  let(:product) { mock_model(Spree::Product, name: 'test-product') }
  let(:variant) { mock_model(Spree::Variant, name: 'test-variant', price: '12') }
  let(:user) { mock_model(Spree::User) }
  let(:role) { mock_model(Spree::Role) }
  let(:roles) { [role] }

  before do
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(controller).to receive(:authorize_admin).and_return(true)
    allow(controller).to receive(:authorize!).and_return(true)
    allow(user).to receive(:generate_spree_api_key!).and_return(true)
    allow(user).to receive(:roles).and_return(roles)
    allow(roles).to receive(:includes).and_return(roles)
    allow(role).to receive(:ability).and_return(true)
  end

  describe 'print_variants_barcodes' do
    def send_request(params = {})
      spree_get :print_variants_barcodes, params
    end

    before do
      allow(Spree::Product).to receive(:find).with(product.id.to_s).and_return(product)
      allow(controller).to receive(:empty_pdf).and_return([])
      @pdf_object = Object.new
      allow(@pdf_object).to receive(:render).and_return('123')
      allow(variant).to receive(:options_text).and_return('Size: XL, Color: Green')
    end

    context 'when variants present' do
      before do
        allow(product).to receive(:variants).and_return([variant])
        allow(Spree::BarcodeGeneratorService).to receive_message_chain(:new, :append_barcode_to_pdf_for_variant).and_return(@pdf_object)
        allow(Spree::BarcodeGeneratorService).to receive_message_chain(:new, :append_barcode_to_pdf_for_variants_of_product).and_return(@pdf_object)
        allow(controller).to receive(:send_data).with('123' , type: "application/pdf" , filename: "#{product.name}.pdf"){controller.render nothing: true}
      end

      it { expect(product).to receive(:variants).and_return([variant]) }
      it { expect(product).not_to receive(:master) }
      it { expect(controller).not_to receive(:print) }
      it { expect(Spree::Product).to receive(:find).with(product.id.to_s).and_return(product) }
      it { expect(controller).to receive(:send_data).with('123' , type: "application/pdf" , filename: "#{product.name}.pdf"){controller.render nothing: true} }

      after { send_request({id: product.id}) }
    end

    context 'when variants not present' do
      before do
        allow(product).to receive(:variants).and_return([])
        allow(product).to receive(:master).and_return(variant)
        allow(Spree::BarcodeGeneratorService).to receive_message_chain(:new, :append_barcode_to_pdf_for_variant).and_return(@pdf_object)
      end

      it { expect(product).to receive(:variants).and_return([]) }
      it { expect(product).to receive(:master).and_return(variant) }
      it { expect(Spree::Product).to receive(:find).with(product.id.to_s).and_return(product) }
      it { expect(Spree::BarcodeGeneratorService).to receive_message_chain(:new, :append_barcode_to_pdf_for_variant).and_return(@pdf_object) }
      it { expect(controller).to receive(:send_data).with('123' , type: "application/pdf" , filename: "#{variant.name}.pdf"){controller.render nothing: true} }

      after { send_request({id: product.id}) }
    end
  end

  describe 'print' do
    def send_request(params = {})
      spree_get :print, params
    end

    before do
      @pdf_object = Object.new
      allow(@pdf_object).to receive(:render).and_return('123')
      allow(Spree::Variant).to receive(:find).with(variant.id.to_s).and_return(variant)
      allow(Spree::BarcodeGeneratorService).to receive_message_chain(:new, :append_barcode_to_pdf_for_variant).and_return(@pdf_object)
      allow(controller).to receive(:send_data).with('123' , type: "application/pdf" , filename: "#{variant.name}.pdf"){controller.render nothing: true}
      allow(variant).to receive(:options_text).and_return('Size: XL, Color: Green')
    end

    it { expect(Spree::Variant).to receive(:find).with(variant.id.to_s).and_return(variant) }
    it { expect(Spree::BarcodeGeneratorService).to receive_message_chain(:new, :append_barcode_to_pdf_for_variant).and_return(@pdf_object) }
    it { expect(controller).to receive(:send_data).with('123' , type: "application/pdf" , filename: "#{variant.name}.pdf"){controller.render nothing: true} }

    after { send_request({id: variant.id}) }
  end
end
