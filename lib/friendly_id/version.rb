module FriendlyId
  module Version
    MAJOR = 3
    MINOR = 2
    TINY = 0
    BUILD = "beta1"
    STRING = [MAJOR, MINOR, TINY, BUILD].compact.join('.')
  end
end
