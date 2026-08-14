require "active_record"
require "friendly_id/core"
require "friendly_id/base"
require "friendly_id/finder_methods"

module FriendlyId
  autoload :History, "friendly_id/history"
  autoload :Slug, "friendly_id/slug"
  autoload :SimpleI18n, "friendly_id/simple_i18n"
  autoload :Reserved, "friendly_id/reserved"
  autoload :Scoped, "friendly_id/scoped"
  autoload :Slugged, "friendly_id/slugged"
  autoload :Finders, "friendly_id/finders"
  autoload :SequentiallySlugged, "friendly_id/sequentially_slugged"

  # FriendlyId takes advantage of `extended` to do basic model setup, primarily
  # extending {FriendlyId::Base} to add {FriendlyId::Base#friendly_id
  # friendly_id} as a class method.
  #
  # Previous versions of FriendlyId simply patched ActiveRecord::Base, but this
  # version tries to be less invasive.
  #
  # In addition to adding {FriendlyId::Base#friendly_id friendly_id}, the class
  # instance variable +@friendly_id_config+ is added. This variable is an
  # instance of an anonymous subclass of {FriendlyId::Configuration}. This
  # allows subsequently loaded modules like {FriendlyId::Slugged} and
  # {FriendlyId::Scoped} to add functionality to the configuration class only
  # for the current class, rather than monkey patching
  # {FriendlyId::Configuration} directly. This isolates other models from large
  # feature changes an addon to FriendlyId could potentially introduce.
  #
  # The upshot of this is, you can have two Active Record models that both have
  # a @friendly_id_config, but each config object can have different methods
  # and behaviors depending on what modules have been loaded, without
  # conflicts.  Keep this in mind if you're hacking on FriendlyId.
  #
  # For examples of this, see the source for {Scoped.included}.
  def self.extended(model_class)
    return if model_class.respond_to? :friendly_id
    class << model_class
      alias_method :relation_without_friendly_id, :relation
    end
    model_class.class_eval do
      extend Base
      @friendly_id_config = Class.new(Configuration).new(self)
      FriendlyId.defaults.call @friendly_id_config
      include Model
    end
  end

  # Allow developers to `include` FriendlyId or `extend` it.
  def self.included(model_class)
    model_class.extend self
  end

  # Set the ActiveRecord table name prefix to friendly_id_
  #
  # This makes 'slugs' into 'friendly_id_slugs' and also respects any
  # 'global' table_name_prefix set on ActiveRecord::Base.
  def self.table_name_prefix
    "#{ActiveRecord::Base.table_name_prefix}friendly_id_"
  end
end

# `Object#friendly_id?` and `Object#unfriendly_id?` are deprecated in favour of
# `FriendlyId.friendly_id?(value)`, which FriendlyId itself uses throughout.
# The patch is installed here rather than in core so that applications on other
# persistence libraries do not pay for a monkey patch only Rails ever wanted, and
# so that Rails applications relying on it keep working until 7.0 removes it.
Object.send :include, FriendlyId::ObjectUtils

# Considered unfriendly if object is an instance of an unfriendly class or one of
# its descendants. Only the patch above needs this; `FriendlyId.friendly_id?`
# checks UNFRIENDLY_CLASSES itself.
FriendlyId::UNFRIENDLY_CLASSES.each { |klass| FriendlyId.mark_as_unfriendly(klass) }

# Objects that are instances of Active Record models are never friendly ids.
ActiveSupport.on_load(:active_record) do
  FriendlyId.mark_as_unfriendly(ActiveRecord::Base)
end
