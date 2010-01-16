module FriendlyId

  # FriendlyId::AbstractStatus presents information about the status of the
  # id that was used to find the model.
  # @abstract
  module BaseStatus

    # The id or name used as the finder argument
    attr_accessor :name

    # The found result, if any
    attr_accessor :record

    def initialize(options={})
      options.each {|key, value| self.send("#{key}=".to_sym, value)}
    end

    # Did the find operation use a friendly id?
    def friendly?
      raise NotImplemtedError.new
    end

    # Did the find operation use a numeric id?
    def numeric?
      !friendly?
    end

    # Did the find operation use the best possible id? True if there is
    # a slug, and the most recent one was used.
    def best?
      raise NotImplementedError.new
    end

  end

end
