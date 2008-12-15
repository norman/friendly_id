require File.dirname(__FILE__) + '/test_helper'

class SluggableTest < Test::Unit::TestCase

  fixtures :posts, :slugs

  def setup
    Post.friendly_id_options[:max_length] = FriendlyId::ClassMethods::DEFAULT_FRIENDLY_ID_OPTIONS[:max_length]
  end

  def test_post_should_generate_slug_text
   @post = Post.new(:name => "Test post", :content => "Test content")
   assert_equal "test-post", @post.slug_text
  end

  def test_should_create_post_with_slug
    @post = Post.create(:name => "Test post", :content => "Test content")
    assert_not_nil @post.slug
  end

  def test_finder_options_are_not_ignored
    assert_raises ActiveRecord::RecordNotFound do
      Post.find(slugs(:one).name, :conditions => "1 = 2")
    end
  end
  
  def test_to_param_for_unslugged_objects_should_return_a_string
    assert_equal String, posts(:without_slug).to_param.class
  end
  
  def test_to_param_for_slugged_objects_should_return_a_string
    assert_equal String, posts(:with_one_slug).to_param.class
  end

  def test_post_should_have_friendly_id_options
    assert_not_nil Post.friendly_id_options
  end

  def test_slug_should_not_have_friendly_id_options
    assert_raises NoMethodError do
      Slug.friendly_id_options
    end
  end

  def test_post_should_not_be_found_using_friendly_id_unless_it_really_was
    @post = Post.new
    assert !@post.found_using_friendly_id?
  end

  def test_posts_should_be_using_friendly_id_when_given_as_array
    @posts = Post.find([posts(:with_one_slug).friendly_id, posts(:with_two_slugs).friendly_id])
    assert @posts.all? { |post| post.found_using_friendly_id? }
  end

  def test_post_raises_active_record_not_found_when_not_all_records_found
    assert_raises(ActiveRecord::RecordNotFound) do
      Post.find([posts(:with_one_slug).slug.name, 'non-existant-slug-record'])
    end
  end

  def test_post_should_be_considered_found_by_numeric_id_as_default
    @post = Post.new
    assert @post.found_using_numeric_id?
  end

  def test_post_should_indicate_if_it_was_found_using_numeric_id
    @post = Post.find(posts(:with_two_slugs).id)
    assert @post.found_using_numeric_id?
  end

  def test_post_should_indicate_if_it_was_found_using_friendly_id
    @post = Post.find(posts(:with_two_slugs).slug.name)
    assert @post.found_using_friendly_id?
  end

  def test_post_should_indicate_if_it_was_found_using_outdated_friendly_id
    @post = Post.find(posts(:with_two_slugs).slugs.last.name)
    assert @post.found_using_outdated_friendly_id?
  end

  def test_should_indicate_there_is_a_better_id_if_found_by_numeric_id
    @post = Post.find(posts(:with_one_slug).id)
    assert @post.has_better_id?
  end

  def test_should_indicate_there_is_a_better_id_if_found_by_outdated_friendly_id
    @post = Post.find(posts(:with_two_slugs).slugs.last.name)
    assert @post.has_better_id?
  end

  def test_should_indicate_correct_best_id
    @post = Post.find(posts(:with_two_slugs).slug.name)
    assert !@post.has_better_id?
    assert slugs(:two_new).name, @post.slug.name
  end

  def test_should_strip_diactics_from_slug_if_configured_to_do_so
    Post.friendly_id_options[:strip_diacritics] = true
    @post = Post.new(:name => "¡FELIZ AÑO!")
    # Happy anus to you too
    assert_equal "feliz-ano", @post.slug_text
  end

  def test_should_not_strip_diactics_from_slug_unless_configured_to_do_so
    Post.friendly_id_options[:strip_diacritics] = false
    @post = Post.new(:name => "¡FELIZ AÑO!")
    assert_equal "feliz-año", @post.slug_text
  end

  def test_post_should_not_make_new_slug_if_name_is_unchanged
    posts(:with_one_slug).content = "Edited content"
    posts(:with_one_slug).save!
    assert_equal 1, posts(:with_one_slug).slugs.size
  end

  def test_post_should_make_new_slug_if_name_is_changed
    posts(:with_one_slug).name = "Edited name"
    posts(:with_one_slug).save!
    assert_equal 2, posts(:with_one_slug).slugs.size
  end

  def test_should_not_consider_substrings_as_duplicate_slugs
    @substring = slugs(:one).name[0, slugs(:one).name.length - 1]
    @post = Post.new(:name => @substring, :content => "stuff")
    assert_equal @substring, @post.slug_text
  end

  def test_should_increment_sequence_for_duplicate_slugs
    @post = Post.create!(:name => slugs(:one).name, :content => "stuff")
    assert_equal 2, @post.slug.sequence
  end

  def test_friendly_id_should_contain_sequence_unless_its_1
    @post = Post.create!(:name => slugs(:one).name, :content => "stuff")
    assert_equal "#{slugs(:one).name}--2", @post.friendly_id
  end


  def test_should_truncate_slugs_longer_than_maxlength
    Post.friendly_id_options[:max_length] = 10
    @post = Post.new(:name => "x" * 11, :content => "Test content")
    assert @post.slug_text.length <= Post.friendly_id_options[:max_length]
  end

  def test_should_ensure_truncated_slugs_that_collide_have_different_sequences
    Post.friendly_id_options[:max_length] = 2
    p = Post.create!(:name => "aaa")
    q = Post.create!(:name => "aaab")
    assert_not_equal p.friendly_id, q.friendly_id
    assert_equal p.slug.name, q.slug.name
    assert_not_equal p.slug.sequence, q.slug.sequence
  end

  def test_should_be_able_to_rename_back_to_old_friendly_id
    p = Post.create!(:name => "value")
    assert_equal "value", p.friendly_id
    p.name = "different value"
    p.save!
    p.reload
    assert_equal "different-value", p.friendly_id
    p.name = "value"
    assert p.save!
    p.reload
    assert_equal "value", p.friendly_id
  end

  def test_should_avoid_extention_collisions
    Post.create!(:name => "Post 2/4")
    assert Post.create!(:name => "Post")
    assert Post.create!(:name => "Post-2")
    assert Post.create!(:name => "Post-2")
    assert Post.create!(:name => "Post")
    assert Post.create!(:name => "Post-2-2")
    assert Post.create!(:name => "Post 2/4")
  end

  def test_slug_should_indicate_if_it_is_the_most_recent
    assert slugs(:two_new).is_most_recent?
  end

  def test_should_raise_error_if_friendly_id_is_blank
    assert_raises(FriendlyId::SlugGenerationError) do
      Post.create(:name => nil)
    end
  end

  def test_should_raise_error_if_normalized_friendly_id_becomes_blank
    assert_raises(FriendlyId::SlugGenerationError) do
      post = Post.create!(:name => "-.-")
    end
  end

  def test_raise_error_on_reseved_slugs
    assert_raises(FriendlyId::SlugGenerationError) do
      Post.create(:name => "new")
    end
  end

  def test_should_return_record_by_id
    post = Post.create!(:name => "New post")
    Post.create!(:name => "#{post.id.to_s} and some text")
    assert_equal post, Post.find(post.id)
  end

  def test_should_allow_eager_loading_slugs
    assert_nothing_raised do
      Post.find(slugs(:one).name, :include => :slugs)
    end

    assert_nothing_raised do
      Post.find([slugs(:one).name, slugs(:two_new).name], :include => :slugs)
    end
  end

end
