class SlugString < ActiveSupport::Multibyte::Chars

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

    cattr_accessor :approximations
    self.approximations = []

    def initialize(string)
      super string.to_s
    end

    def approximate_ascii!(*args)
      @maps = (self.class.approximations + args + [:common]).flatten.uniq
      @wrapped_string = normalize_utf8(:c).unpack("U*").map { |char| approx_char(char) }.flatten.pack("U*")
    end

    def clean!
      @wrapped_string = @wrapped_string.gsub(/\A\-|\-\z/, '').gsub(/\s+/u, ' ').strip
    end

    def downcase!
      @wrapped_string = apply_mapping :lowercase_mapping
    end

    def letters!
      @wrapped_string = normalize_utf8(:c).unpack("U*").map { |char|
        case char
        when 0..31
        when 33..44
        when 46..47
        when 58..64
        when 91..96
        when 123..191
        else char
        end
      }.compact.pack("U*")
    end

    alias normalize_utf8 normalize

    def normalize!
      clean!
      letters!
      downcase!
      with_dashes!
    end

    def to_ascii!
      @wrapped_string = normalize_utf8(:c).unpack("U*").reject {|char| char > 127}.pack("U*")
    end

    def upcase!
      @wrapped_string = apply_mapping :uppercase_mapping
    end

    def with_dashes!
      @wrapped_string = @wrapped_string.gsub(/\s+/u, '-')
    end

    %w[approximate_ascii clean downcase letters normalize to_ascii upcase with_dashes].each do |method|
      class_eval(<<-EOM)
        def #{method}(*args)
          send_to_new_instance(:#{method}!, *args)
        end
      EOM
    end

    private

    def approx_char(char)
      @maps.each do |map|
        if new_char = APPROXIMATIONS[map][char]
          return new_char
        end
      end
      char
    end

    def send_to_new_instance(*args)
      string = SlugString.new self
      string.send(*args)
      string
    end

end
