class Admin::PosController < Admin::BaseController
  before_filter :load 
  

  def new
    session[:items] = []
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
    order.shipping_method = ShippingMethod.find_by_name "nouto"
    order.create_shipment!
    TaxRate.all.each do |rate|
      rate.create_adjustment( rate.tax_category.description , order, order, true)
    end
    payment = Payment.new( :payment_method => PaymentMethod.find_by_type( "PaymentMethod::Check") , 
              :amount => order.total , :order_id => order.id )
    payment.complete
    payment.save!
    order.state = "complete"
    order.completed_at = Time.now
    order.save!
    redirect_to "/admin/invoice/#{order.number}/receipt"
  end
  
  def index
    puts "PROD #{@products.length}"
    
    if pid = params[:add]
      add_product Product.find pid
      flash.notice = t('product_added')
    end
    if pid = params[:remove]
      remove_product pid
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
    var = prod.class == Product ? prod.master : prod 
    @items << [ var.id , var.price ]
    session[:items] = @items
  end
  def load
    @items = session[:items] || []
    init_search
  end
  
  def init_search
    params[:search] ||= {}
    params[:search][:meta_sort] ||= "name.asc"
    puts "NAME -#{params[:search][:variants_including_master_sku_contains][0,3] if params[:search][:variants_including_master_sku_contains]}-"
    if params[:search][:variants_including_master_sku_contains] 
      if params[:search][:variants_including_master_sku_contains][0] == 80 and
        params[:search][:variants_including_master_sku_contains][1] != 45
        s = params[:search][:variants_including_master_sku_contains]
        s[0,3] = "P-" # fix some encoding error of american scanner in europe
        params[:search][:variants_including_master_sku_contains] = s
      end
    end
    puts "NAME2 -#{params[:search][:variants_including_master_sku_contains][0,3] if params[:search][:variants_including_master_sku_contains]}-"
    @search = Product.metasearch(params[:search])

    pagination_options = {:include   => {:variants => [:images, :option_values]},
                          :per_page  => 20 ,
                          :page      => params[:page]}

    @products = @search.relation.group_by_products_id.paginate(pagination_options)
  end
end

