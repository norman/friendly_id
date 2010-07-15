module FriendlyId
  module Version
    MAJOR = 3
    MINOR = 1
    TINY = 0
    BUILD = "pre"
    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join('.')
  end
end
