module FriendlyId

  # @abstract
  class Finder

    attr_accessor :ids
    attr_accessor :options
    attr_accessor :scope
    attr_accessor :model

    class << self

      # Is the id friendly or numeric? Not that the return value here is
      # +false+ if the +id+ is definitely not friendly, and +nil+ if it can
      # not be determined.
      # The return value will be:
      # * +true+ - if the id is definitely friendly (i.e., any string with non-numeric characters)
      # * +false+ - if the id is definitely unfriendly (i.e., an Integer, ActiveRecord::Base, etc.)
      # * +nil+ - if it can not be determined (i.e., a numeric string like "206".)
      # @return [true, false, nil]
      # @see #unfriendly?
      def friendly?(id)
        if id.is_a?(Integer) || id.kind_of?(ActiveRecord::Base)
          return false
        elsif id.to_i.to_s != id.to_s
          return true
        else
          return nil
        end
      end

      # Is the id friendly or numeric?
      # @return [true, false, nil] +true+ if definitely unfriendly, +false+ if
      #   definitely friendly, else +nil+.
      # @see #friendly?
      def unfriendly?(id)
        !friendly?(id) unless friendly?(id) == nil
      end
      
    end

    def initialize(ids, model, options={})
      self.ids = ids
      self.options = options
      self.model = model
      self.scope = options[:scope]
    end

    def method_missing(*args, &block)
      model.send(*args, &block)
    end

    def expected_size
      limited? ? limit : offset_size
    end

    def friendly?
      self.class.friendly?(id)
    end

    def id
      ids[0]
    end

    def ids=(ids)
      @ids = [ids].flatten
    end
    alias :id= :ids=

    def limit
      options[:limit]
    end

    def limited?
      offset_size > limit if limit
    end

    def name
      id.to_s.parse_friendly_id(friendly_id_config.sequence_separator)[0]
    end

    def offset
      options[:offset].to_i
    end

    def offset_size
      ids.size - offset
    end

    def scope=(scope)
      @scope = scope.to_param unless scope.nil?
    end

    def sequence
      id.to_s.parse_friendly_id(friendly_id_config.sequence_separator)[1]
    end

    def slugs_included?
      [*(options[:include] or [])].flatten.include?(:slugs)
    end

    def unfriendly?
      self.class.unfriendly?(id)
    end
    
  end

end