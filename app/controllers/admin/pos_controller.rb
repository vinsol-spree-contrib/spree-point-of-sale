class Admin::PosController < Admin::BaseController
  before_filter :load 
  

  def new
    session[:items] = {}
    redirect_to :action => :index
  end

  
  def add
    if pid = params[:item]
      prod =  Product.find pid
      var = prod.class == Product ? prod.master : prod 
      session[:items][ var.id.to_s ] = var.price 
      flash.notice = t('product_added')
    end
    redirect_to :action => :index
  end

  def remove
    if pid = params[:item]
      session[:items].delete( pid )
      flash.notice = t('product_removed') 
    end
    redirect_to :action => :index
  end

  def print
    order = Order.new
    order.email = current_user.email
    order.save!
    @items.each do |idd , price |
      var = Variant.find(idd)
      puts "Variant #{var.name} #{idd}"
      new_item = LineItem.new(:quantity => 1 )
      new_item.variant = var
      new_item.price = price.to_s 
      order.line_items << new_item
    end
    if id_or_name = Spree::Config[:pos_shipping]
      method = ShippingMethod.find_by_name id_or_name
      method = ShippingMethod.find_by_id(id_or_name) unless method
    end
    order.shipping_method = method || ShippingMethod.first
    order.create_shipment!
    TaxRate.all.each do |rate|
      rate.create_adjustment( rate.tax_category.description , order, order, true)
    end
    payment = Payment.new( :payment_method => PaymentMethod.find_by_type( "PaymentMethod::Check") , 
              :amount => order.total , :order_id => order.id )
    payment.save!
    payment.payment_source.capture(payment)
    order.state = "complete"
    order.completed_at = Time.now
    order.save!
    redirect_to "/admin/invoice/#{order.number}/receipt"
  end
  
  def index
    puts "PROD #{@products.length}"
    if pid = params[:item]
      session[:items][pid] = params["price#{pid}"].to_f
    end
    render :index
  end
  
  def find
    if params[:index]
      search = params[:search]
      search["name_contains"] = search["variants_including_master_sku_contains"]
      search["variants_including_master_sku_contains"] = nil
      init_search
    end
    render :find
  end
    
  private

  def load
    @items = session[:items] || {}
    init_search
  end
  
  def init_search
    params[:search] ||= {}
    params[:search][:meta_sort] ||= "name.asc"
    if params[:search][:variants_including_master_sku_contains] 
      if params[:search][:variants_including_master_sku_contains][0] == 80 and
        params[:search][:variants_including_master_sku_contains][1] != 45
        s = params[:search][:variants_including_master_sku_contains]
        s[0,3] = "P-" # fix some encoding error of american scanner in europe
        params[:search][:variants_including_master_sku_contains] = s
      end
    end
    @search = Product.metasearch(params[:search])

    pagination_options = {:include   => {:variants => [:images, :option_values]},
                          :per_page  => 20 ,
                          :page      => params[:page]}

    @products = @search.relation.group_by_products_id.paginate(pagination_options)
  end
end

