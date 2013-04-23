module FriendlyId

=begin

== History: Avoiding 404's When Slugs Change

FriendlyId's {FriendlyId::History History} module adds the ability to store a
log of a model's slugs, so that when its friendly id changes, it's still
possible to perform finds by the old id.

The primary use case for this is avoiding broken URLs.

=== Setup

In order to use this module, you must add a table to your database schema to
store the slug records. FriendlyId provides a generator for this purpose:

  rails generate friendly_id
  rake db:migrate

This will add a table named +friendly_id_slugs+, used by the {FriendlyId::Slug}
model.

=== Considerations

This module is incompatible with the +:scoped+ module.

Because recording slug history requires creating additional database records,
this module has an impact on the performance of the associated model's +create+
method.

=== Example

    class Post < ActiveRecord::Base
      extend FriendlyId
      friendly_id :title, :use => :history
    end

    class PostsController < ApplicationController

      before_filter :find_post

      ...

      def find_post
        @post = Post.find params[:id]

        # If an old id or a numeric id was used to find the record, then
        # the request path will not match the post_path, and we should do
        # a 301 redirect that uses the current friendly id.
        if request.path != post_path(@post)
          return redirect_to @post, :status => :moved_permanently
        end
      end
    end
=end
  module History

    # Configures the model instance to use the History add-on.
    def self.included(model_class)
      model_class.instance_eval do
        @friendly_id_config.use :slugged
        has_many :slugs, :as => :sluggable, :dependent => :destroy,
          :class_name => Slug.to_s, :order => "#{Slug.quoted_table_name}.id DESC"
        after_save :create_slug

        def self.find_by_friendly_id(id)
          includes(:slugs).where("#{Slug.table_name}.sluggable_type = ? AND #{Slug.table_name}.slug = ?", base_class.to_s, id).first
        end

        def self.exists_by_friendly_id?(id)
          includes(:slugs).where("#{table_name}.#{friendly_id_config.query_field} = ?
            OR #{Slug.table_name}.sluggable_type = ? AND #{Slug.table_name}.slug = ?", id, base_class.to_s, id).exists?
        end
      end
    end

    private

    def create_slug
      return unless friendly_id
      return if slugs.first.try(:slug) == friendly_id
      # Allow reversion back to a previously used slug
      relation = slugs.where(:slug => friendly_id)
      result = relation.select("id").lock(true)
      relation.delete_all unless result.empty?
      slugs.create! do |record|
        record.slug = friendly_id
        record.scope = serialized_scope if friendly_id_config.uses?(:scoped)
      end
    end
  end
end
