module FriendlyId

  module FinderMethods
    
    # Finds a record using the given id.
    #
    # If the id is "unfriendly", it will call the original find method.
    # If the id is a numeric string like '123' it will first look for a friendly
    # id matching '123' and then fall back to looking for a record with the
    # numeric id '123'.
    #
    # Since FriendlyId 5.0, if the id is a numeric string like '123-foo' it
    # will *only* search by friendly id and not fall back to the regular find
    # method.
    #
    # If you want to search only by the friendly id, use {#find_by_friendly_id}.
    # @raise ActiveRecord::RecordNotFound
    def find(*args)
      id = args.first
      return super if args.count != 1 || id.unfriendly_id?
      first_by_friendly_id(id).tap {|result| return result unless result.nil?}
      return super if columns.find{|c| c.primary }.type != :integer || Integer(id, 10) rescue nil
      raise ActiveRecord::RecordNotFound
    end

    # Returns true if a record with the given id exists.
    def exists?(conditions = :none)
      return super unless conditions.friendly_id?
      exists_by_friendly_id?(conditions)
    end

    # Finds exclusively by the friendly id, completely bypassing original
    # `find`.
    # @raise ActiveRecord::RecordNotFound
    def find_by_friendly_id(id)
      first_by_friendly_id(id) or raise ActiveRecord::RecordNotFound
    end

    private

    def first_by_friendly_id(id)
      where(friendly_id_config.query_field => id).first
    end

    def exists_by_friendly_id?(id)
      where(friendly_id_config.query_field => id).exists?
    end

  end
end