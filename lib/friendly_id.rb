# encoding: utf-8
require "thread"
require "friendly_id/base"
require "friendly_id/model"
require "friendly_id/object_utils"
require "friendly_id/configuration"
require "friendly_id/finder_methods"

=begin

== About FriendlyId

FriendlyId is an add-on to Ruby's Active Record that allows you to replace ids
in your URLs with strings:

    # without FriendlyId
    http://example.com/states/4323454

    # with FriendlyId
    http://example.com/states/washington

It requires few changes to your application code and offers flexibility,
performance and a well-documented codebase.

=== Concepts

Although FriendlyId helps with URLs, it does all of its work inside your models,
not your routes.

=== Simple Models

The simplest way to use FriendlyId is with a model that has a uniquely indexed
column with no spaces or special characters, and that is seldom or never
updated. The most common example of this is a user name:

    class User < ActiveRecord::Base
      extend FriendlyId
      friendly_id :login
      validates_format_of :login, :with => /\A[a-z0-9]+\z/i
    end

    @user = User.find "joe"   # the old User.find(1) still works, too
    @user.to_param            # returns "joe"
    redirect_to @user         # the URL will be /users/joe

In this case, FriendlyId assumes you want to use the column as-is; it will never
modify the value of the column, and your application should ensure that the
value is admissible in a URL:

    class City < ActiveRecord::Base
      extend FriendlyId
      friendly_id :name
    end

    @city.find "Viña del Mar"
    redirect_to @city # the URL will be /cities/Viña%20del%20Mar

For this reason, it is often more convenient to use "slugs" rather than a single
column.

=== Slugged Models

FriendlyId can uses a separate column to store slugs for models which require
some processing of the friendly_id text. The most common example is a blog
post's title, which may have spaces, uppercase characters, or other attributes
you wish to modify to make them more suitable for use in URL's.

    class Post < ActiveRecord::Base
      extend FriendlyId
      friendly_id :title, :use => :slugged
    end

    @post = Post.create(:title => "This is the first post!")
    @post.friendly_id   # returns "this-is-the-first-post"
    redirect_to @post   # the URL will be /posts/this-is-the-first-post

In general, use slugs by default unless you know for sure you don't need them.

@author Norman Clarke
=end
module FriendlyId

  # The current version.
  VERSION = "4.0.0.beta14"

  @mutex = Mutex.new

  autoload :History,  "friendly_id/history"
  autoload :I18n,     "friendly_id/i18n"
  autoload :Reserved, "friendly_id/reserved"
  autoload :Scoped,   "friendly_id/scoped"
  autoload :Slugged,  "friendly_id/slugged"

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
      alias relation_without_friendly_id relation
    end
    model_class.instance_eval do
      extend Base
      @friendly_id_config = Class.new(Configuration).new(self)
      FriendlyId.defaults.call @friendly_id_config
    end
  end

  # Set global defaults for all models using FriendlyId.
  #
  # The default defaults are to use the +:reserved+ module and nothing else.
  #
  # @example
  #   FriendlyId.defaults do |config|
  #     config.base = :name
  #     config.use :slugged
  #   end
  def self.defaults(&block)
    @mutex.synchronize do
      @defaults = block if block_given?
      @defaults ||= lambda {|config| config.use :reserved}
    end
  end
end
