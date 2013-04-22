require 'securerandom'

module FriendlyId

  class Candidates

    include Enumerable

    def initialize(object, *array)
      @object = object
      @candidates = to_candidate_array(object, array.flatten(1))
    end

    def each(*args, &block)
      @candidates.each(*args) do |candidate|
        yield @object.normalize_friendly_id(candidate.map(&:call).join(' '))
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
  end
end