require "forwardable"
require File.join(File.dirname(__FILE__), "active_record2", "configuration")
require File.join(File.dirname(__FILE__), "active_record2", "finders")
require File.join(File.dirname(__FILE__), "active_record2", "simple_model")
require File.join(File.dirname(__FILE__), "active_record2", "slugged_model")
require File.join(File.dirname(__FILE__), "active_record2", "slug")
require File.join(File.dirname(__FILE__), "active_record2", "tasks")

module FriendlyId

  module ActiveRecord2

    include FriendlyId::Base

    def has_friendly_id(method, options = {}, &block)
      class_inheritable_accessor :friendly_id_config
      write_inheritable_attribute :friendly_id_config, Configuration.new(self,
        method, options.merge(:normalizer => block))
      if friendly_id_config.use_slug?
        include SluggedModel
      else 
        include SimpleModel
      end
    end

    private

    # Prevent the cached_slug column from being accidentally or maliciously
    # overwritten. Note that +attr_protected+ is used to protect the cached_slug
    # column, unless you have already invoked +attr_accessible+. So if you
    # wish to use +attr_accessible+, you must invoke it BEFORE you invoke
    # {#has_friendly_id} in your class.
    def protect_friendly_id_attributes
      # only protect the column if the class is not already using attributes_accessible
      if !accessible_attributes
        if friendly_id_config.custom_cache_column?
          attr_protected friendly_id_config.cache_column
        end
        attr_protected :cached_slug
      end
    end

  end
end

class ActiveRecord::Base
  extend FriendlyId::ActiveRecord2
end