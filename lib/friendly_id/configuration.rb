module FriendlyId
  # The configuration paramters passed to +has_friendly_id+ will be stored in
  # this object.
  class Configuration
    attr_accessor :base
    attr_reader   :klass

    DEFAULTS = {
      :config_error_message => 'FriendlyId has no such config option "%s"',
      :reserved_words       => ["new", "edit"]
    }

    def initialize(klass, values = nil)
      @klass = klass
      set values
    end

    def method_missing(symbol, *args, &block)
      option = symbol.to_s.gsub(/=\z/, '')
      raise ArgumentError, DEFAULTS[:config_error_message] % option
    end

    def set(values)
      values and values.each {|name, value| self.send "#{name}=", value}
    end

    def query_field
      base
    end
  end
end
