module FriendlyId
  module ActiveRecordAdapter

    module SimpleModel

      def self.included(base)
        base.class_eval do
          column = friendly_id_config.column
          validate :validate_friendly_id, :unless => :skip_friendly_id_validations
          validates_presence_of column, :unless => :skip_friendly_id_validations
          validates_length_of column, :maximum => friendly_id_config.max_length, :unless => :skip_friendly_id_validations
          after_update :update_scopes
        end
      end

      # Get the {FriendlyId::Status} after the find has been performed.
      def friendly_id_status
        @friendly_id_status ||= Status.new :record => self
      end

      # Returns the friendly_id.
      def friendly_id
        send friendly_id_config.column
      end
      alias best_id friendly_id

      # Returns the friendly id, or if none is available, the numeric id.
      def to_param
        (friendly_id || id).to_s
      end

      private

      # The old and new values for the friendly_id column.
      def friendly_id_changes
        changes[friendly_id_config.column.to_s]
      end

      # Update the slugs for any model that is using this model as its
      # FriendlyId scope.
      def update_scopes
        if changes = friendly_id_changes
          friendly_id_config.child_scopes.each do |klass|
            Slug.update_all "scope = '#{changes[1]}'", ["sluggable_type = ? AND scope = ?", klass.to_s, changes[0]]
          end
        end
      end

      def skip_friendly_id_validations
        friendly_id.nil? && friendly_id_config.allow_nil?
      end

      def validate_friendly_id
        if result = friendly_id_config.reserved_error_message(friendly_id)
          self.errors.add(*result)
          return false
        end
      end

    end
  end
end
