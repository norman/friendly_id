# FriendlyId Changelog

We would like to think our many {file:Contributors contributors} for
suggestions, ideas and improvements to FriendlyId.

* Table of Contents
{:toc}

## 2.3.5 (NOT RELEASED YET)

* Added allow_nil option (Andre Duffeck and Norman Clarke)

## 2.3.4 (2010-03-22)

* Made slugged status use the slug sequence. This fixes problems with #best?
  returning false when finding with a sequenced slug.
* Doc fixes. (Juan Schiwndt)
* Misc cleanups.

## 2.3.3 (2010-03-10)

* Fixed sequence regexp to grab all trailing digits. (Nash Kabbara)
* Block param now warns, not raises. (Kamal Fariz Mahyuddin)
* Misc doc fixes. (Kamal Fariz Mahyuddin)

## 2.3.2 (2010-02-14)

* Fixed finding by old slug when using cached slugs.
* Sequence separator parsing now correctly handles occurrences of the sequence
  separator string inside the friendly_id text (Johan Kok).
* Fixed missing quotes on table names in a few places (Brian Collins).


## 2.3.1 (2010-02-09)

* Fixed stack level too deep error on #strip_diacritics.


## 2.3.0 (2010-02-04)

This is a major update à la "Snow Leopard" that adds no new major features,
but significantly improves the underlying code. Most users should be able to
upgrade with no issues other than new deprecation messages appearing in the
logs.

If, however, you have monkey-patched FriendlyId, or are maintaining your own
fork, then this upgrade may causes issues.

**Changes:**

* Sequence separator can now be configured to something other than "--".
* New option to pass arguments to {FriendlyId::SlugString#approximate_ascii!},
  allowing custom approximations specific to German or Spanish.
* FriendlyId now queries against the cached_slug column, which improves performance.
* {FriendlyId::SlugString} class added, allowing finer-grained control over
  Unicode friendly_id strings.
* {FriendlyId::Configuration} class added, offering more flexible/hackable
  options.
* FriendlyId now raises subclasses of {FriendlyId::SlugGenerationError}
  depending on the error context.
* Simple models now correctly validate friendly_id length.
* Passing block into FriendlyId deprecated in favor of overriding
  the model's `normalize_friendly_id` method.
* Updating only the model's scope now also updates the slug.
* Major refactorings, cleanups and deprecations en route to the 3.0 release.

## 2.2.7 (2009-12-16)

* Fixed typo in Rake tasks which caused delete_old_slugs to fail. (Diego R.V.)

## 2.2.6 (2009-12-10)

* Made cached_slug automagic configuration occur outside of has_friendly_id.
  This was causing problems in code where the class is loaded before
  ActiveRecord has established its connection.
* Fixes for scope feature with Postgres (Ben Woosley)
* Migrated away from Hoe/Newgem for gem management.
* Made tests database-agnostic (Ben Woosley)

## 2.2.5 (2009-11-30)

* Fixed typo in config options (Steven Noble).

## 2.2.4 (2009-11-12)

* Fixed typo in post-install message.

## 2.2.3 (2009-11-12)

* Fixed some issues with gem load order under 1.8.x (closes GH Issue #20)
* Made sure friendly_id generator makes a lib/tasks directory (Josh Nichols)
* Finders now accept instances of ActiveRecord::Base, matching AR's behavior
  (Josh Nichols)
* SlugGenerationError now raise when a blank value is passed to
  strip_diacritics

## 2.2.2 (2009-10-26)

* Fixed Rake tasks creating duplicate slugs and not properly clearing cached
  slugs (closes GH issues #14 and #15)

## 2.2.1 (2009-10-23)

* slug cache now properly caches the slug sequence (closes GH issue #10)
* attr_protected is now only invoked on the cached_slug column if
  attr_accessible has not already been invoked. (closes GH issue #11)

## 2.2.0 (2009-10-19)

* Added slug caching, offers huge performance boost (Bruno Michel)
* Handle Unicode string length correctly (Mikhail Shirkov)
* Remove alias_method_chain in favor of super (Diego Carrion)

## 2.1.4 (2009-09-01)

* Fixed upgrade generator not installing rake tasks (Harry Love)
* Fixed handling of very large id's (Nathan Phelps)
* Fixed long index name on migration (Rob Ingram)

## 2.1.3 (2009-06-03)

* Always call #to_s on slug_text to allow objects such as DateTimes to be used
  for the friendly_id text. (reported by Jon Ng)

## 2.1.2 (2009-05-21)

* Non-slugged models now validate the friendly_id on save as well as create
  (Joe Van Dyk).
* Replaced Shoulda with Contest.

## 2.1.1 (2009-03-25)

* Fixed bug with find_some; if a record has old slugs, find_some will no
  longer return multiple copies of that record when finding by numerical ID.
  (Steve Luscher)
* Fixed bug with find_some: you can now find_some with an array of numerical
  IDs without an error being thrown. (Steve Luscher)

## 2.1.0 (2009-03-25)

* Ruby 1.9 compatibility.
* Removed dependency on ancient Unicode gem.

## 2.0.4 (2009-02-12)

* You can now pass in your own custom slug generation blocks while setting up
  friendly_id.

## 2.0.3 (2009-02-11)

* Fixed to_param returning an empty string for non-slugged models with a null
  friendly_id.

## 2.0.2 (2009-02-09)

* Made FriendlyId depend only on ActiveRecord. It should now be possible to
  use FriendlyId with Camping or any other codebase that uses AR.
* Overhauled creaky testing setup and switched to Shoulda.
* Made reserved words work for non-slugged models.

## 2.0.1 (2009-01-19)

* Fix infinite redirect bug when using .has_better_id? in your controllers
  (Sean Abrahams)


## 2.0.0 (2009-01-03)

* Support for scoped slugs (Norman Clarke)
* Support for UTF-8 friendly_ids (Norman Clarke)
* Can now be installed via Ruby Gems, or as a Rails plugin (Norman Clarke)
* Improved handling of non-unique slugs (Norman Clarke and Adrian Mugnolo)
* Shoulda macro (Josh Nichols)
* Various small bugfixes, cleanups and refactorings

## 1.0 (2008-12-11)

* Fixed bug that may return invalid records having similar id/names and using
  MySQL. (Emilio Tagua)
* Fixed slug generation to increment only numeric extension without modifying
  the name on duplicated slugs. (Emilio Tagua)

## 2008-10-31

* Fixed compatibility with Rails 2.0.x. (Norman Clarke)
* friendly_id::make_slugs update records in chunks of 1000 to avoid running
  out of memory with large datasets. (Tim Kadom)
* Fixed logic error with slug name collisions. Thanks to Tim Kadom for
  reporting this bug.

## 2008-10-22

* Reverted use of UTF8Handler - was causing errors for some people (Bence Nagy)
* Corrected find in case if a friendly_id begins with number (Bence Nagy)
* Added ability to reserve words from slugs (Adam Cigánek)

## 2008-10-09

* Moved "require"" for iconv to init.rb (Florian Aßmann)
* Removed "require" for Unicode, use Rails' handler instead (Florian Aßmann)
* Replaced some magic numbers with constants (Florian Aßmann)
* Don't overwrite find, alias_method_chain find_one and find_some instead
  (Florian Aßmann)
* Slugs behave more like ids now (Florian Aßmann)
* Can find by mixture of ids and slugs (Florian Aßmann)
* Reformatted code and comments (Florian Aßmann)
* Added support for Edge Rails' Inflector::parameterize (Norman Clarke)

## 0.5 (2008-08-25)

* Moved strip_diacritics into Slug for easier reuse/better organization.
* Put class methods inside class << self block. (Norman Clarke)

* Small change to allow friendly_id to work better with STI. (David Ramalho)

## 2008-07-14

* Improved slug generation for friendly id's with apostrophes. (Alistair Holt)
* Added support for namespaced models in Rakefile. (David Ramalho)

## 2008-06-23

* Cached most recent slug to improve performance (Emilio Tagua).

## 2008-06-10

* Added ability to find friendly_ids by array (Emilio Tagua)

## 2008-05-15

* Made friendly_id raise an error if slug method returns a blank value.

## 2008-05-12

* Added experimental Github gemspec.

## 2008-04-18

* Improved slug name collision avoidance.

## 2008-03-13

* Added :dependent => :destroy to slug relation, as suggested by Emilio Tagua.
* Fixed error when renaming a slugged item back to a previously used name.
* Incorporated documentation changes suggested by Jesse Crouch and Chris Nolan.

## 2008-02-07

* Applied patches from blog commenter "suntzu" to fix problem with model
  values were being overwritten.
* Applied patch from Dan Blue to make friendly_id no longer ignore options on
  ActiveRecordBase#find.
* Added call to options.assert_valid_keys in has_friendly_id. Thanks to W.
  Andrew Loe III for pointing out that this was missing.
