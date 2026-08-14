require "helper"

class Chapters < ROM::Relation[:sql]
  schema(:chapters, infer: true)
  use :friendly_id, base: :title, use: %i[scoped], scope: :book_id
end

class SequentialChapters < ROM::Relation[:sql]
  schema(:chapters, as: :sequential_chapters, infer: true)
  use :friendly_id, base: :title, use: %i[scoped sequentially_slugged], scope: :book_id
end

class HistoricChapters < ROM::Relation[:sql]
  schema(:chapters, as: :historic_chapters, infer: true)
  use :friendly_id,
    base: :title,
    use: %i[scoped history],
    scope: :book_id,
    sluggable_type: "Chapter"
end

class ScopedSlugs < ROM::Relation[:sql]
  schema(:friendly_id_slugs, infer: true)
end

# `:scope` takes a list, which both the `where` chain and the serialized scope
# written to the history table have to cope with.
class Lessons < ROM::Relation[:sql]
  schema(:lessons, infer: true)
  use :friendly_id, base: :title, use: %i[scoped], scope: %i[course_id unit_id]
end

class HistoricLessons < ROM::Relation[:sql]
  schema(:lessons, as: :historic_lessons, infer: true)
  use :friendly_id,
    base: :title,
    use: %i[scoped history],
    scope: %i[course_id unit_id],
    sluggable_type: "Lesson"
end

class ChapterRepo < ROM::Repository[:chapters]
  include FriendlyId::Rom::Repo
end

class SequentialChapterRepo < ROM::Repository[:sequential_chapters]
  include FriendlyId::Rom::Repo
end

class HistoricChapterRepo < ROM::Repository[:historic_chapters]
  include FriendlyId::Rom::Repo
end

class LessonRepo < ROM::Repository[:lessons]
  include FriendlyId::Rom::Repo
end

class HistoricLessonRepo < ROM::Repository[:historic_lessons]
  include FriendlyId::Rom::Repo
end

class RomScopedTest < TestCaseClass
  def setup
    @rom = FriendlyId::Test::Rom.container(:scoped) do |config|
      config.register_relation(Chapters)
      config.register_relation(SequentialChapters)
      config.register_relation(HistoricChapters)
      config.register_relation(ScopedSlugs)
      config.register_relation(Lessons)
      config.register_relation(HistoricLessons)
    end
    FriendlyId::Test::Rom.clean!(:scoped)
    @chapters = ChapterRepo.new(@rom)
    @sequential = SequentialChapterRepo.new(@rom)
    @historic = HistoricChapterRepo.new(@rom)
    @lessons = LessonRepo.new(@rom)
    @historic_lessons = HistoricLessonRepo.new(@rom)
  end

  test "allows the same slug in different scopes" do
    one = @chapters.create_with_slug(title: "Introduction", book_id: 1)
    two = @chapters.create_with_slug(title: "Introduction", book_id: 2)

    assert_equal "introduction", one.slug
    assert_equal "introduction", two.slug
  end

  test "does not allow the same slug within one scope" do
    @chapters.create_with_slug(title: "Introduction", book_id: 1)
    other = @chapters.create_with_slug(title: "Introduction", book_id: 1)

    refute_equal "introduction", other.slug
  end

  test "sequences within the scope, not globally" do
    @sequential.create_with_slug(title: "Introduction", book_id: 1)
    @sequential.create_with_slug(title: "Introduction", book_id: 1)
    third = @sequential.create_with_slug(title: "Introduction", book_id: 2)

    # Book 1 is now on -2; book 2 has never seen this slug.
    assert_equal "introduction", third.slug
    assert_equal "introduction-3", @sequential.create_with_slug(title: "Introduction", book_id: 1).slug
  end

  test "a record does not conflict with itself on regeneration" do
    chapter = @chapters.create_with_slug(title: "Introduction", book_id: 1)
    updated = @chapters.update_with_slug(chapter.id, slug: nil)

    assert_equal "introduction", updated.slug
  end

  # The scope value comes from the merged attributes, or moving a record between
  # scopes checks conflicts against the old one.
  test "uses the updated scope value when regenerating" do
    @chapters.create_with_slug(title: "Introduction", book_id: 2)
    chapter = @chapters.create_with_slug(title: "Introduction", book_id: 1)

    moved = @chapters.update_with_slug(chapter.id, book_id: 2, slug: nil)

    refute_equal "introduction", moved.slug
  end

  test "requires a :scope option" do
    error = assert_raises(FriendlyId::ConfigurationError) do
      FriendlyId::Rom::Configuration.new(base: :title, use: [:scoped])
    end
    assert_match(/needs a :scope option/, error.message)
    assert_match(/not an association name/, error.message)
  end

  test "rejects a :scope option without the addon" do
    error = assert_raises(FriendlyId::ConfigurationError) do
      FriendlyId::Rom::Configuration.new(base: :title, scope: :book_id)
    end
    assert_match(/without the :scoped addon/, error.message)
  end

  test "serialises the scope for the history table" do
    chapter = @historic.create_with_slug(title: "Introduction", book_id: 7)
    rows = @rom.relations[:friendly_id_slugs]

    assert_equal ["book_id:7"], rows.where(sluggable_id: chapter.id).pluck(:scope)
  end

  test "history conflicts are scoped too" do
    one = @historic.create_with_slug(title: "Introduction", book_id: 1)
    @historic.update_with_slug(one.id, title: "Renamed", slug: nil)

    two = @historic.create_with_slug(title: "Introduction", book_id: 2)

    assert_equal "introduction", two.slug
  end

  test "a retired slug is still taken within its own scope" do
    one = @historic.create_with_slug(title: "Introduction", book_id: 1)
    @historic.update_with_slug(one.id, title: "Renamed", slug: nil)

    other = @historic.create_with_slug(title: "Introduction", book_id: 1)

    refute_equal "introduction", other.slug
  end

  test "every scope column has to differ for a slug to repeat" do
    first = @lessons.create_with_slug(title: "Overview", course_id: 1, unit_id: 1)
    other_course = @lessons.create_with_slug(title: "Overview", course_id: 2, unit_id: 1)
    other_unit = @lessons.create_with_slug(title: "Overview", course_id: 1, unit_id: 2)

    assert_equal %w[overview overview overview],
      [first.slug, other_course.slug, other_unit.slug]
  end

  test "matching on every scope column is a conflict" do
    @lessons.create_with_slug(title: "Overview", course_id: 1, unit_id: 1)
    same = @lessons.create_with_slug(title: "Overview", course_id: 1, unit_id: 1)

    refute_equal "overview", same.slug
  end

  test "a partial scope match does not narrow to the wrong records" do
    @lessons.create_with_slug(title: "Overview", course_id: 1, unit_id: 1)

    assert_equal "overview", @lessons.create_with_slug(title: "Overview", course_id: 1, unit_id: 9).slug
  end

  test "serializes every scope column, in a stable order" do
    lesson = @historic_lessons.create_with_slug(title: "Overview", course_id: 3, unit_id: 4)

    assert_equal ["course_id:3,unit_id:4"],
      @rom.relations[:friendly_id_slugs].where(sluggable_id: lesson.id).pluck(:scope)
  end

  # Sorted, so reordering the `scope:` array keeps history lookups matching.
  test "the serialized scope does not depend on the declared column order" do
    reversed = FriendlyId::Rom::Configuration.new(
      base: :title, use: %i[scoped], scope: %i[unit_id course_id]
    )

    assert_equal "course_id:3,unit_id:4",
      FriendlyId::Rom.serialized_scope(reversed, {course_id: 3, unit_id: 4})
  end

  test "history conflicts respect every scope column" do
    lesson = @historic_lessons.create_with_slug(title: "Overview", course_id: 1, unit_id: 1)
    @historic_lessons.update_with_slug(lesson.id, title: "Renamed", slug: nil)

    # Same course, different unit: a different scope, so the retired slug is free.
    assert_equal "overview",
      @historic_lessons.create_with_slug(title: "Overview", course_id: 1, unit_id: 2).slug

    # Same course and unit: taken.
    refute_equal "overview",
      @historic_lessons.create_with_slug(title: "Overview", course_id: 1, unit_id: 1).slug
  end
end
