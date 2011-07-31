module FriendlyId
  # Class methods that will be added to ActiveRecord::Base.
  module Base

    # Configure FriendlyId for a model. Use this method to configure FriendlyId
    # for your model.
    #
    #   class Post < ActiveRecord::Base
    #     extend FriendlyId
    #     friendly_id :title, :use => :slugged
    #   end
    #
    # @option options [Symbol] :use The name of an addon to use. By default, FriendlyId
    #   provides {FriendlyId::Slugged :slugged}, {FriendlyId::History :history}
    #   and {FriendlyId::Scoped :scoped}.
    # @option options [Symbol] :slug_column Available when using +:slugged+.
    #   Configures the name of the column where FriendlyId will store the slug.
    #   Defaults to +:slug+.
    def friendly_id(base = nil, options = {}, &block)
      yield @friendly_id_config if block_given?
      @friendly_id_config.use options.delete :use
      @friendly_id_config.send :set, options.merge(:base => base)
      before_save do |record|
        record.instance_eval {@current_friendly_id = friendly_id}
      end
      include Model
    end

    def friendly_id_config
      @friendly_id_config
    end
  end
end
