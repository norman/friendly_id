# FriendlyId's ORM-agnostic core.
#
# Nothing required from here may depend on Active Record, Active Support, ROM or
# any other persistence library. Adapters build on top of this; see
# `friendly_id/active_record` and `friendly_id/rom`.
#
# The one contract an adapter must satisfy is the slug scope protocol: whatever
# object is handed to {FriendlyId::SlugGenerator} must respond to
# `exists_by_friendly_id?(slug)`.

require "friendly_id/core/errors"
require "friendly_id/core/object_utils"
require "friendly_id/core/configuration"
require "friendly_id/core/candidates"
require "friendly_id/core/slug_generator"
require "friendly_id/core/normalizers"
require "friendly_id/core/sequence_calculator"

module FriendlyId
  # Set global defaults for all models using FriendlyId.
  #
  # The default defaults are to use the `:reserved` module and nothing else.
  #
  # @example
  #   FriendlyId.defaults do |config|
  #     config.base :name
  #     config.use :slugged
  #   end
  def self.defaults(&block)
    @defaults = block if block
    @defaults ||= ->(config) { config.use :reserved }
  end
end
