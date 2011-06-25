module FriendlyId
  # Class methods that will be added to ActiveRecord::Base.
  module Base
    extend self

    def has_friendly_id(*args)
      options = args.extract_options!
      base = args.shift
      friendly_id_config.set options.merge(:base => base)
      include Model
      # @NOTE: AR-specific code here
      validates_exclusion_of base, :in => Configuration::DEFAULTS[:reserved_words]
      before_save do |record|
        record.instance_eval {@current_friendly_id = friendly_id}
      end
      self
    end

    def friendly_id_config
      @friendly_id_config ||= Configuration.new(self)
    end

    def uses_friendly_id?
      defined? @friendly_id_config
    end
  end
end

ActiveRecord::Base.extend FriendlyId::Base
