module FriendlyId
  # Utility methods that are in Object because it's impossible to predict what
  # kinds of objects get passed into FinderMethods#find_one and
  # Model#normalize_friendly_id.
  module ObjectUtils

    # True is the id is definitely friendly, false if definitely unfriendly,
    # else nil.
    #
    # An object is considired "definitely unfriendly" if its class is or
    # inherits from Numeric, Symbol or ActiveRecord::Base.
    def friendly_id?
      if [Numeric, Symbol, ActiveRecord::Base].detect {|klass| self.class < klass}
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

class Object
  include FriendlyId::ObjectUtils
end
