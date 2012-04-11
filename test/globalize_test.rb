# encoding: utf-8

require "helper"

class TranslatedArticle < ActiveRecord::Base
  translates :slug, :title
  extend FriendlyId
  friendly_id :title, :use => :globalize
end

class GlobalizeTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  test "friendly_id should find slug in current locale if locale is set, otherwise in default locale" do
    transaction do
      I18n.default_locale = :en
      article_en = I18n.with_locale(:en) { TranslatedArticle.create(:title => 'a title') }
      article_de = I18n.with_locale(:de) { TranslatedArticle.create(:title => 'titel') }

      I18n.with_locale(:de) {
        assert_equal TranslatedArticle.find("titel"), article_de
        assert_equal TranslatedArticle.find("a-title"), article_en
      }
    end
  end

  # https://github.com/svenfuchs/globalize3/blob/master/test/globalize3/dynamic_finders_test.rb#L101
  # see: https://github.com/svenfuchs/globalize3/issues/100
  test "record returned by friendly_id should have all translations" do
    transaction do
      I18n.with_locale(:en) do
        article = TranslatedArticle.create(:title => 'a title')
        Globalize.with_locale(:ja) { article.update_attributes(:title => 'タイトル') }
        article_by_friendly_id = TranslatedArticle.find("a-title")
        assert_equal article.translations, article_by_friendly_id.translations
      end
    end
  end

end
