module FriendlyId
  # The configuration paramters passed to +friendly_id+ will be stored in
  # this object.
  class Configuration
    attr_reader :base
    attr_reader :klass
    attr_reader :defaults

    @@defaults = {
      :reserved_words => ["new", "edit"]
    }

    def self.defaults
      @@defaults
    end

    def initialize(klass, values = nil)
      @klass = klass
      @defaults = self.class.defaults.dup
      set values
    end

    def base=(base)
      @base = base
      if @base.respond_to?(:to_s)
        @klass.validates_exclusion_of @base, :in => defaults[:reserved_words]
      end
    end

    def query_field
      base
    end

    def use(*modules)
      modules.compact.each do |name|
        klass.send :include, FriendlyId.const_get(name.to_s.classify)
      end
    end

    def set(values)
      values and values.each {|name, value| self.send "#{name}=", value}
    end
  end
end
