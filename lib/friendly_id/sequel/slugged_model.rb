module FriendlyId
  module Sequel

    module SluggedModel

      class SingleFinder

        include FriendlyId::Finders::Base
        include FriendlyId::Finders::Single

        def find
          join(*join_conditions).select(columns).where(conditions).first
        end

        private
        
        def columns
          :"#{table_name}".*
        end

        def conditions
          {:name.qualify("slugs") => name, :sequence.qualify("slugs") => sequence}
        end

        def join_conditions
          return :slugs, :sluggable_id => :id, :sluggable_type => model_class.to_s
        end

      end

      include FriendlyId::Slugged

      def self.included(base)
        base.one_to_many :slugs,
          :class => slug_class,
          :key => "sluggable_id",
          :conditions => {:sluggable_type => "#{base.to_s}"},
          :order => "id DESC"
        def base.[](*args)
          if args.size == 1
            SingleFinder.new(args.first, self).find or super
          else
            super
          end
        end
      end

      def self.slug_class
        FriendlyId::Sequel::Slug
      end

      private

      def after_save
        @slug.sluggable_id = id
        @slug.save
      end

      def build_slug
        self.slug = SluggedModel.slug_class.new :name => slug_text,
          :sluggable_type => self.class.to_s
      end

      def validate
        build_slug if new_slug_needed?
        method = friendly_id_config.method
      rescue FriendlyId::BlankError
        return errors.add(method, "can't be blank")
      rescue FriendlyId::ReservedError
        return errors.add(method, "is reserved")
      end

    end
  end
end