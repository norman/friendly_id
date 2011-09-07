module FriendlyId
  # Instance methods that will be added to all classes using FriendlyId.
  module Model

    attr_reader :current_friendly_id

    # Convenience method for accessing the class method of the same name.
    def friendly_id_config
      self.class.friendly_id_config
    end

    # Get the instance's friendly_id.
    def friendly_id
      send friendly_id_config.query_field
    end

    # Either the friendly_id, or the numeric id cast to a string.
    def to_param
      if diff = changes[friendly_id_config.query_field]
        diff.first
      else
        friendly_id.present? ? friendly_id : id.to_s
      end
    end
  end
end
