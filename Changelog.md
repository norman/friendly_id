# FriendlyId Changelog

We would like to think our many {file:Contributors contributors} for
suggestions, ideas and improvements to FriendlyId.

* Table of Contents
{:toc}

## 4.0.8 (NOT RELEASED YET)

* Avoid using deprecated `update_attribute` (Philip Arndt).

* Added set_friendly_id method to Globalize module (Norman Clarke).

* autoload FriendlyId::Slug; previously this class was not accessible from
  migrations unless required explicitly, which could cause some queries to
  unexpectedly fail (Norman Clarke).

* Fix Mocha load order (Mark Turner).

* Minor doc updates (Rob Yurkowski).

* Other miscellaneous refactorings and doc updates.

## 4.0.7 (2012-06-06)

* to_param just calls super when no friendly_id is present, to keep the model's
  default behavior. (Andrew White)

* FriendlyId can now properly sequence slugs that end in numbers even when a
  single dash is used as the separator (Tomás Arribas).

## 4.0.6 (2012-05-21)

* Fix nil return value from to_param when save fails because of validation errors (Tomás Arribas)
* Fix incorrect usage of i18n API (Vinicius Ferriani)
* Improve error handling in reserved module (Adrián Mugnolo and Github user "nolamesa")

## 4.0.5 (2012-04-28)

* Favor `includes` over `joins` in globalize to avoid read-only results (Jakub Wojtysiak)
* Fix globalize compatibility with results from dynamic finders (Chris Salzberg)


## 4.0.4 (2012-03-26)

* Fix globalize plugin to avoid issues with asset precompilation (Philip Arndt)


## 4.0.3 (2012-03-14)

* Fix escape for '%' and '_' on SQLite (Norman Clarke and Sergey Petrunin)
* Allow FriendlyId to be extended or included (Norman Clarke)
* Allow Configuration#use to accept a Module (Norman Clarke)
* Fix bugs with History module + STI (Norman Clarke and Sergey Petrunin)

## 4.0.2 (2012-03-12)

* Improved conflict handling and performance in History module (Erik Ogan and Thomas Shafer)
* Fixed bug that impeded using underscores as a sequence separator (Erik Ogan and Thomas Shafer)
* Minor documentation improvements (Norman Clarke)

## 4.0.1 (2012-02-29)

* Added support for Globalize 3 (Enrico Pilotto and Philip Arndt)
* Allow the scoped module to use multiple scopes (Ben Caldwell)
* Fixes for conflicting slugs in history module (Erik Ogan, Thomas Shafer, Evan Arnold)
* Fix for conflicting slugs when using STI (Danny van der Heiden, Diederick Lawson)
* Maintainence improvements (Norman Clarke, Philip Arndt, Thomas Darde, Lee Hambley)

## 4.0.0 (2011-12-27)

This is a complete rewrite of FriendlyId, and introduces a smaller, faster and
less ambitious codebase. The primary change is the relegation of external slugs
to an optional addon, and the adoption of what were formerly "cached slugs"
as the primary way of handling slugging.

## Older releases

Please see the 3.x branch.
