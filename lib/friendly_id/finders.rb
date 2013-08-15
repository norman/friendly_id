module FriendlyId
=begin
## Performing Finds with FriendlyId

FriendlyId offers enhanced finders which will search for your record by
friendly id, and fall back to the numeric id if necessary. This makes it easy
to add FriendlyId to an existing application with minimal code modification.

By default, these methods are available only on the `friendly` scope:

    Restaurant.friendly.find('plaza-diner') #=> works
    Restaurant.friendly.find(23)            #=> also works
    Restaurant.find(23)                     #=> still works
    Restaurant.find('plaza-diner')          #=> will not work

### Restoring FriendlyId 4.0-style finders

Prior to version 5.0, FriendlyId overrode the default finder methods to perform
friendly finds all the time. This required modifying parts of Rails that did
not have a public API, which was harder to maintain and at times caused
compatiblity problems. In 5.0 we decided change the library's defaults and add
the friendly finder methods only to the `friendly` scope in order to boost
compatiblity. However, you can still opt-in to original functionality very
easily by using the `:finders` addon:

    class Restaurant < ActiveRecord::Base
      extend FriendlyId

      scope :active, -> {where(:active => true)}

      friendly_id :name, :use => [:slugged, :finders]
    end

    Restaurant.friendly.find('plaza-diner') #=> works
    Restaurant.find('plaza-diner')          #=> now also works
    Restaurant.active.find('plaza-diner')   #=> now also works

### Updating your application to use FriendlyId's finders

Unless you've chosen to use the `:finders` addon, be sure to modify the finders
in your controllers to use the `friendly` scope. For example:

    # before
    def set_restaurant
      @restaurant = Restaurant.find(params[:id])
    end

    # after
    def set_restaurant
      @restaurant = Restaurant.friendly.find(params[:id])
    end
=end
  module Finders
    def self.included(base_class)
      base_class.send(:relation).class.send(:include, FriendlyId::FinderMethods)
    end
  end
end