# encoding: utf-8
module FriendlyId

  class SlugString < Babosa::SlugString
    # Normalize the string for a given {FriendlyId::Configuration}.
    # @param config [FriendlyId::Configuration]
    # @return String
    def normalize_for!(config)
      approximate_ascii!(config.ascii_approximation_options) if config.approximate_ascii?
      to_ascii! if config.strip_non_ascii?
      normalize!
    end

    # Validate that the slug string is not blank or reserved, and truncate
    # it to the max length if necessary.
    # @param config [FriendlyId::Configuration]
    # @return String
    # @raise FriendlyId::BlankError
    # @raise FriendlyId::ReservedError
    def validate_for!(config)
      truncate!(config.max_length)
      raise FriendlyId::BlankError if blank?
      raise FriendlyId::ReservedError if config.reserved?(self)
      self
    end
  end
end
