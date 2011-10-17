class Admin::PosController < Admin::BaseController

  def new
    session[:items] = {}
    session[:pos_order] = nil
    redirect_to :action => :index
  end

  def add
    if pid = params[:item]
      add_product Variant.find pid
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
    order_id = session[:pos_order]
    if order_id
      order = Order.find order_id
      order.line_items.clear
    else
      order = Order.new
      order.email = current_user.email
      order.save!
      if id_or_name = Spree::Config[:pos_shipping]
        method = ShippingMethod.find_by_name id_or_name
        method = ShippingMethod.find_by_id(id_or_name) unless method
      end
      order.shipping_method = method || ShippingMethod.first
      order.create_shipment!
#      TaxRate.all.each do |rate|
#        rate.create_adjustment( rate.tax_category.description , order, order, true)
#      end
    end
    session[:items].each do |idd , price |
      var = Variant.find(idd)
      puts "Variant #{var.name} #{idd}"
      new_item = LineItem.new(:quantity => 1 )
      new_item.variant = var
      new_item.price = price.to_s 
      order.line_items << new_item
    end
    if order_id
      order.payment.delete
    end
    payment = Payment.new( :payment_method => PaymentMethod.find_by_type( "PaymentMethod::Check") , 
              :amount => order.total , :order_id => order.id )
    payment.save!
    payment.payment_source.capture(payment)
    order.state = "complete"
    order.completed_at = Time.now
    order.save!
    session[:pos_order] = order.id
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
        redirect_to :action => :find , "search[product_name_contains]" => sku
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
    params[:search][:meta_sort] ||= "product_name.asc"
    @search = Variant.metasearch(params[:search])

    @variants = @search.relation.page(params[:page]).per(20)
  end
end

