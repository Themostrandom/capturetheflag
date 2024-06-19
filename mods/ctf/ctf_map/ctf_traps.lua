minetest.register_node("ctf_map:unwalkable_dirt", {
	description = "Unwalkable Dirt",
	tiles = {"default_dirt.png^[colorize:#ffff00:19"},
	is_ground_content = false,
	walkable = false,
	groups = {crumbly=3, soil=1}
})

minetest.register_node("ctf_map:unwalkable_stone", {
	description = "Unwalkable Stone",
	tiles = {"default_stone.png^[colorize:#ffff00:17"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=1}
})

minetest.register_node("ctf_map:unwalkable_cobble", {
	description = "Unwalkable Cobblestone",
	tiles = {"default_cobble.png^[colorize:#ffff00:15"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=2}
})

--
--- Spike Trap
--

minetest.register_node("ctf_map:spike", {
	description = "Spike\n7 DPS",
	drawtype = "plantlike",
	tiles = {"ctf_map_spike.png"},
	inventory_image = "ctf_map_spike.png",
	use_texture_alpha = "clip",
	paramtype = "light",
	paramtype2 = "meshoptions",
	sunlight_propagates = true,
	walkable = false,
	damage_per_second = 7,
	groups = {cracky=1, level=2},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	on_place = function(itemstack, placer, pointed_thing)
		local pteam = ctf_teams.get(placer)

		if pteam then
			if not ctf_core.pos_inside(pointed_thing.above, ctf_teams.get_team_territory(pteam)) then
				minetest.chat_send_player(placer:get_player_name(), "You can only place spikes in your own territory!")
				return itemstack
			end

			local newitemstack = ItemStack("ctf_map:spike_"..pteam)
			newitemstack:set_count(itemstack:get_count())

			local result = minetest.item_place(newitemstack, placer, pointed_thing, 34)

			if result then
				itemstack:set_count(result:get_count())
			end

			return itemstack
		end

		return minetest.item_place(itemstack, placer, pointed_thing, 34)
	end
})

for _, team in ipairs(ctf_teams.teamlist) do
	if not ctf_teams.team[team].not_playing then
		local spikecolor = ctf_teams.team[team].color

		minetest.register_node("ctf_map:spike_"..team, {
			description = HumanReadable(team).." Team Spike",
			drawtype = "plantlike",
			tiles = {"ctf_map_spike.png^[colorize:"..spikecolor..":150"},
			inventory_image = "ctf_map_spike.png^[colorize:"..spikecolor..":150",
			use_texture_alpha = "clip",
			paramtype = "light",
			paramtype2 = "meshoptions",
			sunlight_propagates = true,
			walkable = false,
			damage_per_second = 7,
			groups = {cracky=1, level=2},
			drop = "ctf_map:spike",
			selection_box = {
				type = "fixed",
				fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
			},
			on_place = function(itemstack, placer, pointed_thing)
				return minetest.item_place(itemstack, placer, pointed_thing, 34)
			end
		})
	end
end

minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if reason.type == "node_damage" then
		local team = ctf_teams.get(player)

		if team and reason.node == string.format("ctf_map:spike_%s", team) then
			return 0, true
		end
	end

	return hp_change
end, true)

--
-- Damage Cobble
--

local function damage_cobble_dig(pos, node, digger)
	if not digger:is_player() then return end

	local digger_name = digger:get_player_name()
	local digger_team = ctf_teams.get(digger_name)

	local meta = minetest.get_meta(pos)
	local placer_name = meta:get_string("placer")
	meta:set_string("placer", "")

	local placer_team = ctf_teams.get(placer_name)
	if placer_team ~= digger_team and not ctf_modebase.match_started then
		return
	end

	if digger_team == placer_team then return end

	local placerobj = minetest.get_player_by_name(placer_name)

	if placerobj then
		digger:punch(placerobj, 1, {
			damage_groups = {
				fleshy = 7,
				damage_cobble = 1,
			}
		})
	else
		digger:set_hp(digger:get_hp() - 7)
	end

	minetest.remove_node(pos)
	return true
end

minetest.register_node("ctf_map:damage_cobble", {
	description = "Damage Cobble\n(Damages any enemy that breaks it)",
	tiles = {"ctf_map_damage_cobble.png"},
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3, stone=2},
	on_ranged_shoot = function(pos, node, shooter, type)
		if type == "pistol" then
			return
		end

		if not damage_cobble_dig(pos, node, shooter) then
			return minetest.dig_node(pos)
		end
	end,
	on_dig = function(pos, node, digger)
		if not damage_cobble_dig(pos, node, digger) then
			return minetest.node_dig(pos, node, digger)
		end
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:set_string("placer", placer:get_player_name())
	end
})

minetest.register_node("ctf_map:reinforced_cobble", {
	description = "Reinforced Cobblestone",
	tiles = {"ctf_map_reinforced_cobble.png"},
	is_ground_content = false,
	groups = {cracky = 3, stone = 2},
	sounds = default.node_sound_stone_defaults(),
	on_punch = function(pos, node, digger)
		local meta = minetest.get_meta(pos)
		local placer_team = meta:get_string("placer_team")
		local digger_team = ctf_teams.get(digger)
		if placer_team ~= digger_team then
			minetest.set_node(pos, {name = "ctf_map:reinforced_cobble_hardened"})
			meta = minetest.get_meta(pos)
			meta:set_string("placer_team", placer_team)
		end
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:set_string("placer_team", ctf_teams.get(placer))
	end,
	on_dig = function(pos, node, digger)
		local meta = minetest.get_meta(pos)
		meta:set_string("placer_team", "")
		minetest.node_dig(pos, node, digger)
	end
})

minetest.register_node("ctf_map:reinforced_cobble_hardened", {
	description = "Reinforced Cobblestone Hardened\nYou're not meant to use this",
	tiles = {"ctf_map_reinforced_cobble.png"},
	is_ground_content = false,
	groups = {cracky = 1, stone = 2},
	sounds = default.node_sound_stone_defaults(),
	drop = "ctf_map:reinforced_cobble",
	on_punch = function(pos, node, digger)
		local meta = minetest.get_meta(pos)
		local placer_team = meta:get_string("placer_team")
		local digger_team = ctf_teams.get(digger)
		if placer_team == digger_team then
			minetest.set_node(pos, {name = "ctf_map:reinforced_cobble"})
			meta = minetest.get_meta(pos)
			meta:set_string("placer_team", placer_team)
		end
	end,
	on_dig = function(pos, node, digger)
		local meta = minetest.get_meta(pos)
		meta:set_string("placer_team", "")
		minetest.node_dig(pos, node, digger)
	end
})

minetest.register_node("ctf_map:cobble_wall_generator", {
    description = "Cobble Wall Generator",
    tiles = {"default_cobble.png^ctf_map_wall.png"},
    is_ground_content = false,
    groups = {cracky = 3, stone = 2},

    on_place = function(itemstack, placer, pointed_thing)
        local pos = pointed_thing.above
        if pos and placer then
            -- Vérifie s'il y a un drapeau dans un rayon de 8 blocs
            local radius = 8
            local flag_found = false

            for dx = -radius, radius do
                for dy = -radius, radius do
                    for dz = -radius, radius do
                        local check_pos = {x = pos.x + dx, y = pos.y + dy, z = pos.z + dz}
                        local node = minetest.get_node(check_pos)
                        if node.name == "ctf_modebase:flag" then
                            flag_found = true
                            break
                        end
                    end
                    if flag_found then break end
                end
                if flag_found then break end
            end

            if flag_found then
                minetest.chat_send_player(placer:get_player_name(), "You cannot place this block near a flag.")
                return itemstack
            end

            local dir = placer:get_look_dir()
            local dirx = math.floor(dir.x + 0.5)
            local dirz = math.floor(dir.z + 0.5)

            -- Calcule des vecteurs perpendiculaires
            local perp_x = -dirz
            local perp_z = dirx

            local start_x = pos.x - perp_x
            local start_z = pos.z - perp_z

            for x = 0, 3 do
                for y = 0, 3 do
                    local target_pos = {x = start_x + perp_x * x, y = pos.y + y, z = start_z + perp_z * x}
                    local node = minetest.get_node(target_pos)
                    if node.name == "air" then
                        minetest.set_node(target_pos, {name = "default:cobble"})
                    end
                end
            end
            itemstack:take_item()
        end
        return itemstack
    end,
})

