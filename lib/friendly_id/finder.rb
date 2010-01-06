module FriendlyId

  class Finder

    attr_accessor :name
    attr_accessor :slug
    attr_accessor :model

    def initialize(options={})
      options.each {|key, value| self.send("#{key}=".to_sym, value)}
    end

    def slug
      @slug ||= model.slugs.find_by_name_and_sequence(*FriendlyId.parse_friendly_id(name))
    end

    def friendly?
      !! (name or slug)
    end

    def numeric?
      !friendly?
    end

    def current?
      slug == @model.slug
    end

    def outdated?
      current?
    end

    def best?
      friendly? and current?
    end

  end

end
