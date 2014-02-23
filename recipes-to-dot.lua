#!/usr/bin/env lua

-- convert factorio recipe.lua files to DOT
-- This script originally authored by Clarence "sparr" Risher in 2014
-- Licensed GPL v3, CC-BY-SA, or CC-BY-NC
-- https://en.wikipedia.org/wiki/DOT_(graph_description_language)

include_natural_resources_node = false
render_item_names = false

node_options = {
    -- size is specified in inches, see graph_options.dpi for reference
    fixedsize='true',
    width='1',
    height='1',
    fontsize=20,
    labelloc='b',
    shape='record',
    penwidth=0,
    -- margin=0.5,
}
edge_options = {
	-- tailport='s',
	-- headport='n',
    fontsize=20,
    labeldistance=1.5,
    penwidth=2,
}
graph_options = {
    -- some DOT measurements are in pixels, some in inches
    dpi=32,
    -- modes: major, KK, hier, ipsep, spring, maxent
    mode='hier',
    -- models: circuit, subset, mds
    model='subset',
    overlap='prism',
    -- packMode='node',
    -- ratio=0.75,
    sep='+32',
    -- splines: spline, line, ortho, polyline, curved
    splines='spline',
    levelsgap=10000,
    concentrate='false',
}
if(include_natural_resources_node) then
	graph_options.root="natural_resources"
end

-- which nodes should be linked from the fake root "Natural Resources" node?
natural_resources = {
    'iron-ore',
    'copper-ore',
    'coal',
    'crude-oil',
    'raw-wood',
    'stone',
    'water'
}

-- skip these recipes, for reasons including edge duplication
skip_recipes = {
    advanced_oil_processing=true, -- same results as basic-oil-processing if we ignore quantity
}

skip_items = {
	biter_spawner=true,
	computer=true,
	raw_fish=true,
	coin=true,
	small_worm_turret=true,
	medium_worm_turret=true,
}

function serialize_options (options)
	if(options==nil) then
		return ''
	end
    output_array = {}
    for option,value in pairs(options) do
        table.insert(output_array, option .. '="' .. value .. '"')
    end
    return ' ' .. table.concat(output_array, ' ') .. ' ';
end

-- open the digraph element of the dot file
print("digraph factorio_recipe_tree {")

-- set options for all entities
print("  node [" .. serialize_options(node_options) .. "];")
print("  edge [" .. serialize_options(edge_options) .. "];")
print("  graph [" .. serialize_options(graph_options) .. "];")


-- http://www.wowwiki.com/USERAPI_StringHash
function StringHash(text)
  local counter = 1
  local len = string.len(text)
  for i = 1, len, 3 do 
    counter = math.fmod(counter*8161, 4294967279) +  -- 2^32 - 17: Prime!
  	  (string.byte(text,i)*16776193) +
  	  ((string.byte(text,i+1) or (len-i+256))*8372226) +
  	  ((string.byte(text,i+2) or (len-i+256))*3932164)
  end
  return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

function color_from_name (name)
	hash = StringHash(name)
	return ((hash%1000)/1000) .. " " .. ((math.floor(hash/1000)%500)/1000+0.5) .. " " .. (0.5-(math.floor(hash/500000)%500)/1000+0.5)
end

-- all three parameters are strings
-- result and ingredient probably have dashes, replace with underscores
-- "ingredient -> result"
function print_graph_link (result, ingredient, quantity, attributes)
    print("  "..
    string.gsub(ingredient,"-","_")..
    " -> "..
    string.gsub(result,"-","_")..
    ' [color="'..color_from_name(ingredient)..
    '" '..
    serialize_options(attributes)..
    '];'
    )
    -- quantity just gets in the way on the big chart
    -- ..
    -- " [headlabel="..
    -- quantity..
    -- "];")
end

-- result is a string, the internal name of an item
-- ingredients is a table with one of two formats:
--         ingredients =
--         {
--            {"iron-gear-wheel", 30},
--           {"basic-transport-belt-to-ground", 2}
--         }
-- or
--         ingredients =
--         {
--           {type="fluid", name="crude-oil", amount=10},
--           {type="item", name="empty-barrel", amount=1},
--         }
function print_graph_links (result, ingredients, attributes)
    for i=1,#ingredients do
        if(ingredients[i]["type"] ~= nil) then
            print_graph_link(result,ingredients[i]["name"],ingredients[i]["amount"],attributes)
        else
            print_graph_link(result,ingredients[i][1],ingredients[i][2],attributes)
        end
    end
end



-- import the proper names of all items
--         pretty_names =
--        {
--            basic-transport-belt-to-ground = "Underground belt",
--            space-module-wreck = "Space module's wreckage",
--            ...
--        }
pretty_names = {}

-- TODO: enumerate cfg file list from directory, finding only names

name_files = {"base/locale/en/entity-names.cfg",
    "base/locale/en/item-names.cfg",
    "base/locale/en/equipment-names.cfg",
    "base/locale/en/fluids.cfg"}

for i,name_file in pairs(name_files) do
    file = io.open(name_file, "r")
    if file then
        for line in file:lines() do
            local codename, name = line:match("(.*)=(.*)")
            if(codename and name) then
                pretty_names[codename]=name
            end
        end
    end
    file:close()
end


-- result is the internal name of an item
--        "basic-transport-belt"
-- icon is the configured icon path for the item
--        "__base__/graphics/icons/basic-inserter.png"
-- printed output looks like this:
--   stone_brick [label=<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0" CELLPADDING="0"><TR><TD><IMG SCALE="true" SRC='base/graphics/icons/stone-brick.png' /></TD></TR><TR><TD>Stone<BR/>Brick</TD></TR></TABLE>>];

function print_node (result, icon, attributes)
    -- skip items with no icon
    if(
        icon ~= nil
        and
        (
            icon:match('__base__/graphics/icons')
            or
            icon:match('__base__/graphics/equipment')
        )    
    ) then
        -- TODO: improve rendering of items, bounding boxes, outlines, etc
        out = ''
        out = out .. '  '
        out = out .. string.gsub(result,"-","_")
        out = out .. " [label=<"
        out = out .. "<TABLE BORDER=\"0\" CELLBORDER=\"0\" CELLSPACING=\"0\" CELLPADDING=\"0\">"
        out = out .. "<TR><TD><IMG SCALE=\"true\" SRC='"
        out = out .. string.gsub(string.gsub(icon,"__core__","core"),"__base__","base")
        out = out .. "' /></TD></TR>"
        if ( render_item_names ) then
        	out = out .. "<TR><TD>"
            out = out .. string.gsub(pretty_names[result] or result," ","<BR/>")
            out = out .. "</TD></TR>"
        end
        out = out .. "</TABLE>>"
        out = out .. serialize_options(attributes)
        out = out .. "];"
        print(out)
    end
end


if(include_natural_resources_node) then
	print_node('natural_resources','__base__/graphics/icons/coin.png',{style='invis'})
    for i,r in pairs(natural_resources) do
    	-- TODO: stop using this icon
        print_graph_link(r,'natural-resources','""',{style='invis'})
    end

end

-- the factorio lua files want to use data:extend so we implement it here
data = {}
function data.extend (target, new_data)
    -- append rows from new_data to target
    -- also print out a DOT node for each item
    -- doing this here ensures that items with no recipe will be rendered
    for i=1,#new_data do
        target[new_data[i]["name"]] = new_data[i]
        if(skip_items[new_data[i]["name"]:gsub("-","_")]) then
        else
			print_node(new_data[i]["name"],new_data[i]["icon"])
		end
    end
end

-- TODO: enumerate lua file list from directory
dofile("base/prototypes/item/ammo.lua")
dofile("base/prototypes/item/armor.lua")
dofile("base/prototypes/item/capsule.lua")
dofile("base/prototypes/item/demo-ammo.lua")
dofile("base/prototypes/item/demo-armor.lua")
dofile("base/prototypes/item/demo-gun.lua")
dofile("base/prototypes/item/demo-item-groups.lua")
dofile("base/prototypes/item/demo-item.lua")
dofile("base/prototypes/item/demo-mining-tools.lua")
dofile("base/prototypes/item/demo-turret.lua")
dofile("base/prototypes/item/equipment.lua")
dofile("base/prototypes/item/gun.lua")
dofile("base/prototypes/item/item-groups.lua")
dofile("base/prototypes/item/item.lua")
dofile("base/prototypes/item/mining-tools.lua")
dofile("base/prototypes/item/module.lua")
dofile("base/prototypes/item/turret.lua")
dofile("base/prototypes/fluid/demo-fluid.lua")
dofile("base/prototypes/fluid/fluid.lua")

-- preserve the item information separately from the recipe data
item_info = data

-- the factorio lua files want to use data:extend so we implement it here
data = {}
function data.extend (target, new_data)
    -- append rows from new_data to target
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

-- produce a graph link for each ingredient of each recipe
for d=1,#data do
    if(skip_recipes[data[d]["name"]:gsub("-","_")]) then
    	
    else
        if(data[d]["results"] ~= nil) then
            -- fluids or other recipes with multiple results
            for r=1,#(data[d]["results"]) do
                -- print_node(data[d]["results"][r]["name"],item_info[result]["icon"])
                print_graph_links(data[d]["results"][r]["name"],data[d]["ingredients"])
            end
        else
            -- normal recipes, one result
            -- print_node(data[d]["result"],item_info[result]["icon"])
            print_graph_links(data[d]["result"],data[d]["ingredients"])
        end
    end
end

-- close the digraph
print("}")
