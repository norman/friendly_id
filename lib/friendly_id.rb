require "active_record"
require "active_record/version"
require File.join(File.dirname(__FILE__), "friendly_id", "slug_string")
require File.join(File.dirname(__FILE__), "friendly_id", "configuration")
require File.join(File.dirname(__FILE__), "friendly_id", "status")

# FriendlyId is a comprehensive Ruby library for slugging and permalinks with
# ActiveRecord.
# @author Norman Clarke
# @author Emilio Tagua
# @author Adrian Mugnolo
module FriendlyId

  # An error based on this class is raised when slug generation fails
  class SlugGenerationError < StandardError ; end

  # Raised when the slug text is blank.
  class BlankError < SlugGenerationError ; end

  # Raised when the slug text is reserved.
  class ReservedError < SlugGenerationError ; end

  # Set up a model to use a friendly_id. This method accepts a hash with
  # {FriendlyId::Configuration several possible options}.
  #
  # @param [#to_sym] method The column or method that should be used as the
  #   basis of the friendly_id string.
  #
  # @param [Hash] options For valid configuration options, see
  #   {FriendlyId::Configuration}.
  #
  # @param [block] block An optional block through which to filter the
  #   friendly_id text; see {FriendlyId::Configuration#normalizer}. Note that
  #   passing a block parameter is now deprecated and will be removed
  #   from FriendlyId 3.0.
  #
  # @example
  #
  #   class User < ActiveRecord::Base
  #     has_friendly_id :user_name
  #   end
  #
  #   class Post < ActiveRecord::Base
  #     has_friendly_id :title, :use_slug => true, :approximate_ascii => true
  #   end
  # @see FriendlyId::Configuration
  def has_friendly_id(method, options = {}, &block)
    class_inheritable_accessor :friendly_id_config
    write_inheritable_attribute :friendly_id_config, Configuration.new(self,
      method, options.merge(:normalizer => block))
    load_friendly_id_adapter
  end

  # Does the model class use the FriendlyId plugin?
  def uses_friendly_id?
    respond_to? :friendly_id_config
  end

  private

  # Implement this method to load the modules needed by the adapter.
  def load_friendly_id_adapter
    raise NotImplementedError
  end

end

module ActiveRecord

  module Friendly

    include FriendlyId

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

    # Loads either the slugged or non-slugged modules.
    def load_friendly_id_adapter

      validate_ar_version

      %w[finders simple_model slugged_model slug].each do |file|
        require File.join(File.dirname(__FILE__), "friendly_id", "active_record_2", file)
      end

      if friendly_id_config.use_slug?
        include ActiveRecord2::SluggedModel
      else
        include ActiveRecord2::SimpleModel
      end

    end

    private

    def validate_ar_version

      if ActiveRecord::VERSION::MAJOR > 2
        raise "FriendlyId is not yet compatible with ActiveRecord > 2"
      end

      if ActiveRecord::VERSION::MAJOR == 2 && ActiveRecord::VERSION::MINOR < 2
        raise "FriendlyId is not compatible with ActiveRecord < 2.2.3"
      end
    end

  end

  class Base
    extend Friendly
  end

end

class String
  def parse_friendly_id(separator = nil)
    name, sequence = split(separator || FriendlyId::Configuration::DEFAULTS[:sequence_separator])
    return name, sequence ||= "1"
  end
end