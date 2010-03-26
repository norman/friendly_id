module FriendlyId

  module Finders

    module Base

      # Is the id friendly or numeric? Not that the return value here is
      # +false+ if the +id+ is definitely not friendly, and +nil+ if it can
      # not be determined.
      # The return value will be:
      # * +true+ - if the id is definitely friendly (i.e., any string with non-numeric characters)
      # * +false+ - if the id is definitely unfriendly (i.e., an Integer, a model instance, etc.)
      # * +nil+ - if it can not be determined (i.e., a numeric string like "206".)
      # @return [true, false, nil]
      # @see #unfriendly?
      def self.friendly?(id)
        if id.is_a?(Integer) or id.is_a?(Symbol) or id.class.respond_to? :friendly_id_config
          return false
        elsif id.to_i.to_s != id.to_s
          return true
        else
          return nil
        end
      end

      # Is the id numeric?
      # @return [true, false, nil] +true+ if definitely unfriendly, +false+ if
      #   definitely friendly, else +nil+.
      # @see #friendly?
      def self.unfriendly?(id)
        !friendly?(id) unless friendly?(id) == nil
      end

      def initialize(ids, model_class, options={})
        self.ids = ids
        self.options = options
        self.model_class = model_class
        self.scope = options.delete :scope
      end

      def method_missing(*args, &block)
        model_class.send(*args, &block)
      end

      # An array of ids; can be both friendly and unfriendly.
      attr_accessor :ids

      # The ActiveRecord query options
      attr_accessor :options

      # The FriendlyId scope
      attr_accessor :scope

      # The model class being used to perform the query.
      attr_accessor :model_class

      # Perform the find.
      def find
        raise NotImplementedError
      end

      private

      def ids=(ids)
        @ids = [ids].flatten
      end
      alias :id= :ids=

      def scope=(scope)
        unless scope.nil?
          @scope = scope.respond_to?(:to_param) ? scope.to_param : scope.to_s
        end
      end
    end

    module Single
      # Is the id definitely friendly?
      # @see Finder::friendly?
      def friendly?
        Base.friendly?(id)
      end

      # Is the id definitely unfriendly?
      # @see Finder::unfriendly?
      def unfriendly?
        Base.unfriendly?(id)
      end

      private

      # The id (numeric or friendly).
      def id
        ids[0]
      end

      # The slug name; i.e. if "my-title--2", then "my-title".
      def name
        id.to_s.parse_friendly_id(friendly_id_config.sequence_separator)[0]
      end

      # The slug sequence; i.e. if "my-title--2", then "2".
      def sequence
        id.to_s.parse_friendly_id(friendly_id_config.sequence_separator)[1]
      end
    end

  end
end