module FriendlyId
  # The default slug generator offers functionality to check slug candidates for
  # availability.
  class SlugGenerator
    def initialize(scope, config)
      @scope = scope
      @config = config
    end

    def available?(slug)
      return false if reserved_conflict?(slug)
      return false if numeric_conflict?(slug)

      !@scope.exists_by_friendly_id?(slug)
    end

    def generate(candidates)
      candidates.each { |c| return c if available?(c) }
      nil
    end

    private

    # The reserved-words options are contributed by the `:reserved` addon, which
    # is adapter-specific, so detect them on the configuration rather than
    # referring to the addon module itself. That keeps this class usable by any
    # adapter whose configuration exposes the same options.
    def reserved_conflict?(slug)
      return false unless @config.respond_to?(:reserved_words)
      return false unless @config.respond_to?(:treat_reserved_as_conflict)
      return false unless @config.treat_reserved_as_conflict

      words = @config.reserved_words
      return false if words.nil? || words.empty?

      words.include?(slug)
    end

    def numeric_conflict?(slug)
      return false unless @config.respond_to?(:treat_numeric_as_conflict)
      return false unless @config.treat_numeric_as_conflict

      purely_numeric_slug?(slug)
    end

    def purely_numeric_slug?(slug)
      return false unless slug

      slug.to_s.match?(/\A[0-9]+\z/)
    end
  end
end
