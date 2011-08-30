require File.expand_path("../helper", __FILE__)

class DefaultScopeTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => :slugged
    default_scope :order => 'id ASC', :conditions => { :active => true }
  end
  
  test "friendly_id should sequence correctly a default_scoped ordered table" do
    Journalist.destroy_all
    Journalist.create!({ :name => 'I\'m unique', :active => true })
    Journalist.create!({ :name => 'I\'m unique', :active => true })
    begin
      Journalist.create!({ :name => 'I\'m unique', :active => true })
    rescue
      flunk "expected no errors but got #{$!}"
    end
  end
  
  test "friendly_id should sequence correctly a default_scoped scoped table" do
    Journalist.destroy_all
    Journalist.create!({ :name => 'I\'m unique', :active => false })
    begin
      Journalist.create!({ :name => 'I\'m unique', :active => true })
    rescue
      flunk "expected no errors but got #{$!}"
    end
  end
end
