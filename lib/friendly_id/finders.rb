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

### `has_many` and other associations

If you want to perform friendly finds on associations, you must extend the
FriendlyId::Finder methods module, or use the `friendly` scope:

    class Account < ActiveRecord::Base
      extend FriendlyId

      friendly_id :name, use: :slugged
      belongs_to :person
    end

    class Person < ActiveRecord::Base
      has_many :accounts
    end

    person.accounts.find 'bank-of-america'          # This will fail
    person.accounts.friendly.find 'bank-of-america' # OK

    class Person < ActiveRecord::Base
      has_many :accounts, extend: FriendlyId::FinderMethods
    end

    person.accounts.find 'bank-of-america'          # OK
    person.accounts.friendly.find 'bank-of-america' # OK


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
    def self.included(model_class)
      model_class.send(:relation).class.send(:include, FriendlyId::FinderMethods)

      if model_class.friendly_id_config.uses? :history
        model_class.send(:relation).class.send(:include, FriendlyId::History::HistoryFinderMethods)
      end
    end
  end
end