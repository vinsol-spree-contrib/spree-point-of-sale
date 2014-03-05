Spree::Admin::StockLocationsController.class_eval do
  def update
    if @stock_location.update_attributes(permitted_resource_params)
      flash[:success] = flash_message_for(@object, :successfully_updated)
      respond_with(@object) do |format|
        format.html { redirect_to location_after_save }
        format.js   { render :layout => false }
      end
    else
      render :edit
    end
  end
end