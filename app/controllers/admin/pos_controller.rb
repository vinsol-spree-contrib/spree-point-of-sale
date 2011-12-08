class Admin::PosController < Admin::BaseController

  def new
    init
    redirect_to :action => :index
  end

  def export
    unless session[:items]
      index
      return
    end
    missing = []
    session[:items].each do |key , item | 
      missing << item.variant.full_name if item.variant.ean.blank?
    end
    unless missing.empty?
      flash[:error] = "All items must have ean set, missing: #{missing.join(' , ')}"
      redirect_to :action => "index" 
      return
    end
    opt = {}
    session[:items].each do |key , item | 
      var = item.variant
      opt[var.ean] = item.quantity
      var.on_hand =  var.on_hand - item.quantity
      var.save!
    end
    init  # reset this pos
    opt[:host] = Spree::Config[:pos_export] 
    opt[:controller] = "pos" 
    opt[:action] = "import" 
    redirect_to opt
  end
  
  def import
    init
    added = 0
    params.each do |id , quant |
      next if id == "action" 
      next if id == "controller" 
      v = Variant.find_by_ean id
      if v 
        add_variant(v , quant )
        added += 1
      else
        v = Variant.find_by_sku id
        if v 
          add_variant(v , quant )
          added += 1
        else
          add_error "No product found for EAN #{id}     "
        end
      end
    end
    add_notice "Added #{added} products" if added
    redirect_to :action => :index
  end
  
  def inventory
    as = params[:as]
    num = 0 
    session[:items].each_value do |item |
      variant = item.variant
      num += item.quantity
      if as
        variant.on_hand = item.quantity
      else
        variant.on_hand += item.quantity
      end
      variant.save
    end
    flash.notice = "Total of #{num} items added for #{session[:items].length} products "     
    self.new
  end
  
  def add
    if pid = params[:item]
      add_variant Variant.find pid
    end
    redirect_to :action => :index
  end

  def remove
    if pid = params[:item]
      if( item = session[:items][pid] )
        if item.quantity > 1 
          item.quantity = item.quantity - 1
        else
          session[:items].delete( pid )
        end
        flash.notice = t('product_removed') 
      end
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
      order.user = current_user
      order.email = current_user.email
      order.save!
      if id_or_name = Spree::Config[:pos_shipping]
        method = ShippingMethod.find_by_name id_or_name
        method = ShippingMethod.find_by_id(id_or_name) unless method
      end
      order.shipping_method = method || ShippingMethod.first
      order.create_shipment!
    end
    session[:items].each_value do |item |
      puts "Variant #{item.variant.name} #{item.id}"
      new_item = LineItem.new(:quantity => item.quantity  )
      new_item.variant_id = item.id
      puts "PRICE #{item.no_tax_price} #{item.no_tax_price.class}"
      new_item.price = item.no_tax_price
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
    order.finalize!
    order.save!
    session[:pos_order] = order.id
    redirect_to "/admin/invoice/#{order.number}/receipt"
  end
  
  def index
    if (pid = params[:price]) && request.post?
      item =  session[:items][pid] 
      puts "#{session[:items].first[0].class} + item #{item.class}"
      item.price = params["price#{pid}"].to_f
    end
    if (pid = params[:quantity_id]) && request.post?
      item =  session[:items][pid] 
      puts "#{session[:items].first[0].class} + item #{item.class}"
      item.quantity = params[:quantity].to_i
    end
    if discount = params[:discount]
      if params[:item]
        item = session[:items][params[:item]]
        item.discount( discount )
      else
        session[:items].each_value do |item|
          item.discount( discount )
        end
      end
    end
    if sku = params[:sku]
      prods = Variant.where(:sku => sku ).limit(2)
      if prods.length == 0 and Variant.instance_methods.include? "ean"
        prods = Variant.where(:ean => sku ).limit(2)
      end
      if prods.length == 1
        add_variant prods.first
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
  
  def add_notice no
    flash[:notice] = "" unless flash[:notice]
    flash[:notice] << no
  end
  def add_error no
    flash[:error] = "" unless flash[:error]
    flash[:error] << no
  end
  
  def init
    session[:items] = {}
    session[:pos_order] = nil
  end
  def add_variant var , quant = 1
    session[:items] = {} unless session[:items]
    item = session[:items][ var.id.to_s ] || PosItem.new( var )
    item.quantity = item.quantity + quant.to_i
    session[:items][ var.id.to_s ] = item 
    #flash.notice = t('product_added')
  end
  
  def init_search
    params[:search] ||= {}
    params[:search][:meta_sort] ||= "product_name.asc"
    params[:search][:deleted_at_is_null] = "1"
    params[:search][:product_deleted_at_is_null] = "1"
    @search = Variant.metasearch(params[:search])

    @variants = @search.relation.page(params[:page]).per(20)
  end
end

