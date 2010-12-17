module FriendlyId

  # Are we running on ActiveRecord 3 or higher?
  def self.on_ar3?
    ActiveRecord::VERSION::STRING >= "3"
  end

  module ActiveRecordAdapter

    autoload :Relation,       "friendly_id/active_record_adapter/relation"
    autoload :Configuration,  "friendly_id/active_record_adapter/configuration"
    autoload :Finders,        "friendly_id/active_record_adapter/finders"
    autoload :SimpleModel,    "friendly_id/active_record_adapter/simple_model"
    autoload :SluggedModel,   "friendly_id/active_record_adapter/slugged_model"
    autoload :Tasks,          "friendly_id/active_record_adapter/tasks"

    include FriendlyId::Base

    def has_friendly_id(method, options = {})
      class_inheritable_accessor :friendly_id_config
      write_inheritable_attribute :friendly_id_config, Configuration.new(self, method, options)
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
      # only protect the column if the class is not already using attr_accessible
      unless accessible_attributes.present?
        if friendly_id_config.custom_cache_column?
          attr_protected friendly_id_config.cache_column
        end
        attr_protected :cached_slug
      end
    end

  end
end

require "friendly_id/active_record_adapter/slug"

module ActiveRecord
  class Base
    extend FriendlyId::ActiveRecordAdapter
    unless FriendlyId.on_ar3?
      class << self
        VALID_FIND_OPTIONS << :scope
      end
    end
  end

  if defined? Relation
    class Relation
      alias find_one_without_friendly  find_one
      alias find_some_without_friendly find_some
      include FriendlyId::ActiveRecordAdapter::Relation
    end
  end
end
