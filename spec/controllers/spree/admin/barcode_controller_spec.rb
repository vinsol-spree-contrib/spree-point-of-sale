require 'spec_helper'

describe Spree::Admin::BarcodeController do
  let(:product) { mock_model(Spree::Product, :name => 'test-product') }
  let(:variant) { mock_model(Spree::Variant, :name => 'test-variant') }
  let(:user) { mock_model(Spree::User) }
  let(:role) { mock_model(Spree::Role) }
  let(:roles) { [role] }

  before do
    controller.stub(:spree_current_user).and_return(user)
    controller.stub(:authorize_admin).and_return(true)
    controller.stub(:authorize!).and_return(true)
    user.stub(:generate_spree_api_key!).and_return(true)
    user.stub(:roles).and_return(roles)
    roles.stub(:includes).and_return(roles)
    role.stub(:ability).and_return(true)
  end

  describe 'print_variants_barcodes' do
    def send_request(params = {})
      get :print_variants_barcodes, params.merge!({:use_route => 'spree'})
    end

    before do
      Spree::Product.stub(:where).with(:id => product.id.to_s).and_return([product])
      controller.stub(:empty_pdf).and_return([])
      @pdf_object = Object.new
      @pdf_object.stub(:render).and_return('123')
    end

    context 'when variants present' do
      before do
        product.stub(:variants).and_return([variant])
        controller.stub(:append_barcode_to_pdf_for_variant).with(variant, []).and_return(@pdf_object)
        controller.stub(:send_data).with('123' , :type => "application/pdf" , :filename => "#{product.name}.pdf").and_return{controller.render :nothing => true}
      end

      it { product.should_receive(:variants).and_return([variant]) }
      it { product.should_not_receive(:master) }
      it { controller.should_not_receive(:print) }
      it { Spree::Product.should_receive(:where).with(:id => product.id.to_s).and_return([product]) }
      it { controller.should_receive(:append_barcode_to_pdf_for_variant).with(variant, []).and_return(@pdf_object) }
      it { controller.should_receive(:send_data).with('123' , :type => "application/pdf" , :filename => "#{product.name}.pdf").and_return{controller.render :nothing => true} }

      after { send_request({:id => product.id}) }
    end

    context 'when variants not present' do
      before do
        product.stub(:variants).and_return([])
        product.stub(:master).and_return(variant)
        controller.stub(:append_barcode_to_pdf_for_variant).with(variant).and_return(@pdf_object)
        controller.stub(:send_data).with('123' , :type => "application/pdf" , :filename => "#{variant.name}.pdf").and_return{controller.render :nothing => true}
      end

      it { product.should_receive(:variants).and_return([]) }
      it { product.should_receive(:master).and_return(variant) }
      it { Spree::Product.should_receive(:where).with(:id => product.id.to_s).and_return([product]) }
      it { controller.should_receive(:append_barcode_to_pdf_for_variant).with(variant).and_return(@pdf_object) }
      it { controller.should_receive(:send_data).with('123' , :type => "application/pdf" , :filename => "#{variant.name}.pdf").and_return{controller.render :nothing => true} }
      
      after { send_request({:id => product.id}) }
    end
  end

  describe 'print' do
    def send_request(params = {})
      get :print, params.merge!({:use_route => 'spree'})
    end

    before do
      @pdf_object = Object.new
      @pdf_object.stub(:render).and_return('123')
      Spree::Variant.stub(:where).with(:id => variant.id.to_s).and_return([variant])
      controller.stub(:append_barcode_to_pdf_for_variant).with(variant).and_return(@pdf_object)
      controller.stub(:send_data).with('123' , :type => "application/pdf" , :filename => "#{variant.name}.pdf").and_return{controller.render :nothing => true}
    end

    it { Spree::Variant.should_receive(:where).with(:id => variant.id.to_s).and_return([variant]) }
    it { controller.should_receive(:append_barcode_to_pdf_for_variant).with(variant).and_return(@pdf_object) }
    it { controller.should_receive(:send_data).with('123' , :type => "application/pdf" , :filename => "#{variant.name}.pdf").and_return{controller.render :nothing => true} }
      
    after { send_request({:id => variant.id}) }
  end
end