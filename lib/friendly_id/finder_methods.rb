module FriendlyId
  # These methods will override the finder methods in ActiveRecord::Relation.
  module FinderMethods

    protected

    # FriendlyId overrides this method to make it possible to use friendly id's
    # identically to numeric ids in finders.
    #
    # @example
    #  person = Person.find(123)
    #  person = Person.find("joe")
    #
    # @see FriendlyId::ObjectUtils
    def find_one(id)
      return super if !@klass.respond_to?(:friendly_id) || id.unfriendly_id?
      where(@klass.friendly_id_config.query_field => id).first or super
    end

    # FriendlyId overrides this method to make it possible to use friendly id's
    # identically to numeric ids in finders.
    #
    # @example
    #  person = Person.exists?(123)
    #  person = Person.exists?("joe")
    #
    # @see FriendlyId::ObjectUtils
    def exists?(id = nil)
      return super if !@klass.respond_to?(:friendly_id) || id.unfriendly_id?
      join_dependency = construct_join_dependency_for_association_find
      relation = construct_relation_for_association_find(join_dependency)
      relation = relation.except(:select).select("1").limit(1)
      relation = relation.where(@klass.friendly_id_config.query_field => id)
      connection.select_value(relation.to_sql) ? true : false
    end
  end
end
