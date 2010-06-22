module FriendlyId

  module Finders

    module Base

      extend Forwardable

      def_delegators :model_class, :base_class, :friendly_id_config,
        :primary_key, :quoted_table_name, :sanitize_sql, :table_name

      def friendly?
        ids.length == 1 && id.friendly_id?
      end

      def unfriendly?
        ids.length == 1 && id.unfriendly_id?
      end

      def initialize(ids, model_class, options={})
        self.ids = ids
        self.options = options
        self.model_class = model_class
        self.scope = options.delete :scope
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
