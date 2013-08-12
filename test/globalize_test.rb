# encoding: utf-8
require 'globalize3'
require "helper"

class TranslatedArticle < ActiveRecord::Base
  translates :slug, :title
  extend FriendlyId
  friendly_id :title, :use => :globalize
end

class GlobalizeTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  def setup
    I18n.locale = :en
  end

  test "should find slug in current locale if locale is set, otherwise in default locale" do
    transaction do
      I18n.default_locale = :en
      article_en = I18n.with_locale(:en) { TranslatedArticle.create(:title => 'a title') }
      article_de = I18n.with_locale(:de) { TranslatedArticle.create(:title => 'titel') }

      I18n.with_locale(:de) {
        assert_equal TranslatedArticle.friendly.find("titel"), article_de
        assert_equal TranslatedArticle.friendly.find("a-title"), article_en
      }
    end
  end

  test "should set friendly id for locale" do
    transaction do
      article = TranslatedArticle.create!(:title => "War and Peace")
      article.set_friendly_id("Guerra y paz", :es)
      article.save!
      TranslatedArticle.friendly.find('war-and-peace')
      I18n.with_locale(:es) { assert_equal "guerra-y-paz", found_article.friendly_id }
      I18n.with_locale(:en) { assert_equal "war-and-peace", found_article.friendly_id }
    end
  end

  # https://github.com/svenfuchs/globalize3/blob/master/test/globalize3/dynamic_finders_test.rb#L101
  # see: https://github.com/svenfuchs/globalize3/issues/100
  test "record returned by friendly_id should have all translations" do
    transaction do
      I18n.with_locale(:en) do
        article = TranslatedArticle.create(:title => 'a title')
        Globalize.with_locale(:ja) { article.update_attributes(:title => 'タイトル') }
        article_by_friendly_id = TranslatedArticle.friendly.find("a-title")
        article.translations.each do |translation|
          assert_includes article_by_friendly_id.translations, translation
        end
      end
    end
  end

end
