module SpreePos

  class Engine < Rails::Engine
    engine_name 'spree_pos'

    config.autoload_paths += %W(#{config.root}/lib)

    initializer "spree.spree_pos.preferences", :after => "spree.environment" do |app|
      SpreePos::Config = SpreePos::Configuration.new
    end

    def self.activate

      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*decorator.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
      Deface::Override.new(:virtual_path => "spree/layouts/admin",
                           :name => "Add Pos tab to menu",
                           :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                           :text => " <%= tab( :pos , :url => admin_pos_path) %>",
                           :sequence => {:after => "promo_admin_tabs"},
                           :disabled => false)
      Deface::Override.new(:virtual_path => "spree/admin/variants/index",
                           :name => "fix_vat_price",
                           :replace => "td:contains('price')",
                           :text => "<td><%=  variant.price %></td>",
                           :disabled => false)
      if Spree::Variant.first and Spree::Variant.first.respond_to? :ean
        Deface::Override.new(:virtual_path => "spree/admin/products/_form",
                             :name => "Add ean to product form",
                             :insert_after => "code[erb-silent]:contains('has_variants')",
                             :text => "<% unless @product.has_variants? %> <p>
                                    <%= f.label :ean, t(:ean) %><br>
                                    <%= f.text_field :ean, :size => 16 %>
                                    </p> <%end%>",
                             :disabled => false)
        Deface::Override.new(:virtual_path => "spree/admin/variants/_form",
                             :name => "add_ean_to_variants_edit",
                             :insert_after => "[data-hook='sku']",
                             :text => "<p data-hook='ean'>
                                    <%= f.label :ean, t(:ean) %><br>
                                    <%= f.text_field :ean, :size => 16 %>
                                    </p>",
                             :disabled => false)
      else
        puts "POS: EAN support disabled, run migration to activate"
      end
      Spree::Variant.class_eval do

        def tax_price
          (self.price * (1 + self.product.effective_tax_rate)).round(2, BigDecimal::ROUND_HALF_UP)
        end
      end
      Spree::Product.class_eval do

        delegate_belongs_to :master, :ean

      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
