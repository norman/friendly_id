# encoding: utf-8
module FriendlyId

  # This class provides some string-manipulation methods specific to slugs.
  # Its Unicode support is provided by ActiveSupport::Multibyte::Chars; this
  # is needed primarily for Unicode encoding normalization and proper
  # calculation of string lengths.
  #
  # Note that this class includes many "bang methods" such as {#clean!} and {#normalize!}
  # that perform actions on the string in-place. Each of these methods has a
  # corresponding "bangless" method (i.e., +SlugString#clean!+ and +SlugString#clean+)
  # which does not appear in the documentation because it is generated dynamically.
  #
  # All of the bang methods return an instance of String, while the bangless
  # versions return an instance of FriendlyId::SlugString, so that calls to
  # methods specific to this class can be chained:
  #
  #   string = SlugString.new("hello world")
  #   string.with_dashes! # => "hello-world"
  #   string.with_dashes  # => <FriendlyId::SlugString:0x000001013e1590 @wrapped_string="hello-world">
  #
  # @see http://www.utf8-chartable.de/unicode-utf8-table.pl?utf8=dec Unicode character table
  # @see FriendlyId::SlugString::dump_approximations
  class SlugString < ActiveSupport::Multibyte::Chars

      # All values are Unicode decimal characters or character arrays.
      APPROXIMATIONS = {
        :common => Hash[
          192, 65, 193, 65, 194, 65, 195, 65, 196, 65, 197, 65, 198, [65, 69],
          199, 67, 200, 69, 201, 69, 202, 69, 203, 69, 204, 73, 205, 73, 206,
          73, 207, 73, 208, 68, 209, 78, 210, 79, 211, 79, 212, 79, 213, 79,
          214, 79, 215, 120, 216, 79, 217, 85, 218, 85, 219, 85, 220, 85, 221,
          89, 222, [84, 104], 223, [115, 115], 224, 97, 225, 97, 226, 97, 227,
          97, 228, 97, 229, 97, 230, [97, 101], 231, 99, 232, 101, 233, 101,
          234, 101, 235, 101, 236, 105, 237, 105, 238, 105, 239, 105, 240, 100,
          241, 110, 242, 111, 243, 111, 244, 111, 245, 111, 246, 111, 248, 111,
          249, 117, 250, 117, 251, 117, 252, 117, 253, 121, 254, [116, 104],
          255, 121, 256, 65, 257, 97, 258, 65, 259, 97, 260, 65, 261, 97, 262,
          67, 263, 99, 264, 67, 265, 99, 266, 67, 267, 99, 268, 67, 269, 99,
          270, 68, 271, 100, 272, 68, 273, 100, 274, 69, 275, 101, 276, 69, 277,
          101, 278, 69, 279, 101, 280, 69, 281, 101, 282, 69, 283, 101, 284, 71,
          285, 103, 286, 71, 287, 103, 288, 71, 289, 103, 290, 71, 291, 103,
          292, 72, 293, 104, 294, 72, 295, 104, 296, 73, 297, 105, 298, 73, 299,
          105, 300, 73, 301, 105, 302, 73, 303, 105, 304, 73, 305, 105, 306,
          [73, 74], 307, [105, 106], 308, 74, 309, 106, 310, 75, 311, 107, 312,
          107, 313, 76, 314, 108, 315, 76, 316, 108, 317, 76, 318, 108, 319, 76,
          320, 108, 321, 76, 322, 108, 323, 78, 324, 110, 325, 78, 326, 110,
          327, 78, 328, 110, 329, [39, 110], 330, [78, 71], 331, [110, 103],
          332, 79, 333, 111, 334, 79, 335, 111, 336, 79, 337, 111, 338, [79,
          69], 339, [111, 101], 340, 82, 341, 114, 342, 82, 343, 114, 344, 82,
          345, 114, 346, 83, 347, 115, 348, 83, 349, 115, 350, 83, 351, 115,
          352, 83, 353, 115, 354, 84, 355, 116, 356, 84, 357, 116, 358, 84, 359,
          116, 360, 85, 361, 117, 362, 85, 363, 117, 364, 85, 365, 117, 366, 85,
          367, 117, 368, 85, 369, 117, 370, 85, 371, 117, 372, 87, 373, 119,
          374, 89, 375, 121, 376, 89, 377, 90, 378, 122, 379, 90, 380, 122, 381,
          90, 382, 122
        ].freeze,
        :german => Hash[252, [117, 101], 246, [111, 101], 228, [97, 101]],
        :spanish => Hash[209, [78, 110], 241, [110, 110]]
      }

      # CP-1252 decimal byte => UTF-8 approximation as an array of bytes
      CP1252 = {
        128 => [226, 130, 172],
        129 => nil,
        130 => [226, 128, 154],
        131 => [198, 146],
        132 => [226, 128, 158],
        133 => [226, 128, 166],
        134 => [226, 128, 160],
        135 => [226, 128, 161],
        136 => [203, 134],
        137 => [226, 128, 176],
        138 => [197, 160],
        139 => [226, 128, 185],
        140 => [197, 146],
        141 => nil,
        142 => [197, 189],
        143 => nil,
        144 => nil,
        145 => [226, 128, 152],
        146 => [226, 128, 153],
        147 => [226, 128, 156],
        148 => [226, 128, 157],
        149 => [226, 128, 162],
        150 => [226, 128, 147],
        151 => [226, 128, 148],
        152 => [203, 156],
        153 => [226, 132, 162],
        154 => [197, 161],
        155 => [226, 128, 186],
        156 => [197, 147],
        157 => nil,
        158 => [197, 190],
        159 => [197, 184]
      }

      cattr_accessor :approximations
      self.approximations = []

      # This method can be used by developers wishing to debug the
      # {APPROXIMATIONS} hashes, which are written in a hard-to-read format.
      # @return Hash
      # @example
      #
      #  > ruby -rrubygems -rlib/friendly_id -e 'p FriendlyId::SlugString.dump_approximations'
      #
      # {:common =>
      # {"À"=>"A", "Á"=>"A", "Â"=>"A", "Ã"=>"A", "Ä"=>"A", "Å"=>"A", "Æ"=>"AE",
      # "Ç"=>"C", "È"=>"E", "É"=>"E", "Ê"=>"E", "Ë"=>"E", "Ì"=>"I", "Í"=>"I",
      # "Î"=>"I", "Ï"=>"I", "Ð"=>"D", "Ñ"=>"N", "Ò"=>"O", "Ó"=>"O", "Ô"=>"O",
      # "Õ"=>"O", "Ö"=>"O", "×"=>"x", "Ø"=>"O", "Ù"=>"U", "Ú"=>"U", "Û"=>"U",
      # "Ü"=>"U", "Ý"=>"Y", "Þ"=>"Th", "ß"=>"ss", "à"=>"a", "á"=>"a", "â"=>"a",
      # "ã"=>"a", "ä"=>"a", "å"=>"a", "æ"=>"ae", "ç"=>"c", "è"=>"e", "é"=>"e",
      # "ê"=>"e", "ë"=>"e", "ì"=>"i", "í"=>"i", "î"=>"i", "ï"=>"i", "ð"=>"d",
      # "ñ"=>"n", "ò"=>"o", "ó"=>"o", "ô"=>"o", "õ"=>"o", "ö"=>"o", "ø"=>"o",
      # "ù"=>"u", "ú"=>"u", "û"=>"u", "ü"=>"u", "ý"=>"y", "þ"=>"th", "ÿ"=>"y",
      # "Ā"=>"A", "ā"=>"a", "Ă"=>"A", "ă"=>"a", "Ą"=>"A", "ą"=>"a", "Ć"=>"C",
      # "ć"=>"c", "Ĉ"=>"C", "ĉ"=>"c", "Ċ"=>"C", "ċ"=>"c", "Č"=>"C", "č"=>"c",
      # "Ď"=>"D", "ď"=>"d", "Đ"=>"D", "đ"=>"d", "Ē"=>"E", "ē"=>"e", "Ĕ"=>"E",
      # "ĕ"=>"e", "Ė"=>"E", "ė"=>"e", "Ę"=>"E", "ę"=>"e", "Ě"=>"E", "ě"=>"e",
      # "Ĝ"=>"G", "ĝ"=>"g", "Ğ"=>"G", "ğ"=>"g", "Ġ"=>"G", "ġ"=>"g", "Ģ"=>"G",
      # "ģ"=>"g", "Ĥ"=>"H", "ĥ"=>"h", "Ħ"=>"H", "ħ"=>"h", "Ĩ"=>"I", "ĩ"=>"i",
      # "Ī"=>"I", "ī"=>"i", "Ĭ"=>"I", "ĭ"=>"i", "Į"=>"I", "į"=>"i", "İ"=>"I",
      # "ı"=>"i", "Ĳ"=>"IJ", "ĳ"=>"ij", "Ĵ"=>"J", "ĵ"=>"j", "Ķ"=>"K", "ķ"=>"k",
      # "ĸ"=>"k", "Ĺ"=>"L", "ĺ"=>"l", "Ļ"=>"L", "ļ"=>"l", "Ľ"=>"L", "ľ"=>"l",
      # "Ŀ"=>"L", "ŀ"=>"l", "Ł"=>"L", "ł"=>"l", "Ń"=>"N", "ń"=>"n", "Ņ"=>"N",
      # "ņ"=>"n", "Ň"=>"N", "ň"=>"n", "ŉ"=>"'n", "Ŋ"=>"NG", "ŋ"=>"ng",
      # "Ō"=>"O", "ō"=>"o", "Ŏ"=>"O", "ŏ"=>"o", "Ő"=>"O", "ő"=>"o", "Œ"=>"OE",
      # "œ"=>"oe", "Ŕ"=>"R", "ŕ"=>"r", "Ŗ"=>"R", "ŗ"=>"r", "Ř"=>"R", "ř"=>"r",
      # "Ś"=>"S", "ś"=>"s", "Ŝ"=>"S", "ŝ"=>"s", "Ş"=>"S", "ş"=>"s", "Š"=>"S",
      # "š"=>"s", "Ţ"=>"T", "ţ"=>"t", "Ť"=>"T", "ť"=>"t", "Ŧ"=>"T", "ŧ"=>"t",
      # "Ũ"=>"U", "ũ"=>"u", "Ū"=>"U", "ū"=>"u", "Ŭ"=>"U", "ŭ"=>"u", "Ů"=>"U",
      # "ů"=>"u", "Ű"=>"U", "ű"=>"u", "Ų"=>"U", "ų"=>"u", "Ŵ"=>"W", "ŵ"=>"w",
      # "Ŷ"=>"Y", "ŷ"=>"y", "Ÿ"=>"Y", "Ź"=>"Z", "ź"=>"z", "Ż"=>"Z", "ż"=>"z",
      # "Ž"=>"Z", "ž"=>"z"},
      # :german => {"ü"=>"ue", "ö"=>"oe", "ä"=>"ae"},
      # :spanish => {"Ñ"=>"Nn", "ñ"=>"nn"}}
      def self.dump_approximations
        Hash[APPROXIMATIONS.map do |name, approx|
          [name, Hash[approx.map {|key, value| [[key].pack("U*"), [value].flatten.pack("U*")]}]]
        end]
      end


      # @param string [String] The string to use as the basis of the SlugString.
      def initialize(string)
        super string.to_s
        tidy_bytes!
      end

      # Approximate an ASCII string. This works only for Western strings using
      # characters that are Roman-alphabet characters + diacritics. Non-letter
      # characters are left unmodified.
      #
      #   string = SlugString.new "Łódź, Poland"
      #   string.approximate_ascii                 # => "Lodz, Poland"
      #   string = SlugString.new "日本"
      #   string.approximate_ascii                 # => "日本"
      #
      # You can pass any key(s) from {APPROXIMATIONS} as arguments. This allows
      # for contextual approximations. By default; +:spanish+ and +:german+ are
      # provided:
      #
      #   string = SlugString.new "Jürgen Müller"
      #   string.approximate_ascii                 # => "Jurgen Muller"
      #   string.approximate_ascii :german        # => "Juergen Mueller"
      #   string = SlugString.new "¡Feliz año!"
      #   string.approximate_ascii                 # => "¡Feliz ano!"
      #   string.approximate_ascii :spanish       # => "¡Feliz anno!"
      #
      # You can modify the built-in approximations, or add your own:
      #
      #   # Make Spanish use "nh" rather than "nn"
      #   FriendlyId::SlugString::APPROXIMATIONS[:spanish] = {
      #     # Ñ => "Nh"
      #     209 => [78, 104],
      #     # ñ => "nh"
      #     241 => [110, 104]
      #   }
      #
      # It's also possible to use a custom approximation for all strings:
      #
      #   FriendlyId::SlugString.approximations << :german
      #
      # Notice that this method does not simply convert to ASCII; if you want
      # to remove non-ASCII characters such as "¡" and "¿", use {#to_ascii!}:
      #
      #   string.approximate_ascii!(:spanish)       # => "¡Feliz anno!"
      #   string.to_ascii!                          # => "Feliz anno!"
      # @param *args <Symbol>
      # @return String
      def approximate_ascii!(*args)
        @maps = (self.class.approximations + args.flatten + [:common]).flatten.uniq
        @wrapped_string = normalize_utf8(:c).unpack("U*").map { |char| approx_char(char) }.flatten.pack("U*")
      end

      # Removes leading and trailing spaces or dashses, and replaces multiple
      # whitespace characters with a single space.
      # @return String
      def clean!
        @wrapped_string = @wrapped_string.gsub(/\A\-|\-\z/, "").gsub(/\s+/u, " ").strip
      end

      # Lowercases the string. Note that this works for Unicode strings,
      # though your milage may vary with Greek and Turkic strings.
      # @return String
      def downcase!
        @wrapped_string = apply_mapping :lowercase_mapping
      end

      if defined? ActiveSupport::Multibyte::Unicode
        def apply_mapping(*args)
          ActiveSupport::Multibyte::Unicode.apply_mapping(@wrapped_string, *args)
        end
      end

      # Remove any non-word characters.
      # @return String
      def word_chars!
        @wrapped_string = normalize_utf8(:c).unpack("U*").map { |char|
          case char
          # control chars
          when 0..31
          # punctuation; 45 is "-" (HYPHEN-MINUS) and allowed
          when 33..44
          # more puncuation
          when 46..47
          # more puncuation and other symbols
          when 58..64
          # brackets and other symbols
          when 91..96
          # braces, pipe, tilde, etc.
          when 123..191
          else char
          end
        }.compact.pack("U*")
      end

      # Normalize the string for a given {FriendlyId::Configuration}.
      # @param config [FriendlyId::Configuration]
      # @return String
      def normalize_for!(config)
        approximate_ascii!(config.ascii_approximation_options) if config.approximate_ascii?
        to_ascii! if config.strip_non_ascii?
        normalize!
      end

      alias :normalize_utf8 :normalize rescue NoMethodError

      # Normalize the string for use as a FriendlyId. Note that in
      # this context, +normalize+ means, strip, remove non-letters/numbers,
      # downcasing and converting whitespace to dashes.
      # ActiveSupport::Multibyte::Chars#normalize is aliased to +normalize_utf8+
      # in this subclass.
      # @return String
      def normalize!
        clean!
        word_chars!
        downcase!
        with_dashes!
      end

      # Attempt to replace invalid UTF-8 bytes with valid ones. This method
      # naively assumes if you have invalid UTF8 bytes, they are either Windows
      # CP-1252 or ISO8859-1. In practice this isn't a bad assumption, but may not
      # always work.
      #
      # Passing +true+ will forcibly tidy all bytes, assuming that the string's
      # encoding is CP-1252 or ISO-8859-1.
      def tidy_bytes!(force = false)

        if force
          @wrapped_string = @wrapped_string.unpack("C*").map do |b|
            tidy_byte(b)
          end.flatten.compact.pack("C*").unpack("U*").pack("U*")
        end

        bytes = @wrapped_string.unpack("C*")
        conts_expected = 0
        last_lead = 0

        bytes.each_index do |i|

          byte          = bytes[i]
          is_ascii      = byte < 128
          is_cont       = byte > 127 && byte < 192
          is_lead       = byte > 191 && byte < 245
          is_unused     = byte > 240
          is_restricted = byte > 244

          # Impossible or highly unlikely byte? Clean it.
          if is_unused || is_restricted
            bytes[i] = tidy_byte(byte)
          elsif is_cont
            # Not expecting contination byte? Clean up. Otherwise, now expect one less.
            conts_expected == 0 ? bytes[i] = tidy_byte(byte) : conts_expected -= 1
          else
            if conts_expected > 0
              # Expected continuation, but got ASCII or leading? Clean backwards up to
              # the leading byte.
              (1..(i - last_lead)).each {|j| bytes[i - j] = tidy_byte(bytes[i - j])}
              conts_expected = 0
            end
            if is_lead
              # Final byte is leading? Clean it.
              if i == bytes.length - 1
                bytes[i] = tidy_byte(bytes.last)
              else
                # Valid leading byte? Expect continuations determined by position of
                # first zero bit, with max of 3.
                conts_expected = byte < 224 ? 1 : byte < 240 ? 2 : 3
                last_lead = i
              end
            end
          end
        end
        @wrapped_string = bytes.empty? ? "" : bytes.flatten.compact.pack("C*").unpack("U*").pack("U*")
      end

      # Delete any non-ascii characters.
      # @return String
      def to_ascii!
        if ">= 1.9".respond_to?(:force_encoding)
          @wrapped_string.encode!("ASCII", :invalid => :replace, :undef => :replace,
            :replace => "")
        else
          @wrapped_string = tidy_bytes.normalize_utf8(:c).unpack("U*").reject {|char| char > 127}.pack("U*")
        end
      end

      # Truncate the string to +max+ length.
      # @return String
      def truncate!(max)
        @wrapped_string = self[0...max].to_s if length > max
      end

      # Upper-cases the string. Note that this works for Unicode strings,
      # though your milage may vary with Greek and Turkic strings.
      # @return String
      def upcase!
        @wrapped_string = apply_mapping :uppercase_mapping
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

      # Replaces whitespace with dashes ("-").
      # @return String
      def with_dashes!
        @wrapped_string = @wrapped_string.gsub(/[\s\-]+/u, "-")
      end

      %w[approximate_ascii clean downcase word_chars normalize normalize_for tidy_bytes
          to_ascii truncate upcase with_dashes].each do |method|
        class_eval(<<-EOM)
          def #{method}(*args)
            send_to_new_instance(:#{method}!, *args)
          end
        EOM
      end

      private

      # Look up the character's approximation in the configured maps.
      def approx_char(char)
        @maps.each do |map|
          if new_char = APPROXIMATIONS[map][char]
            return new_char
          end
        end
        char
      end

      # Used as the basis of the bangless methods.
      def send_to_new_instance(*args)
        string = SlugString.new self
        string.send(*args)
        string
      end

      def tidy_byte(byte)
        byte < 160 ? CP1252[byte] : byte < 192 ? [194, byte] : [195, byte - 64]
      end

  end
end
