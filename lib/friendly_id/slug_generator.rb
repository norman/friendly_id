module FriendlyId
  # The default slug generator offers functionality to check slug candidates for
  # availability.
  class SlugGenerator

    def initialize(scope)
      @scope = scope
    end

    def available?(slug)
      !@scope.exists_by_friendly_id?(slug)
    end

    def generate(candidates)
      candidates.each {|c| return c if available?(c)}
      nil
    end

  end
end
