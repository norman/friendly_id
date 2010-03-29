module FriendlyId
  module ActiveRecordAdapter

    module SimpleModel

      # Some basic methods common to {MultipleFinder} and {SingleFinder}.
      module SimpleFinder

        # The column used to store the friendly_id.
        def column
          "#{table_name}.#{friendly_id_config.column}"
        end

        # The model's fully-qualified and quoted primary key.
        def primary_key
          "#{quoted_table_name}.#{model_class.send :primary_key}"
        end

      end

      class MultipleFinder

        include FriendlyId::ActiveRecordAdapter::Finders::Multiple
        include SimpleFinder

        def find
          @results = model_class.scoped(:conditions => conditions).scoped(options).all(options)
          raise(::ActiveRecord::RecordNotFound, error_message) if @results.size != expected_size
          friendly_results.each { |result| result.friendly_id_status.name = result.to_param }
          @results
        end

        private

        def conditions
          ["#{primary_key} IN (?) OR #{column} IN (?)", unfriendly_ids, friendly_ids]
        end

        def friendly_results
          results.select { |result| friendly_ids.include? result.to_param }
        end

      end

      class SingleFinder

        include FriendlyId::Finders::Base
        include FriendlyId::Finders::Single
        include SimpleFinder

        def find
          result = model_class.scoped(find_options).first(options)
          raise ::ActiveRecord::RecordNotFound.new if friendly? && !result
          result.friendly_id_status.name = id if result
          result
        end

        private

        def find_options
          @find_options ||= {:conditions => {column => id}}
        end

      end

      def self.included(base)
        base.class_eval do
          column = friendly_id_config.column
          validate :validate_friendly_id, :unless => :skip_friendly_id_validations
          validates_presence_of column, :unless => :skip_friendly_id_validations
          validates_length_of column, :maximum => friendly_id_config.max_length, :unless => :skip_friendly_id_validations
          after_update :update_scopes
          extend FriendlyId::ActiveRecordAdapter::FinderMethods
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