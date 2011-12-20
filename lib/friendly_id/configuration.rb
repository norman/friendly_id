module FriendlyId
  # The configuration paramters passed to +friendly_id+ will be stored in
  # this object.
  class Configuration

    # The base column or method used by FriendlyId as the basis of a friendly id
    # or slug.
    #
    # For models that don't use FriendlyId::Slugged, the base is the column that
    # is used as the FriendlyId directly. For models using FriendlyId::Slugged,
    # the base is a column or method whose value is used as the basis of the
    # slug.
    #
    # For example, if you have a model representing blog posts and that uses
    # slugs, you likely will want to use the "title" attribute as the base, and
    # FriendlyId will take care of transforming the human-readable title into
    # something suitable for use in a URL.
    #
    # @param [Symbol] A symbol referencing a column or method in the model. This
    #   value is usually set by passing it as the first argument to
    #   {FriendlyId::Base#friendly_id friendly_id}:
    #
    # @example
    #   class Book < ActiveRecord::Base
    #     extend FriendlyId
    #     friendly_id :name
    #   end
    attr_accessor :base

    # The default configuration options.
    attr_reader :defaults

    # The model class that this configuration belongs to.
    # @return ActiveRecord::Base
    attr_reader :model_class

    def initialize(model_class, values = nil)
      @model_class = model_class
      @defaults    = {}
      set values
    end

    # Lets you specify the modules to use with FriendlyId.
    #
    # This method is invoked by {FriendlyId::Base#friendly_id friendly_id} when
    # passing the +:use+ option, or when using {FriendlyId::Base#friendly_id
    # friendly_id} with a block.
    #
    # @example
    #   class Book < ActiveRecord::Base
    #     extend FriendlyId
    #     friendly_id :name, :use => :slugged
    #   end
    # @param [#to_s] *modules Arguments should be a symbols or strings that
    #   correspond with the name of a module inside the FriendlyId namespace. By
    #   default FriendlyId provides +:slugged+, +:history+, +:simple_i18n+ and +:scoped+.
    def use(*modules)
      modules.to_a.flatten.compact.map do |name|
        mod = FriendlyId.const_get(name.to_s.classify)
        model_class.send(:include, mod) unless model_class < mod
      end
    end

    # The column that FriendlyId will use to find the record when querying by
    # friendly id.
    #
    # This method is generally only used internally by FriendlyId.
    # @return String
    def query_field
      base.to_s
    end

    private

    def set(values)
      values and values.each {|name, value| self.send "#{name}=", value}
    end
  end
end
