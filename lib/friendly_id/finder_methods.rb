module FriendlyId
  # These methods will override the finder methods in ActiveRecord::Relation.
  module FinderMethods

    protected

    def find_one(id)
      return super if !@klass.respond_to?(:has_friendly_id) or id.unfriendly_id?
      where(@klass.friendly_id_config.query_field => id).first or super
    end
  end
end

ActiveRecord::Relation.send :include, FriendlyId::FinderMethods
