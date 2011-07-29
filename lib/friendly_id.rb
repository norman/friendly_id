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
  # extending {FriendlyId::Base} to add {FriendlyId::Base#friendly_id
  # friendly_id} as a class method.
  #
  # Previous versions of FriendlyId simply patched ActiveRecord::Base, but this
  # version tries to be less invasive.
  #
  # In addition to adding {FriendlyId::Base.friendly_id friendly_id}, the class
  # instance variable +@friendly_id_config+ is added. This variable is an
  # instance of an anonymous subclass of {FriendlyId::Configuration}. This
  # allows subsequently loaded modules like {FriendlyId::Slugged} and
  # {FriendlyId::Scoped} to add functionality to the configuration class only
  # for the current class, rather than monkey patching
  # {FriendlyId::Configuration} directly. This isolates other models from large
  # feature changes an addon to FriendlyId could potentially introduce.
  #
  # The upshot of this is, you can htwo Active Record models that both have a
  # @friendly_id_config, but each config object can have different methods and
  # behaviors depending on what modules have been loaded, without conflicts.
  # Keep this in mind if you're hacking on FriendlyId.
  #
  # For examples of this, see the source for {Scoped.included}.
  def self.extended(base)
    base.instance_eval do
      extend FriendlyId::Base
      @friendly_id_config = Class.new(FriendlyId::Configuration).new(base)
    end
    ActiveRecord::Relation.send :include, FriendlyId::FinderMethods
  end
end
