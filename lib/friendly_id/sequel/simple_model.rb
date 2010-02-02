module FriendlyId
  module Sequel

    module SimpleModel

      class SingleFinder

        include FriendlyId::Finders::Base
        include FriendlyId::Finders::Single

        def find
          with_sql(query).first if friendly?
        end

        private

        def query
          table = simple_table
          column = friendly_id_config.column
          "SELECT * FROM #{table} WHERE #{column} = #{dataset.literal(id)}"
        end

      end

      def self.included(base)
        def base.primary_key_lookup(pk)
          SingleFinder.new(pk, self).find or super
        end
      end

      # Get the {FriendlyId::Status} after the find has been performed.
      def friendly_id_status
        @friendly_id_status ||= Status.new :record => self
      end

      # Returns the friendly_id.
      def friendly_id
        send self.class.friendly_id_config.column
      end

      # Returns the friendly id, or if none is available, the numeric id.
      def to_param
        (friendly_id || id).to_s
      end

      def validate
        column = friendly_id_config.column
        value = send(column)
        return errors.add(column, "can't be blank") if value.blank?
        return errors.add(column, "is reserved") if friendly_id_config.reserved?(value)
      end

      private

      def friendly_id_config
        self.class.friendly_id_config
      end

    end
  end
end