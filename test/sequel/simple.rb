module FriendlyId
  module Test
    module Sequel

      module Simple

        def klass
          @klass ||= User
        end
        
        def other_class
          @other_class ||= Post
        end

        def instance
          @instance ||= klass.send(create_method, :name => "hello world")
        end

      end
    end
  end
end