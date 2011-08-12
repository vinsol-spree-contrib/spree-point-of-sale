class Admin::PosController < Admin::BaseController
  before_filter :load 
  

  def new
    session[:order] = nil
    redirect_to :action => :index
  end

  def print
    unless @order.shipment
      @order.shipping_method = ShippingMethod.find_by_name "nouto"
      @order.create_shipment!
    end
    unless @order.payment
      TaxRate.all.each do |rate|
        rate.create_adjustment( rate.tax_category.description , @order, @order, true)
      end 
      payment = Payment.new( :payment_method => PaymentMethod.find_by_type( "PaymentMethod::Check") , 
                :amount => @order.total , :order_id => @order.id )
      payment.complete
      payment.save!
    end
    unless @order.completed?
      @order.state = "complete"
      @order.completed_at = Time.now
    end
    redirect_to "/admin/invoice/#{@order.number}/receipt"
  end
  
  def index
    unless session[:order]
      @order.save!
      session[:order] = @order.id 
    end
    puts "PROD #{@products.length}"
    
    if pid = params[:add]
      add_product Product.find pid
      flash.notice = t('product_added')
    end
    if pid = params[:remove]
      remove_product Product.find pid
      flash.notice = t('product_removed')
    end
    render :index
  end
  
  def find
    if @products.length == 1
      add_product @products.first 
      redirect_to :action => :index
    else
      if params[:index]
        search = params[:search]
        search["name_contains"] = search["variants_including_master_sku_contains"]
        search["variants_including_master_sku_contains"] = nil
        init_search
      end
      render :find
    end
  end
    
  private

  def add_product prod
    new_item = LineItem.new(:quantity => 1)
    var = prod.class == Product ? prod.master : prod 
    new_item.variant = var
    new_item.price   = var.price
    @order.line_items << new_item
    @order.save!
  end
  def load
    begin
      @order = Order.find session[:order]
      @order.shipping_method = ShippingMethod.find_by_name "nouto"
    rescue
      session[:order] = nil
    ensure
      @order = Order.new unless @order
    end
    @order.email = current_user.email
    @empty = params[:search] == nil
    init_search
  end
  
  def init_search
    params[:search] ||= {}
    params[:search][:meta_sort] ||= "name.asc"
    @search = Product.metasearch(params[:search])

    pagination_options = {:include   => {:variants => [:images, :option_values]},
                          :per_page  => 20 ,
                          :page      => params[:page]}

    @products = @search.relation.group_by_products_id.paginate(pagination_options)
  end
end

