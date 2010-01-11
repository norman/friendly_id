require File.join(File.dirname(__FILE__), "friendly_id", "slug_string")
require File.join(File.dirname(__FILE__), "friendly_id", "config")
require File.join(File.dirname(__FILE__), "friendly_id", "finder")
require File.join(File.dirname(__FILE__), "friendly_id", "status")
require File.join(File.dirname(__FILE__), "friendly_id", "adapters", "active_record", "simple_model")
require File.join(File.dirname(__FILE__), "friendly_id", "adapters", "active_record", "slugged_model")
require File.join(File.dirname(__FILE__), "friendly_id", "adapters", "active_record", "slug")

# FriendlyId is a comprehensive Ruby library for slugging and permalinks with
# ActiveRecord.
# @author Norman Clarke
# @author Emilio Tagua
# @author Adrian Mugnolo
module FriendlyId

  # This error is raised when it's not possible to generate a unique slug.
  class SlugGenerationError < StandardError ; end

  mattr_accessor :sequence_separator

  # Set up a model to use a friendly_id. This method accepts a hash with
  # {FriendlyId::Config several possible options}.
  #
  # @param [#to_sym] method The column or method that should be used as the
  #   basis of the friendly_id string.
  #
  # @param [Hash] options For valid configuration options, see
  #   {FriendlyId::Config}.
  #
  # @param [block] block An optional block through which to filter the
  #   friendly_id text; see {FriendlyId::Config#normalizer}. Note that
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
  #
  def has_friendly_id(method, options = {}, &block)
    class_inheritable_accessor :friendly_id_config
    write_inheritable_attribute :friendly_id_config, Config.new(self.class,
      method, options.merge(:normalizer => block))
    FriendlyId.sequence_separator ||= "--"
    load_adapters
  end

  private

  # Load either the SluggedModel or SimpleModel modules.
  # @TODO figure out best way to selectively load adapted modules
  def load_adapters
    if friendly_id_config.use_slug?
      include Adapters::ActiveRecord::SluggedModel
    else
      include Adapters::ActiveRecord::SimpleModel
    end
  end

end

# {FriendlyId#has_friendly_id has_friendly_id} is available to all subclasses of
# ActiveRecord::Base.
class ActiveRecord::Base
  extend FriendlyId
end

class String
  def parse_friendly_id(separator = nil)
    name, sequence = split(separator || FriendlyId.sequence_separator)
    return name, sequence ||= "1"
  end
end