module FriendlyId

  # A Shoulda[http://www.thoughtbot.com/projects/shoulda/] macros for testing
  # models using FriendlyId.
  module ShouldaMacros

    # Ensure that a model is using FriendlyId.
    def self.should_have_friendly_id(column, options = {})

      options.assert_valid_keys(:use_slug)
      klass = self.model_class

      should "have friendly id for #{method}" do
        assert_respond_to klass, :friendly_id_options,
          "#{klass} does not respond to friendly_id_options"
        assert_equal column, klass.friendly_id_options[:method]
      end

      if options[:use_slug]
        should "include/extend friendly_id's sluggable modules" do
          assert klass.extended_by.include?(FriendlyId::SluggableClassMethods),
            "#{klass} does not extend FriendlyId::SluggableClassMethods"
          assert klass.include?(FriendlyId::SluggableInstanceMethods),
            "#{klass} not include FriendlyId::SluggableInstanceMethods"
        end
      else
        should "include/extend friendly_id's non-sluggable modules" do
          assert klass.extended_by.include?(FriendlyId::NonSluggableClassMethods),
            "#{klass} does not extend FriendlyId::NonSluggableClassMethods"
          assert klass.include?(FriendlyId::NonSluggableInstanceMethods),
            "#{klass} not include FriendlyId::NonSluggableInstanceMethods"
        end
      end
    end
  end
end