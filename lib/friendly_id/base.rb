module FriendlyId
  # Class methods that will be added to model classes that extend {FriendlyId}.
  module Base

    # Configure FriendlyId's behavior in a model.
    #
    #   class Post < ActiveRecord::Base
    #     extend FriendlyId
    #     friendly_id :title, :use => :slugged
    #   end
    #
    # When given the optional block, this method will yield the class's instance
    # of {FriendlyId::Configuration} to the block before evaluating other
    # arguments, so configuration values set in the block may be overwritten by
    # the arguments. This order was chosen to allow passing the same proc to
    # multiple models, while being able to override the values it sets. Here is
    # a contrived example:
    #
    #   $friendly_id_config_proc = Proc.new do |config|
    #     config.base = :name
    #     config.use :slugged
    #   end
    #
    #   class Foo < ActiveRecord::Base
    #     extend FriendlyId
    #     friendly_id &$friendly_id_config_proc
    #   end
    #
    #   class Bar < ActiveRecord::Base
    #     extend FriendlyId
    #     friendly_id :title, &$friendly_id_config_proc
    #   end
    #
    # However, it's usually better to use {FriendlyId.defaults} for this:
    #
    #   FriendlyId.defaults do |config|
    #     config.base = :name
    #     config.use :slugged
    #   end
    #
    #   class Foo < ActiveRecord::Base
    #     extend FriendlyId
    #   end
    #
    #   class Bar < ActiveRecord::Base
    #     extend FriendlyId
    #     friendly_id :title
    #   end
    #
    # In general you should use the block syntax either because of your personal
    # aesthetic preference, or because you need to share some functionality
    # between multiple models that can't be well encapsulated by
    # {FriendlyId.defaults}.
    #
    # === Order Method Calls in a Block vs Ordering Options
    #
    # When calling this method without a block, you may set the hash options in
    # any order.
    #
    # However, when using block-style invocation, be sure to call
    # FriendlyId::Configuration's {FriendlyId::Configuration#use use} method
    # *prior* to the associated configuration options, because it will include
    # modules into your class, and these modules in turn may add required
    # configuration options to the +@friendly_id_configuraton+'s class:
    #
    #   class Person < ActiveRecord::Base
    #     friendly_id do |config|
    #       # This will work
    #       config.use :slugged
    #       config.sequence_separator = ":"
    #     end
    #   end
    #
    #   class Person < ActiveRecord::Base
    #     friendly_id do |config|
    #       # This will fail
    #       config.sequence_separator = ":"
    #       config.use :slugged
    #     end
    #   end
    #
    # @option options [Symbol] :use The name of an addon to use. By default,
    #   FriendlyId provides {FriendlyId::Slugged :slugged},
    #   {FriendlyId::History :history}, {FriendlyId::Reserved :reserved}, and
    #   {FriendlyId::Scoped :scoped}.
    #
    # @option options [Array] :reserved_words Available when using +:reserved+,
    #   which is loaded by default. Sets an array of words banned for use as
    #   the basis of a friendly_id. By default this includes "edit" and "new".
    #
    # @option options [Symbol] :scope Available when using +:scoped+.
    #   Sets the relation or column used to scope generated friendly ids. This
    #   option has no default value.
    #
    # @option options [Symbol] :sequence_separator Available when using +:slugged+.
    #   Configures the sequence of characters used to separate a slug from a
    #   sequence. Defaults to +--+.
    #
    # @option options [Symbol] :slug_column Available when using +:slugged+.
    #   Configures the name of the column where FriendlyId will store the slug.
    #   Defaults to +:slug+.
    #
    # @option options [Symbol] :slug_sequencer_class Available when using +:slugged+.
    #   Sets the class used to generate unique slugs. You should not specify this
    #   unless you're doing some extensive hacking on FriendlyId. Defaults to
    #   {FriendlyId::SlugSequencer}.
    #
    # @yield Provides access to the model class's friendly_id_config, which
    #   allows an alternate configuration syntax, and conditional configuration
    #   logic.
    #
    # @yieldparam config The model class's {FriendlyId::Configuration friendly_id_config}.
    def friendly_id(base = nil, options = {}, &block)
      yield @friendly_id_config if block_given?
      @friendly_id_config.use options.delete :use
      @friendly_id_config.send :set, base ? options.merge(:base => base) : options
      before_save do |record|
        record.instance_eval {@current_friendly_id = friendly_id}
      end
      include Model
    end

    # Returns the model class's {FriendlyId::Configuration friendly_id_config}.
    # @note In the case of Single Table Inheritance (STI), this method will
    #   duplicate the parent class's FriendlyId::Configuration instance on first
    #   access. If you're concerned about thread safety, then be sure to invoke
    #   {#friendly_id} in your class for each model.
    def friendly_id_config
      @friendly_id_config
    end
  end
end
