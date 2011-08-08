require 'spree_pos_hooks'

module SpreePos
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate

    end

    config.to_prepare &method(:activate).to_proc
  end
end
