# encoding: utf-8
module FriendlyId

  class SlugString < Babosa::Identifier
    # Normalize the string for a given {FriendlyId::Configuration}.
    # @param config [FriendlyId::Configuration]
    # @return String
    def normalize_for!(config)
      normalize!(config.babosa_options)
    end

    # Validate that the slug string is not blank or reserved, and truncate
    # it to the max length if necessary.
    # @param config [FriendlyId::Configuration]
    # @return String
    # @raise FriendlyId::BlankError
    # @raise FriendlyId::ReservedError
    def validate_for!(config)
      truncate_bytes!(config.max_length)
      raise FriendlyId::BlankError if blank?
      raise FriendlyId::ReservedError if config.reserved?(self)
      self
    end
  end
end
