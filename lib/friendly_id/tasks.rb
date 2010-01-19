module FriendlyId
  class Tasks
    
    class << self

      def make_slugs(klass, options = {})
        klass = parse_class_name(klass)
        validate_uses_slugs(klass)
        options = {:limit => 100, :include => :slugs, :conditions => "slugs.id IS NULL"}.merge(options)
        while records = klass.find(:all, options) do
          break if records.size == 0
          records.each do |r|
            r.save!
            yield(r) if block_given?
          end
        end
      end

      def delete_slugs_for(klass)
        klass = parse_class_name(klass)
        cache_column = klass.friendly_id_config.cache_column
        validate_uses_slugs(klass)
        FriendlyId::Adapters::ActiveRecord::Slug.destroy_all(["sluggable_type = ?", klass.to_s])
        if cache_column
          klass.update_all("#{cache_column} = NULL")
        end
      end

      def delete_old_slugs(days = nil, class_name = nil)
        days = days.blank? ? 45 : days.to_i
        klass = class_name.blank? ? nil : parse_class_name(class_name.to_s)
        conditions = ["created_at < ?", DateTime.now - days.days]
        if klass
          conditions[0] << " AND sluggable_type = ?"
          conditions << klass.to_s
        end
        slugs = FriendlyId::Adapters::ActiveRecord::Slug.find :all, :conditions => conditions
        slugs.each { |s| s.destroy unless s.is_most_recent? }
      end

      def parse_class_name(class_name)
        class_name.to_s.classify.constantize
      end

      private

      def validate_uses_slugs(klass)
        raise "Class '%s' doesn't use slugs" % klass.to_s unless klass.friendly_id_config.use_slug?
      end

    end
  end
end
