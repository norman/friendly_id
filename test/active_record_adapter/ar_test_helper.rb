require File.expand_path('../../test_helper', __FILE__)

require "active_record"
require "active_support"

require File.expand_path("../../../lib/friendly_id/active_record", __FILE__)
require File.expand_path("../../../generators/friendly_id/templates/create_slugs", __FILE__)
require File.expand_path("../support/models", __FILE__)
require File.expand_path('../core', __FILE__)
require File.expand_path('../slugged', __FILE__)

local_db_settings   = File.expand_path("../support/database.yml", __FILE__)
default_db_settings = File.expand_path("../support/database.sqlite3.yml", __FILE__)

db_settings = File.exists?(local_db_settings) ? local_db_settings : default_db_settings
ActiveRecord::Base.establish_connection(YAML::load(File.open(db_settings)))

class ActiveRecord::Base
  def log_protected_attribute_removal(*args) end
end

ActiveRecord::Base.connection.tables.each do |table|
  ActiveRecord::Base.connection.drop_table(table)
end
ActiveRecord::Migration.verbose = false
CreateSlugs.up
CreateSupportModels.up

# A model that uses the automagically configured "cached_slug" column
class District < ActiveRecord::Base
  has_friendly_id :name, :use_slug => true
end

# A model that specifies a custom cached slug column
class City < ActiveRecord::Base
  has_friendly_id :name, :use_slug => true, :cache_column => "my_slug"
end

# A model with a custom slug text normalizer
class Person < ActiveRecord::Base
  has_friendly_id :name, :use_slug => true

  def normalize_friendly_id(string)
    string.upcase
  end

end

# A slugged model that uses a scope
class Resident < ActiveRecord::Base
  belongs_to :country
  has_friendly_id :name, :use_slug => true, :scope => :country
end

# A slugged model used as a scope
class Country < ActiveRecord::Base
  has_many :people
  has_many :residents
  has_friendly_id :name, :use_slug => true
end

# A model that doesn"t use slugs
class User < ActiveRecord::Base
  has_friendly_id :name
  has_many :houses
end

# Another model that doesn"t use slugs
class Author < ActiveRecord::Base
  has_friendly_id :name
end


# A model that uses a non-slugged model for its scope
class House < ActiveRecord::Base
  belongs_to :user
  has_friendly_id :name, :use_slug => true, :scope => :user
end

# A model that uses default slug settings and has a named scope
class Post < ActiveRecord::Base
  has_friendly_id :name, :use_slug => true
  send FriendlyId::ActiveRecordAdapter::Compat.scope_method, :published, :conditions => { :published => true }
end

# Model that uses a custom table name
class Place < ActiveRecord::Base
  self.table_name = "legacy_table"
  has_friendly_id :name, :use_slug => true
end

# A model that uses a datetime field for its friendly_id
class Event < ActiveRecord::Base
  has_friendly_id :event_date, :use_slug => true
end

# A base model for single table inheritence
class Book < ActiveRecord::Base ; end

# A model that uses STI
class Novel < ::Book
  has_friendly_id :name, :use_slug => true
end

# A model with no table
class Question < ActiveRecord::Base
  has_friendly_id :name, :use_slug => true
end