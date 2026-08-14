module FriendlyId
  # Base class for every error FriendlyId raises deliberately.
  #
  # Descends from StandardError so that `rescue => e` catches it. Note in
  # particular that NotImplementedError would *not* be caught that way, since it
  # descends from ScriptError.
  class Error < StandardError; end

  # Raised when a model or relation asks for an addon the current adapter does
  # not provide, e.g. `:history` on the ROM adapter.
  class UnsupportedAddonError < Error; end

  # Raised when an addon name does not correspond to any known addon.
  class UnknownAddonError < Error; end

  # Raised when FriendlyId is not configured well enough to generate a slug,
  # e.g. a relation with no `:base` option.
  class ConfigurationError < Error; end
end
