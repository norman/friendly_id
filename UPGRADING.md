## Articles

* [Migrating an ad-hoc URL slug system to FriendlyId](http://olivierlacan.com/posts/migrating-an-ad-hoc-url-slug-system-to-friendly-id/)
* [Pretty URLs with FriendlyId](http://railscasts.com/episodes/314-pretty-urls-with-friendlyid)

## Docs

The most current docs from the master branch can always be found
[here](http://norman.github.io/friendly_id).

Docs for older versions are also available:

* [5.0](http://norman.github.io/friendly_id/5.0/)
* [4.0](http://norman.github.io/friendly_id/4.0/)
* [3.3](http://norman.github.io/friendly_id/3.3/)
* [2.3](http://norman.github.io/friendly_id/2.3/)

## What Changed in Version 6.0

### Supported versions

6.0 requires **Ruby >= 3.1** and **Rails >= 7.1**. Support for Rails 6.0, 6.1 and
7.0, and for Ruby 2.7 and 3.0, is dropped.

Hanami users additionally need Ruby >= 3.3, which is Hanami 3.0's own floor. The
ROM adapter itself runs on Ruby 3.1 for plain ROM and Sequel applications.

6.0 makes FriendlyId's core independent of any ORM so that it can support more
than one, and adds an adapter for ROM, the persistence layer used by Hanami 3.0.

**Existing Rails applications should need no code changes, and no slug will
change.** The Active Record adapter still normalizes slugs with Active Support's
`String#parameterize`, exactly as every previous version has.

### FriendlyId no longer declares a runtime dependency on Active Record

This is the one change that can break an install rather than an application. If
your Gemfile relied on FriendlyId to pull in Active Record for you, name it
yourself:

```ruby
gem "activerecord"
gem "friendly_id", "~> 6.0"
```

Rails applications already depend on Active Record through Rails, so this affects
almost nobody.

`require "friendly_id"` still loads the Active Record adapter whenever Active
Record is available. You can also be explicit:

```ruby
require "friendly_id/active_record"
```

### Internal files moved

The ORM-agnostic classes moved into `lib/friendly_id/core/`. Constant names are
unchanged, so `FriendlyId::Candidates`, `FriendlyId::Configuration`,
`FriendlyId::SlugGenerator` and the addon modules such as `FriendlyId::Slugged`
all still resolve. Only code doing `require "friendly_id/candidates"` and similar
on internal files needs updating, to `require "friendly_id/core/candidates"`.

### `Object#friendly_id?` is deprecated

Use `FriendlyId.friendly_id?(value)` and `FriendlyId.unfriendly_id?(value)`
instead, which answer identically without patching anything. FriendlyId itself
now uses only those.

On Rails the patch is still installed and still works, and is scheduled for
removal in 7.0. What has changed in 6.0 is *who* installs it: it now comes from
the Active Record adapter rather than from core, so applications on Hanami, ROM
or any future adapter never get `Object#friendly_id?`, `Object#unfriendly_id?`,
or the accompanying patches on `Array`, `Hash`, `Numeric`, `Symbol`, `NilClass`,
`TrueClass` and `FalseClass`.

This only affects you if you were calling `some_object.friendly_id?` in a
non-Rails application, which was not previously possible, or if you
`require "friendly_id/core"` directly and expected the patch. `FriendlyId.mark_as_unfriendly`
is unchanged and remains available in core for marking your own classes.

### New: normalizer objects

`normalize_friendly_id` remains the primary and fully supported way to control
slug generation. Alongside it there are now normalizer objects:

* `FriendlyId::Normalizers::ActiveSupport` wraps `String#parameterize` and is what
  the Active Record adapter always uses.
* `FriendlyId::Normalizers::Babosa` wraps [babosa](https://github.com/norman/babosa),
  which has no dependencies of its own and ships transliteration tables for many
  non-Latin scripts. It is the default for the ROM adapter.

FriendlyId never picks a normalizer based on which gems happen to be installed,
because that would let a change in your bundle silently rewrite your URLs. Note
that babosa is **not** a drop-in replacement for `parameterize`: it deletes "."
where Active Support converts it to the separator, so `"3.14159"` normalizes to
`"314159"` rather than `"3-14159"`.

### New: Hanami and ROM support

See the [README](README.md). The first release supports `:slugged`, `:finders`,
`:sequentially_slugged`, `:reserved`, `:history`, `:scoped` and `:simple_i18n` --
that is, every addon the Active Record adapter has.

Three of them need a little more than their Active Record counterparts, because
ROM has no callbacks and no model classes:

* **`:history`** stores retired slugs in a `friendly_id_slugs` table. Run
  `hanami generate friendly_id` to get the migration and the relation, then
  `hanami db migrate`. Because the table is polymorphic, `sluggable_type`
  defaults to the relation name (`"posts"`); set `sluggable_type: "Post"` to
  share the table with an Active Record application. Deleting a record is
  `delete_with_slug`, which is the counterpart of `dependent: :destroy` -- a
  foreign key cannot do this job, since one key would constrain every row in the
  table including rows belonging to other relations.
* **`:scoped`** takes the column itself rather than an association name:
  `scope: :author_id`, not `scope: :author`. Active Record infers the foreign key
  by reflection, which ROM has no equivalent of, and naming the column is clearer
  anyway.
* **`:simple_i18n`** takes its locale from a configurable source, defaulting to
  the `I18n` module. **Hanami users must pass `i18n: Hanami.app["i18n"]`**,
  because Hanami keeps each slice's locale in a thread-local and deliberately
  does not track the global `I18n.locale`. Without it every slug would be written
  to the default locale's column.

`update_with_slug` follows the same rule as the Active Record adapter: the slug is
regenerated only when it is nil, so editing a title leaves the existing slug in
place. Pass `slug: nil` to ask for a new one. Slugs are public URLs, and
regenerating one on every title edit breaks every link to the record.

### New: error classes

Errors FriendlyId raises deliberately now descend from `FriendlyId::Error`, which
descends from `StandardError` and so is caught by a plain `rescue => e`.

## What Changed in Version 5.1

5.1 is a bugfix release, but bumps the minor version because some applications may be dependent
on the previously buggy behavior. The changes include:

* Blank strings can no longer be used as slugs.
* When the first slug candidate is rejected because it is reserved, additional candidates will
  now be considered before marking the record as invalid.
* The `:finders` module is now compatible with Rails 4.2.

## What Changed in Version 5.0

As of version 5.0, FriendlyId uses [semantic versioning](http://semver.org/). Therefore, as you might
infer from the version number, 5.0 introduces changes incompatible with 4.0.

The most important changes are:

* Finders are no longer overridden by default. If you want to do friendly finds,
  you must do `Model.friendly.find` rather than `Model.find`. You can however
  restore FriendlyId 4-style finders by using the `:finders` addon:

  ```ruby
  friendly_id :foo, use: :slugged # you must do MyClass.friendly.find('bar')
  # or...
  friendly_id :foo, use: [:slugged, :finders] # you can now do MyClass.find('bar')
  ```
* A new "candidates" functionality which makes it easy to set up a list of
  alternate slugs that can be used to uniquely distinguish records, rather than
  appending a sequence. For example:

  ```ruby
  class Restaurant < ActiveRecord::Base
    extend FriendlyId
    friendly_id :slug_candidates, use: :slugged

    # Try building a slug based on the following fields in
    # increasing order of specificity.
    def slug_candidates
      [
        :name,
        [:name, :city],
        [:name, :street, :city],
        [:name, :street_number, :street, :city]
      ]
    end
  end
  ```
* Now that candidates have been added, FriendlyId no longer uses a numeric
  sequence to differentiate conflicting slug, but rather a UUID (e.g. something
  like `2bc08962-b3dd-4f29-b2e6-244710c86106`). This makes the
  codebase simpler and more reliable when running concurrently, at the expense
  of uglier ids being generated when there are conflicts.
* The default sequence separator has been changed from two dashes to one dash.
* Slugs are no longer regenerated when a record is saved. If you want to regenerate
  a slug, you must explicitly set the slug column to nil:

  ```ruby
  restaurant.friendly_id # joes-diner
  restaurant.name = "The Plaza Diner"
  restaurant.save!
  restaurant.friendly_id # joes-diner
  restaurant.slug = nil
  restaurant.save!
  restaurant.friendly_id # the-plaza-diner
  ```

  You can restore some of the old behavior by overriding the
  `should_generate_new_friendly_id?` method.
* The `friendly_id` Rails generator now generates an initializer showing you
  how to do some common global configuration.
* The Globalize plugin has moved to a [separate gem](https://github.com/norman/friendly_id-globalize) (currently in alpha).
* The `:reserved` module no longer includes any default reserved words.
  Previously it blocked "edit" and "new" everywhere. The default word list has
  been moved to `config/initializers/friendly_id.rb` and now includes many more
  words.
* The `:history` and `:scoped` addons can now be used together.
* Since it now requires Rails 4, FriendlyId also now requires Ruby 1.9.3 or
  higher.

## Upgrading from FriendlyId 4.0

Run `rails generate friendly_id --skip-migration` and edit the initializer
generated in `config/initializers/friendly_id.rb`. This file contains notes
describing how to restore (or not) some of the defaults from FriendlyId 4.0.

If you want to use the `:history` and `:scoped` addons together, you must add a
`:scope` column to your friendly_id_slugs table and replace the unique index on
`:slug` and `:sluggable_type` with a unique index on those two columns, plus
the new `:scope` column.

A migration like this should be sufficient:

```ruby
add_column   :friendly_id_slugs, :scope, :string
remove_index :friendly_id_slugs, [:slug, :sluggable_type]
add_index    :friendly_id_slugs, [:slug, :sluggable_type]
add_index    :friendly_id_slugs, [:slug, :sluggable_type, :scope], unique: true
```
