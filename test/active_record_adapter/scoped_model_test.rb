require File.expand_path("../ar_test_helper", __FILE__)

module FriendlyId
  module Test

    class ScopedModelTest < ::Test::Unit::TestCase

      def setup
        @user      = User.create!(:name => "john")
        @house     = House.create!(:name => "123 Main", :user => @user)
        @usa       = Country.create!(:name => "USA")
        @canada    = Country.create!(:name => "Canada")
        @resident  = Resident.create!(:name => "John Smith", :country => @usa)
        @resident2 = Resident.create!(:name => "John Smith", :country => @canada)
        @resident3 = Resident.create!(:name => "Jim Beam", :country => @canada)
        @owner     = Company.create!(:name => "Acme Events")
        @site      = Site.create!(:name => "Downtown Venue", :owner => @owner)
      end

      def teardown
        Resident.delete_all
        Country.delete_all
        User.delete_all
        House.delete_all
        Slug.delete_all
        Tourist.delete_all
      end

      test "As of 3.2.0, should raise error if :scope option is passed" do
        assert_raise(RuntimeError) do
          Tourist.find("hello", :scope => "usa")
        end
      end

      test "should not use cached slug column with scopes" do
        @tourist  = Tourist.create!(:name => "John Smith", :country => @usa)
        @tourist2 = Tourist.create!(:name => "John Smith", :country => @canada)
        assert_equal @canada, @canada.residents.find(@tourist2.friendly_id).country
      end

      test "a slugged model should auto-detect that it is being used as a parent scope" do
        assert_equal [Resident], Country.friendly_id_config.child_scopes
      end

      test "a slugged model should update its child model's scopes when its friendly_id changes" do
        @usa.update_attributes(:name => "United States")
        assert_equal "united-states", @usa.to_param
        assert_equal "united-states", @resident.slugs(true).first.scope
        assert_equal 2, @resident.slugs(true).count
        assert_equal "usa", @resident.slugs(true).second.scope
      end

      test "a non-slugged model should auto-detect that it is being used as a parent scope" do
        assert_equal [House], User.friendly_id_config.child_scopes
      end

      test "should update the slug when the scope changes" do
        @resident.update_attributes! :country => Country.create!(:name => "Argentina")
        assert_equal "argentina", @resident.slugs(true).first.scope
      end

      test "updating only the scope should not append sequence to friendly_id" do
        old_friendly_id = @resident.friendly_id
        @resident.update_attributes! :country => Country.create!(:name => "Argentina")
        assert_equal old_friendly_id, @resident.friendly_id
      end

      test "updating the scope should increment sequence to avoid conflicts" do
        old_friendly_id = @resident.friendly_id
        @resident.update_attributes! :country => @canada
        assert_equal "#{old_friendly_id}--2", @resident.friendly_id
        assert_equal "canada", @resident.slugs(true).first.scope
      end

      test "a non-slugged model should update its child model's scopes when its friendly_id changes" do
        @user.update_attributes(:name => "jack")
        assert_equal "jack", @user.to_param
        assert_equal "jack", @house.slugs(true).first.scope
      end

      test "should should not show the scope in the friendly_id" do
        assert_equal "john-smith", @resident.friendly_id
        assert_equal "john-smith", @resident2.friendly_id
      end

      test "should find all scoped records without scope" do
        name, sequence = @resident.friendly_id.parse_friendly_id
        assert_equal 2, Resident.find(:all, :joins => :slugs, :conditions => {
            :slugs => {:name => name, :sequence => sequence}}).size
      end

      test "should find a scoped record by friendly_id" do
        assert Resident.find(@resident.friendly_id)
      end

      test "should find a scope record as a relation member" do
        assert_equal @resident, @usa.residents.find("john-smith")
        assert_equal @resident2, @canada.residents.find("john-smith")
      end

      test "should find a single scoped record using slug conditions" do
        assert_equal @resident, Resident.find(@resident.friendly_id, :include => :slugs,
          :conditions => {:slugs => {:scope => @resident.country.to_param}})
      end

      test "should update the sluggable field when a polymorphic relationship exists" do
        @site.update_attributes(:name => "Uptown Venue")
        assert_equal "Uptown Venue", @site.name
      end

      test "should not assume that AR's reflect_on_all_associations with return AR classes" do
        reflections = Resident.reflect_on_all_associations
        reflections << Struct.new("Dummy", :options, :klass).new(:options => [], :klass => Struct)
        Resident.expects(:reflect_on_all_associations).returns(reflections)
        assert_nothing_raised do
          Resident.friendly_id_config.send(:associated_friendly_classes)
        end
      end
    end
  end
end