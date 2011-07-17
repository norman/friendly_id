module FriendlyId
  # These methods will override the finder methods in ActiveRecord::Relation.
  module FinderMethods

    protected

    def find_one(id)
      return super if !@klass.respond_to?(:friendly_id) || id.unfriendly_id?
      where(@klass.friendly_id_config.query_field => id).first or super
    end
  end
end
