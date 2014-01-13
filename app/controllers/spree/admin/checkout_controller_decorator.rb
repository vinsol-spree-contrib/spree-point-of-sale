Spree::Admin::GeneralSettingsController.class_eval do
  before_filter :update_pos_config, :only => :update

  def update_pos_config
    SpreePos::Config[:pos_shipping] = params[:pos_shipping]
  end
end