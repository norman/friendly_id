module FriendlyId

  module StringHelpers

    # Return a dasherized string suitable for use as friendly_id in a URL.
    def to_friendly_id
      s = clone
      s.to_friendly_id!
      s
    end

    # Generate friendly_id string and replace self.
    def to_friendly_id!
      return "" if self.blank?
      strip_special_chars!
      gsub!(/\W+/, ' ')
      strip!
      gsub!(/\s+/, '-')
      gsub!(/-\z/, '')
      replace Unicode.normalize_KC(Unicode::downcase(self))
    end

    # Strips punctuation and some other "weird" characters.
    def strip_special_chars
      Unicode.normalize_KD(self).unpack('U*').reject { |cp|
        # Control chars and some punctuation
        cp < 48 ||
        # Some more punctuation
        cp >= 58 && cp <= 64 ||
        # Brackets and stuff
        cp >= 91 && cp <= 96 ||
        # More brackets and stuff
        cp >= 123 && cp <= 137 ||
        # Quotes, dashes and stuff
        cp >= 143 && cp <= 153
        # Currencies and stuff
        cp >= 160 && cp <= 191 ||
        # General punctuation range
        cp >= 8192 && cp <= 8303 ||
        # "<"
        cp == 139 ||
        # Some control or blank char
        cp == 141 ||
        # ">"
        cp == 155 ||
        # Some control or blank char
        cp == 157
      }.pack('U*')
    end

    # Strip special characters, replacing self with output.
    def strip_special_chars!
      replace strip_special_chars
    end

    # Remove diacritics from the string, converting Western European strings
    # to ASCII. For example:
    #
    #   Slug::strip_diacritics("lingüística") # returns "linguistica"
    #
    # Don't bother trying this with strings in Russian, Hebrew, Japanese, etc.
    # It only works for strings that use some variation of the Roman alphabet.
    #
    # The code here was taken from Hal Fulton's "The Ruby Way, Second
    # Edition", page 151.
    def strip_diacritics
      Unicode.normalize_KD(self).unpack('U*').select { |cp|
        cp < 0x300 || cp > 0x036F
      }.pack('U*')
    end

    # Strip diacritics, replacing self with output.
    def strip_diacritics!
      replace strip_diacritics
    end

  end

end