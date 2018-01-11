module FriendlyId
  class Railtie < Rails::Railtie
    initializer 'friendly_id.setup' do
      ActiveSupport.on_load(:active_record) do
        FriendlyId.mark_as_unfriendly(ActiveRecord::Base)
      end
    end
  end
end
