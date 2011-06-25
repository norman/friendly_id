require "friendly_id/slugged"

module FriendlyId

  # This module adds scopes to in-table slugs. It's not loaded by default,
  # so in order to active this feature you must include the module in your
  # class.
  #
  # You can scope by an explicit column, or by a `belongs_to` relation.
  #
  # @example
  #   class Restaurant < ActiveRecord::Base
  #     belongs_to :city
  #     include FriendlyId::Scoped
  #     has_friendly_id :name, :scope => :city
  #   end
  module Scoped
    def self.included(klass)
      klass.send :include, Slugged unless klass.include? Slugged
    end
  end

  class SlugSequencer
    private

    alias conflict_without_scope conflict

    # Checks for naming conflicts, taking scopes into account.
    # @return ActiveRecord::Base
    def conflict_with_scope
      column = friendly_id_config.scope_column
      conflicts.where("#{column} = ?", sluggable.send(column)).first
    end

    def conflict
      friendly_id_config.scope ? conflict_with_scope : conflict_without_scope
    end
  end

  class Configuration
    attr_accessor :scope

    # Gets the scope column.
    #
    # Checks to see if the +:scope+ option passed to {#has_friendly_id}
    # refers to a relation, and if so, returns the realtion's foreign key.
    # Otherwise it assumes the option value was the name of column and returns
    # it cast to a String.
    # @return String The scope column
    def scope_column
      (klass.reflections[@scope].try(:association_foreign_key) || @scope).to_s
    end
  end
end
