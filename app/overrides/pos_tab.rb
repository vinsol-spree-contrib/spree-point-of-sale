Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "Add Pos tab to menu",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text => " <%= tab( :pos , :url => admin_pos_path) %>",
                     :sequence => {:after => "promo_admin_tabs"},
                     :disabled => false)
