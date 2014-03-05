Deface::Override.new(:virtual_path => "spree/admin/shared/_menu",
                     :name => "Add Pos tab to menu",
                     :insert_bottom => "[data-hook='admin_tabs']",
                     :text => " <%= tab( :pos , :url => admin_pos_path) %>",
                     :sequence => {:after => "promo_admin_tabs"},
                     :disabled => false)
