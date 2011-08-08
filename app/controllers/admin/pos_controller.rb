class Admin::PosController < Admin::BaseController
#  resource_controller
  layout  :false
  before_filter :load 
  

  def new
    session[:order] = nil
    redirect_to :action => :index
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
    rescue
      session[:order] = nil
    ensure
      @order = Order.new unless @order
    end
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

