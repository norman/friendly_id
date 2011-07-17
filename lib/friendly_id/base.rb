module FriendlyId
  # Class methods that will be added to ActiveRecord::Base.
  module Base

    def has_friendly_id(*args)
      @friendly_id_config.set args.extract_options!.merge(:base => args.shift)
      before_save do |record|
        record.instance_eval {@current_friendly_id = friendly_id}
      end
      include Model
      self
    end

    def friendly_id_config
      @friendly_id_config
    end
  end
end
