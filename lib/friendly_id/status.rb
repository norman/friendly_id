module FriendlyId

  # FriendlyId::Status presents information about the status of the
  # id that was used to find the model. This class can be useful for figuring
  # out when to redirect to a new URL.
  class Status

    # The id or name used as the finder argument
    attr_accessor :name

    # The found result, if any
    attr_accessor :record

    def initialize(options={})
      options.each {|key, value| self.send("#{key}=".to_sym, value)}
    end

    # Did the find operation use a friendly id?
    def friendly?
      !! name
    end

    # Did the find operation use a numeric id?
    def numeric?
      !friendly?
    end

    # Did the find operation use the best available id?
    def best?
      record.friendly_id && friendly?
    end

  end

end