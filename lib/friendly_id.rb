require "friendly_id/base"
require "friendly_id/model"
require "friendly_id/object_utils"
require "friendly_id/configuration"
require "friendly_id/finder_methods"

# FriendlyId is a comprehensive Ruby library for ActiveRecord permalinks and
# slugs.
#
# @author Norman Clarke
module FriendlyId
  autoload :Slugged,  "friendly_id/slugged"
  autoload :Scoped,   "friendly_id/scoped"
  autoload :History,  "friendly_id/history"

  # FriendlyId takes advantage of `extended` to do basic model setup, primarily
  # extending FriendlyId::Base to add #friendly_id as a class method for
  # configuring how a model is going to use FriendlyId. In previous versions of
  # this library, ActiveRecord::Base was patched by default to include methods
  # needed to configure friendly_id, but this version tries to be a little less
  # invasive.
  #
  # In addition to adding the #friendly_id method, the class instance variable
  # +@friendly_id_config+ is added. This variable is an instance of an anonymous
  # subclass of FriendlyId::Configuration. This is done to allow for
  # subsequently loaded modules like FriendlyId::Slugged to add functionality to
  # the configuration only for the current class, and thereby isolating other
  # classes from large feature changes a module could potentially introduce. The
  # upshot of this is, you can have two Active Record models that both have a
  # @friendly_id_config, but each config object can have different methods and
  # behaviors depending on what modules have been loaded, without conflicts.
  def self.extended(base)
    base.instance_eval do
      extend FriendlyId::Base
      @friendly_id_config = Class.new(FriendlyId::Configuration).new(base)
    end
    ActiveRecord::Relation.send :include, FriendlyId::FinderMethods
  end
end
