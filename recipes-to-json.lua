#!/usr/bin/env lua

-- convert factorio recipe.lua files to json

json = require("json")

data = {}

-- the factorio lua files call this method, so we have to implement it

function data.extend (target, new_data)
	-- append rows from new_data to target
	-- TODO: handle named table rows
	for i=1,#new_data do
        target[#target+1] = new_data[i]
    end
end

-- TODO: enumerate lua file list from directory
dofile("base/prototypes/recipe/ammo.lua")
dofile("base/prototypes/recipe/demo-furnace-recipe.lua")
dofile("base/prototypes/recipe/demo-turret.lua")
dofile("base/prototypes/recipe/fluid-recipe.lua")
dofile("base/prototypes/recipe/inserter.lua")
dofile("base/prototypes/recipe/recipe.lua")
dofile("base/prototypes/recipe/turret.lua")
dofile("base/prototypes/recipe/capsule.lua")
dofile("base/prototypes/recipe/demo-recipe.lua")
dofile("base/prototypes/recipe/equipment.lua")
dofile("base/prototypes/recipe/furnace-recipe.lua")
dofile("base/prototypes/recipe/module.lua")

-- TODO: possibly pretty-print the json, with indenting and newlines
print (json.encode( data ))
