require "sequel"
require File.join(File.dirname(__FILE__), "sequel", "simple_model")
require File.join(File.dirname(__FILE__), "sequel", "slugged_model")

module Sequel

  module Plugins

    module FriendlyId

      def self.configure(model, method, opts={})
        model.instance_eval do
          if friendly_id_config.use_slug?
            include ::FriendlyId::Sequel::SluggedModel
          else
            include ::FriendlyId::Sequel::SimpleModel
          end
        end
      end

      module ClassMethods
        attr_accessor :friendly_id_config
        def friendly_id_config
          @friendly_id_config ||= ::FriendlyId::Configuration.new(self, *friendly_id_opts)
        end
      end

    end
  end

end