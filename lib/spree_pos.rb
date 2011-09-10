module SpreePos
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate

    end

    config.to_prepare &method(:activate).to_proc
  end
end

Deface::Override.new(:virtual_path => "layouts/admin",
                     :name => "converted_admin_tabs_801931065",
                     :insert_after => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :text => " <%= tab :pos %>",
                     :disabled => false)
                     