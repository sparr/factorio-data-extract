#!/usr/bin/perl -p

# convert factorio recipe.lua files to json

# expects to be fed a .lua file that looks like this:
# data:extend(
# {
#   {
#     type = "recipe",
#     name = "player-port",
#     enabled = "false",
#     ingredients =
#     {
#       {"electronic-circuit", 10},
#       {"iron-gear-wheel", 5},
#       {"iron-plate", 1 }
#     },
#     result = "player-port"
#   },
#   {
#     type = "recipe",
#     name = "fast-transport-belt",
#     enabled = "false",
#     ingredients =
#     {
#       {"iron-gear-wheel", 5},
#       {"basic-transport-belt", 1}
#     },
#     result = "fast-transport-belt"
#   }
# }


# TODO: find a solution for trailing commas inside arrays

# TODO: handle whole file instead of line-by-line, for better bracket matching

s/^data:extend.$//g;
s/^\)$//g;

s/([^ ]*) =/"\1":/g;
s/(?<!^  ){/[/g;
s/(?<!^  )}/]/g;
