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
    # yields the wanted slug candidates.
    def each(*args, &block)
      @candidates.map do |candidate|
        slug = @object.normalize_friendly_id(candidate.map(&:call).join(' '))
        yield slug if wanted?(slug)
      end
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
      !slug.blank?
    end
  end
end
