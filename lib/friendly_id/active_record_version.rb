module FriendlyId

  class ActiveRecordVersion
    class << self
      def gt_than_5?
        return true if ActiveRecord::VERSION::MAJOR >= 5
        false
      end
      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]" if gt_than_5? 
      end
    end
  end
  
end