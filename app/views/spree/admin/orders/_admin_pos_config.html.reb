<fieldset class="no-border-bottom">
  <legend align="center">Pos Settings</legend>
  <label>Pos Shipping Method</label>
  <%= select_tag :pos_shipping, options_from_collection_for_select(Spree::ShippingMethod.all, :name, :name, SpreePos::Config[:pos_shipping]), :class => 'fullwidth' %>
</fieldset>
