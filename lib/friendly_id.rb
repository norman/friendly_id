require "forwardable"
require "active_support/core_ext/class/attribute_accessors"
require "active_support/core_ext/object/blank"

require File.join(File.dirname(__FILE__), "friendly_id", "slug_string")
require File.join(File.dirname(__FILE__), "friendly_id", "configuration")
require File.join(File.dirname(__FILE__), "friendly_id", "status")
require File.join(File.dirname(__FILE__), "friendly_id", "finders")
require File.join(File.dirname(__FILE__), "friendly_id", "slugged")

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

  module Base
    # Set up a model to use a friendly_id. This method accepts a hash with
    # {FriendlyId::Configuration several possible options}.
    #
    # @param [#to_sym] method The column or method that should be used as the
    #   basis of the friendly_id string.
    #
    # @param [Hash] options For valid configuration options, see
    #   {FriendlyId::Configuration}.
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
    #
    # @see FriendlyId::Configuration
    def has_friendly_id(method, options = {})
      raise NotImplementedError
    end

    # Does the model class use the FriendlyId plugin?
    def uses_friendly_id?
      respond_to? :friendly_id_config
    end
  end

end

class String
  def parse_friendly_id(separator = nil)
    separator ||= FriendlyId::Configuration::DEFAULTS[:sequence_separator]
    name, sequence = split(/#{Regexp.escape(separator)}(\d+)?\z/)
    return name, sequence ||= "1"
  end
end

require File.join(File.dirname(__FILE__), "friendly_id", "railtie") if defined?(Rails) && Rails.version >= "3"