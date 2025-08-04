require "set"

module FriendlyId
  module FinderMethods
    # Finds a record using the given id.
    #
    # If the id is "unfriendly", it will call the original find method.
    # If the id is a numeric string like '123' it will first look for a friendly
    # id matching '123' and then fall back to looking for a record with the
    # numeric id '123'.
    #
    # @param [Boolean] allow_nil (default: false)
    # Use allow_nil: true if you'd like the finder to return nil instead of
    # raising ActivRecord::RecordNotFound
    #
    # ### Example
    #
    #     MyModel.friendly.find("bad-slug")
    #     #=> raise ActiveRecord::RecordNotFound
    #
    #     MyModel.friendly.find("bad-slug", allow_nil: true)
    #     #=> nil
    #
    # Since FriendlyId 5.0, if the id is a nonnumeric string like '123-foo' it
    # will *only* search by friendly id and not fall back to the regular find
    # method.
    #
    # If you want to search only by the friendly id, use {#find_by_friendly_id}.
    # @raise ActiveRecord::RecordNotFound
    def find(*args, allow_nil: false)
      id = args.first
      
      # Handle array of IDs (potentially including slugs)
      if args.count == 1 && id.is_a?(Array)
        return find_by_array(id, allow_nil: allow_nil)
      end
      
      return super(*args) if args.count != 1 || id.unfriendly_id?
      first_by_friendly_id(id).tap { |result| return result unless result.nil? }
      return super(*args) if potential_primary_key?(id)

      raise_not_found_exception(id) unless allow_nil
    rescue ActiveRecord::RecordNotFound => exception
      raise exception unless allow_nil
    end

    # Returns true if a record with the given id exists.
    def exists?(conditions = :none)
      return super if conditions.unfriendly_id?
      return true if exists_by_friendly_id?(conditions)
      super
    end

    # Finds exclusively by the friendly id, completely bypassing original
    # `find`.
    # @raise ActiveRecord::RecordNotFound
    def find_by_friendly_id(id)
      first_by_friendly_id(id) or raise_not_found_exception(id)
    end

    # Finds records by an array of IDs, which may include friendly IDs (slugs)
    # and/or numeric primary keys.
    # @raise ActiveRecord::RecordNotFound
    def find_by_array(ids, allow_nil: false)
      return [] if ids.empty?
      
      # Separate potential slugs from numeric IDs
      slugs = []
      numeric_ids = []
      
      ids.each do |id|
        if id.unfriendly_id? || potential_primary_key?(id)
          numeric_ids << id
        else
          slugs << id
        end
      end
      
      # Find records by slugs
      records_by_slugs = []
      if slugs.any?
        # Parse slugs and find by friendly_id field
        parsed_slugs = slugs.map { |slug| parse_friendly_id(slug) }
        records_by_slugs = where(friendly_id_config.query_field => parsed_slugs).to_a
      end
      
      # Find records by numeric IDs using original ActiveRecord find
      records_by_ids = []
      if numeric_ids.any?
        begin
          # Use where with primary key to find by numeric IDs, which avoids
          # calling the overridden find method and works like the original
          primary_key_name = self.primary_key
          records_by_ids = where(primary_key_name => numeric_ids).to_a
          
          # Check if we found all requested numeric IDs
          found_ids = records_by_ids.map(&:id)
          missing_ids = numeric_ids - found_ids
          if missing_ids.any? && !allow_nil
            # Use the same error format as ActiveRecord for missing IDs
            if ActiveRecord.version < Gem::Version.create("5.0")
              raise ActiveRecord::RecordNotFound.new("Couldn't find #{self.name} with 'id'=#{missing_ids.first}")
            else
              raise ActiveRecord::RecordNotFound.new("Couldn't find #{self.name} with 'id'=#{missing_ids.first}", self.name, :id, missing_ids.first)
            end
          end
        rescue ActiveRecord::RecordNotFound => e
          # If allow_nil is true, we continue and return partial results
          # If allow_nil is false, we re-raise the exception
          raise e unless allow_nil
        end
      end
      
      # Combine results
      all_records = records_by_slugs + Array(records_by_ids)
      
      # Check if we found all requested slugs (numeric IDs are already checked above)
      unless allow_nil
        if slugs.any?
          found_slugs = Set.new(records_by_slugs.map { |record| record.send(friendly_id_config.query_field) })
          parsed_slugs = slugs.map { |slug| parse_friendly_id(slug) }
          missing_slugs = parsed_slugs - found_slugs.to_a
          
          if missing_slugs.any?
            # Find the original slug that corresponds to the missing parsed slug
            original_missing_slug = slugs.find { |slug| parse_friendly_id(slug) == missing_slugs.first }
            raise_not_found_exception(original_missing_slug)
          end
        end
      end
      
      all_records
    end

    def exists_by_friendly_id?(id)
      where(friendly_id_config.query_field => parse_friendly_id(id)).exists?
    end

    private

    def potential_primary_key?(id)
      key_type = primary_key_type
      # Hook for "ActiveModel::Type::Integer" instance.
      key_type = key_type.type if key_type.respond_to?(:type)
      case key_type
      when :integer
        begin
          Integer(id, 10)
        rescue
          false
        end
      when :uuid
        id.match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
      else
        true
      end
    end

    def first_by_friendly_id(id)
      find_by(friendly_id_config.query_field => parse_friendly_id(id))
    end

    # Parse the given value to make it suitable for use as a slug according to
    # your application's rules.
    #
    # This method is not intended to be invoked directly; FriendlyId uses it
    # internally to process a slug into string to use as a finder.
    #
    # However, if FriendlyId's default slug parsing doesn't suit your needs,
    # you can override this method in your model class to control exactly how
    # slugs are generated.
    #
    # ### Example
    #
    #     class Person < ActiveRecord::Base
    #       extend FriendlyId
    #       friendly_id :name_and_location
    #
    #       def name_and_location
    #         "#{name} from #{location}"
    #       end
    #
    #       # Use default slug, but lower case
    #       # If `id` is "Jane-Doe" or "JANE-DOE", this finds data by "jane-doe"
    #       def parse_friendly_id(slug)
    #         super.downcase
    #       end
    #     end
    #
    # @param [#to_s] value The slug to be parsed.
    # @return The parsed slug, which is not modified by default.
    def parse_friendly_id(value)
      value
    end

    def raise_not_found_exception(id)
      message = "can't find record with friendly id: #{id.inspect}"
      if ActiveRecord.version < Gem::Version.create("5.0")
        raise ActiveRecord::RecordNotFound.new(message)
      else
        raise ActiveRecord::RecordNotFound.new(message, name, friendly_id_config.query_field, id)
      end
    end
  end
end
