module SpreePos
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Deface::Override.new(:virtual_path => "layouts/admin",
                           :name => "converted_admin_tabs_801931065",
                           :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                           :text => " <%= tab :pos %>",
                           :disabled => false)

    end

    config.to_prepare &method(:activate).to_proc
  end
end
                     