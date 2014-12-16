require 'securerandom'

module FriendlyId

  # This class provides the slug candidate functionality.
  # @see FriendlyId::Slugged
  class Candidates

    include Enumerable

    def initialize(object, *array)
      @object = object
      @candidates = to_candidate_array(object, array.flatten(1))
    end

    # Visits each candidate, calls it, passes it to `normalize_friendly_id` and
    # yields any wanted and unreserved slug candidates.
    def each(*args, &block)
      pre_candidates = @candidates.map do |candidate|
        @object.normalize_friendly_id(candidate.map(&:call).join(' '))
      end.select {|x| wanted?(x)}

      unless pre_candidates.all? {|x| reserved?(x)}
        pre_candidates.reject! {|x| reserved?(x)}
      end
      pre_candidates.each {|x| yield x}
    end

    private

    def to_candidate_array(object, array)
      array.map do |candidate|
        case candidate
        when String
          [->{candidate}]
        when Array
          to_candidate_array(object, candidate).flatten
        when Symbol
          [object.method(candidate)]
        else
          if candidate.respond_to?(:call)
            [candidate]
          else
            [->{candidate.to_s}]
          end
        end
      end
    end

    def wanted?(slug)
      slug.present?
    end

    private

    def reserved?(slug)
      config = @object.friendly_id_config
      return false unless config.uses? ::FriendlyId::Reserved
      return false unless config.reserved_words
      config.reserved_words.include?(slug)
    end
  end
end
