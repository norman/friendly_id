module FriendlyId
  # Utility methods for determining whether any object is a friendly id.
  #
  # Monkey-patching Object is a somewhat extreme measure not to be taken lightly
  # by libraries, but in this case I decided to do it because to me, it feels
  # cleaner than adding a module method to {FriendlyId}. I've given the methods
  # names that unambigously refer to the library of their origin, which should
  # be sufficient to avoid conflicts with other libraries.
  module ObjectUtils

    # True if the id is definitely friendly, false if definitely unfriendly,
    # else nil.
    #
    # An object is considired "definitely unfriendly" if its class is or
    # inherits from ActiveRecord::Base, Array, Hash, NilClass, Numeric, or
    # Symbol.
    #
    # An object is considered "definitely friendly" if it responds to +to_i+,
    # and its value when cast to an integer and then back to a string is
    # different from its value when merely cast to a string:
    #
    #     123.friendly_id?                  #=> false
    #     :id.friendly_id?                  #=> false
    #     {:name => 'joe'}.friendly_id?     #=> false
    #     ['name = ?', 'joe'].friendly_id?  #=> false
    #     nil.friendly_id?                  #=> false
    #     "123".friendly_id?                #=> nil
    #     "abc123".friendly_id?             #=> true
    def friendly_id?
      # Considered unfriendly if this is an instance of an unfriendly class or
      # one of its descendants.
      if FriendlyId::UNFRIENDLY_CLASSES.detect {|klass| self.class <= klass}
        false
      elsif respond_to?(:to_i) && to_i.to_s != to_s
        true
      end
    end

    # True if the id is definitely unfriendly, false if definitely friendly,
    # else nil.
    def unfriendly_id?
      val = friendly_id? ; !val unless val.nil?
    end
  end
end

Object.send :include, FriendlyId::ObjectUtils
