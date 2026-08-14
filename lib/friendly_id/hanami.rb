# Hanami's persistence layer is ROM, and `Hanami::DB::Relation` and
# `Hanami::DB::Repo` are thin subclasses of `ROM::Relation[:sql]` and
# `ROM::Repository`. FriendlyId therefore targets ROM directly, and this file
# exists so that `require "friendly_id/hanami"` reads naturally in a Hanami app.
require "friendly_id/rom"
