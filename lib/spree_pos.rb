module SpreePos
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*decorator.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
      Deface::Override.new(:virtual_path => "layouts/admin",
                           :name => "Add Pos tab to menu",
                           :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                           :text => " <%= tab :pos %>",
                           :disabled => false)
      Deface::Override.new(:virtual_path => "admin/variants/index",
                           :name => "fix_vat_price",
                           :replace => "td:contains('price')",
                           :text => "<td><%=  variant.tax_price %></td>",
                           :disabled => false)
      if Variant.first and Variant.first.respond_to? :ean
        Deface::Override.new(:virtual_path => "admin/products/_form",
                             :name => "Add ean to product list",
                             :replace => "p:contains('sku')",
                             :text => "<p>
                                    <%= f.label :sku, t(:sku) %> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<%= f.label :ean, t(:ean) %><br>
                                    <%= f.text_field :sku, :size => 16 %> <%= f.text_field :ean, :size => 16 %>
                                    </p>",
                             :disabled => false)
        Deface::Override.new(:virtual_path => "admin/variants/_form",
                             :name => "add_ean_to_variants_edit",
                             :replace => "p:contains('sku')",
                             :text => "<p data-hook='sku'>
                                    <%= f.label :sku, t(:sku) %> <%= f.label :ean, t(:ean) %><br>
                                    <%= f.text_field :sku, :size => 16 %> <%= f.text_field :ean, :size => 16 %>
                                    </p>",
                             :disabled => false)
      else
        puts "POS: EAN support disabled, run migration to activate"
      end

    end

    config.to_prepare &method(:activate).to_proc
  end
end
                     