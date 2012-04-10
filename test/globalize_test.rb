# encoding: utf-8

require "helper"

class TranslatedArticle < ActiveRecord::Base
  translates :slug, :title
  extend FriendlyId
  friendly_id :title, :use => :globalize
end

class GlobalizeTest < MiniTest::Unit::TestCase

  # https://github.com/svenfuchs/globalize3/blob/master/test/globalize3/dynamic_finders_test.rb#L101
  # see: https://github.com/svenfuchs/globalize3/issues/100
  test "record returned by friendly_id should have all translations" do
    I18n.locale = :en
    article = TranslatedArticle.create(:title => 'a title')
    Globalize.with_locale(:ja) { article.update_attributes(:title => 'タイトル') }
    article_by_friendly_id = TranslatedArticle.find("a-title")
    assert_equal article.translations, article_by_friendly_id.translations
  end

end
