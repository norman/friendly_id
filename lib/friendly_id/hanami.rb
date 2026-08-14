# Hanami's persistence layer is ROM, and `Hanami::DB::Relation` and
# `Hanami::DB::Repo` are thin subclasses of `ROM::Relation[:sql]` and
# `ROM::Repository`. FriendlyId therefore targets ROM directly, and this file
# exists so that `require "friendly_id/hanami"` reads naturally in a Hanami app.
require "friendly_id/rom"

# When this file is loaded by the `hanami` executable rather than by a booting
# application, `Hanami::CLI` is already defined and we can add our generator to
# it. Guarded so that requiring this file in a normal app pulls in no CLI code.
require "friendly_id/hanami/cli" if defined?(::Hanami::CLI)
