module FriendlyId

=begin
## Performing Finds with FriendlyId

FriendlyId offers enhanced finders which will search for your record by
friendly id, and fall back to the numeric id if necessary. This makes it easy
to add FriendlyId to an existing application with minimal code modification.

To search by friendly id, use the `friendly` scope:

    Restaurant.friendly.find('plaza-diner') #=> works
    Restaurant.friendly.find(23)            #=> also works
    Restaurant.find(23)                     #=> still works
    Restaurant.find('plaza-diner')          #=> will not work

When implementing FriendlyId in an application, be sure to modify the finders
in your controllers to use the `friendly` scope. For example:

    # before
    def set_restaurant
      @restaurant = Restaurant.find(params[:id])
    end

    # after
    def set_restaurant
      @restaurant = Restaurant.friendly.find(params[:id])
    end

### Restoring FriendlyId 4.0-style finders

Prior to version 5.0, FriendlyId overrode the default finder methods to perform
friendly finds all the time. This required modifying parts of Rails that did
not have a public API, which was hard to maintain and at times caused
compatiblity problems. In 5.0 we decided to add the friendly finders only to
the `friendly` scope. However, you can still restore some of the original
functionality if you wish.

Extending the {FriendlyId::Finders} module in an Active Record model will allow
you to perform friendly finds at the root level, similar to previous versions
of FriendlyId:

    class Restaurant < ActiveRecord::Base
      extend FriendlyId
      extend FriendlyId::Finders

      scope :active, -> {where(:active => true)}

      friendly_id :name, :use => :slugged
    end

    Restaurant.friendly.find('plaza-diner') #=> works
    Restaurant.find('plaza-diner')          #=> now also works

Note however, that since we're only extending the model and not its
relation class, this will not let you perform `find` on scopes; only
at the root:

    Restaurant.active.find('plaza-diner')            #=> does not work
    Restaurant.active.friendly.find('plaza-diner')   #=> works

If you want to be able to perform friendly finds on any scope produced by a
model, you can include the FriendlyId::Finders module in the model's relation
class:

    class Restaurant < ActiveRecord::Base
      extend FriendlyId
      relation.class.send(:include, FriendlyId::Finders)

      scope :active, -> {where(:active => true)}

      friendly_id :name, :use => :slugged
    end

    Restaurant.find('plaza-diner')         #=> works
    Restaurant.active.find('plaza-diner')  #=> also works

Note that doing this is a bit of a hack and although it should work for most
applications, it is not recommended.

=end
  module Finders

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
      return super if Integer(id, 10) rescue nil
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