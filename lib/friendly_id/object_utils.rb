module FriendlyId
  # Instances of these classes will never be considered a friendly id.
  # @see FriendlyId::ObjectUtils#friendly_id
  UNFRIENDLY_CLASSES = [
    Array,
    FalseClass,
    Hash,
    NilClass,
    Numeric,
    Symbol,
    TrueClass
  ]

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
      true if respond_to?(:to_i) && to_i.to_s != to_s
    end

    # True if the id is definitely unfriendly, false if definitely friendly,
    # else nil.
    def unfriendly_id?
      val = friendly_id?
      !val unless val.nil?
    end
  end

  module UnfriendlyUtils
    def friendly_id?
      false
    end

    def unfriendly_id?
      true
    end
  end

  def self.mark_as_unfriendly(klass)
    klass.send(:include, FriendlyId::UnfriendlyUtils)
  end

  # True if the value can never be a friendly id: an instance of an
  # {UNFRIENDLY_CLASSES} member, or of a class passed to {mark_as_unfriendly}.
  #
  # Consults {UNFRIENDLY_CLASSES} directly rather than depending on
  # {mark_as_unfriendly} having been called for each of them.
  def self.unfriendly_id?(value)
    return true if value.is_a?(FriendlyId::UnfriendlyUtils)

    UNFRIENDLY_CLASSES.any? { |klass| value.is_a?(klass) }
  end

  # True if the value can only be a friendly id.
  #
  # This and {unfriendly_id?} are not complements. A numeric string is neither:
  # "123" may be a slug or a primary key, so both return false and the finders
  # try the slug before falling back to the primary key.
  #
  # `Object#friendly_id?` answers nil for that case instead. These take a value
  # and return true or false, so nil never escapes into a caller's conditional.
  def self.friendly_id?(value)
    return false if unfriendly_id?(value)

    value.respond_to?(:to_i) && value.to_i.to_s != value.to_s
  end
end

Object.send :include, FriendlyId::ObjectUtils

# Considered unfriendly if object is an instance of an unfriendly class or
# one of its descendants.

FriendlyId::UNFRIENDLY_CLASSES.each { |klass| FriendlyId.mark_as_unfriendly(klass) }

ActiveSupport.on_load(:active_record) do
  FriendlyId.mark_as_unfriendly(ActiveRecord::Base)
end
