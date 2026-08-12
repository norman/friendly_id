module FriendlyId
  # The default slug generator offers functionality to check slug candidates for
  # availability.
  class SlugGenerator
    def initialize(scope, config)
      @scope = scope
      @config = config
    end

    def available?(slug)
      if @config.uses?(::FriendlyId::Reserved) && @config.reserved_words.present? && @config.treat_reserved_as_conflict
        return false if @config.reserved_words.include?(slug)
      end

      if @config.treat_numeric_as_conflict && purely_numeric_slug?(slug)
        return false
      end

      !@scope.exists_by_friendly_id?(slug)
    end

    def generate(candidates)
      candidates.each { |c| return c if available?(c) }
      nil
    end

    private

    def purely_numeric_slug?(slug)
      return false unless slug
      begin
        Integer(slug, 10).to_s == slug.to_s
      rescue ArgumentError, TypeError
        false
      end
    end
  end
end
