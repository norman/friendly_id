module FriendlyId
  module ActiveRecord2

    module SimpleModel

      module SimpleFinder

        def column
          "#{table_name}.#{friendly_id_config.method}"
        end

        def primary_key
          "#{quoted_table_name}.#{model.send :primary_key}"
        end

      end

      class MultipleFinder < Finders::MultipleFinder

        include SimpleFinder

        def conditions
          ["#{primary_key} IN (?) OR #{column} IN (?)", unfriendly_ids, friendly_ids]
        end

        def find
          @results = with_scope(:find => options) { find_every :conditions => conditions }
          raise(::ActiveRecord::RecordNotFound, error_message) if @results.size != expected_size
          friendly_results.each { |result| result.friendly_id_status.name = result.friendly_id }
          @results
        end

        private

        def friendly_results
          results.select { |result| friendly_ids.include? result.friendly_id.to_s }
        end

      end

      class SingleFinder < Finders::SingleFinder

        include SimpleFinder

        def find
          result = with_scope(:find => find_options) { find_initial options }
          raise ::ActiveRecord::RecordNotFound.new if !result
          result.friendly_id_status.name = id
          result
        end

        def find_options
          {:conditions => {column => id}}
        end

      end

      module ClassMethods
        def find_one(id, options)
          finder = SingleFinder.new(id, self, options)
          finder.unfriendly? ? super : finder.find
        end

        def find_some(ids_and_names, options)
          MultipleFinder.new(ids_and_names, self, options).find
        end
        protected :find_one, :find_some
      end

      def self.included(base)
        base.validate :validate_friendly_id
        base.after_update :update_scopes
        base.extend ClassMethods
      end

      def friendly_id_status
        @friendly_id_status ||= Status.new :record => self
      end

      # Was the record found using one of its friendly ids?
      def found_using_friendly_id?
        friendly_id_status.friendly?
      end

      # Was the record found using its numeric id?
      def found_using_numeric_id?
        friendly_id_status.numeric?
      end
      alias has_better_id? found_using_numeric_id?

      # Returns the friendly_id.
      def friendly_id
        send friendly_id_config.method
      end
      alias best_id friendly_id

      # Returns the friendly id, or if none is available, the numeric id.
      def to_param
        (friendly_id || id).to_s
      end

      private

      def friendly_id_changes
        changes[friendly_id_config.method.to_s]
      end

      def update_scopes
        if changes = friendly_id_changes
          friendly_id_config.child_scopes.each do |klass|
            Slug.update_all "scope = '#{changes[1]}'", ["sluggable_type = ? AND scope = ?", klass.to_s, changes[0]]
          end
        end
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