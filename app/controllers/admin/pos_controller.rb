class Admin::PosController < Admin::BaseController

  def new
    session[:items] = {}
    redirect_to :action => :index
  end

  def add
    if pid = params[:item]
      add_product Product.find pid
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
    session[:items].each do |idd , price |
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
    if pid = params[:price]
      session[:items][pid] = params["price#{pid}"].to_f
    end
    if discount = params[:discount]
      pids = params[:item] ? [params[:item]] : session[:items].keys
      pids.each do |pid|
        if discount == "0" #reset
          session[:items][pid] = Variant.find(pid).price
        else
          session[:items][pid] = (100.0 - discount.to_f) * session[:items][pid] / 100.0 
        end
      end
    end
    if sku = params[:sku]
      prods = Variant.where(:sku => sku ).limit(5)
      if prods.length == 1
        add_product prods.first
      else
        redirect_to :action => :find , "search[name_contains]" => sku
        return
      end
    end
    render :index
  end
  
  def find
    init_search
    if params[:index]
      search = params[:search]
      search["name_contains"] = search["variants_including_master_sku_contains"]
      search["variants_including_master_sku_contains"] = nil
      init_search
    end
    render :find
  end
    
  private
  
  
  def add_product prod
    var = prod.class == Product ? prod.master : prod 
    session[:items] = {} unless session[:items]
    session[:items][ var.id.to_s ] = var.price 
    #flash.notice = t('product_added')
  end
  
  def init_search
    params[:search] ||= {}
    params[:search][:meta_sort] ||= "name.asc"
    @search = Product.metasearch(params[:search])

    @products = @search.relation.group_by_products_id.includes(:variants => [:images, :option_values]).page(params[:page]).per(20)
  end
end

