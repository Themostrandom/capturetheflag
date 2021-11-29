-- add_mode_func(minetest.register_on_dieplayer, "on_dieplayer", true) is the same as calling
--[[
	minetest.register_on_dieplayer(function(...)
		if current_mode.on_dieplayer then
			return current_mode.on_dieplayer(...)
		end
	end, true)
]]--
local function add_mode_func(minetest_func, mode_func_name, ...)
	minetest_func(function(...)
		local current_mode = ctf_modebase:get_current_mode()

		if not current_mode then return end

		if current_mode[mode_func_name] then
			return current_mode[mode_func_name](...)
		end
	end, ...)
end

add_mode_func(ctf_teams.register_on_allocplayer  , "on_allocplayer"  )
add_mode_func(minetest .register_on_dieplayer    , "on_dieplayer"    )
add_mode_func(minetest .register_on_respawnplayer, "on_respawnplayer")

add_mode_func(minetest.register_on_joinplayer , "on_joinplayer" )
add_mode_func(minetest.register_on_leaveplayer, "on_leaveplayer")

add_mode_func(ctf_modebase.register_on_new_match, "on_new_match", true)
add_mode_func(ctf_modebase.register_on_new_mode, "on_mode_start", true)
-- on_mode_end is called in match.lua's ctf_modebase.start_new_match()

minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	if not ctf_modebase.match_started then return true end

	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return true end

	local real_damage = current_mode.on_punchplayer(player, hitter, damage, time_from_last_punch, tool_capabilities, dir)
	if real_damage then
		player:set_hp(player:get_hp() - real_damage, {type="punch"})
	end

	return true
end)

ctf_healing.register_on_heal(function(...)
	if not ctf_modebase.match_started then return true end

	local current_mode = ctf_modebase:get_current_mode()
	if not current_mode then return true end

	return current_mode.on_healplayer(...)
end)

function ctf_modebase.on_flag_rightclick(...)
	if ctf_modebase.current_mode then
		ctf_modebase:get_current_mode().on_flag_rightclick(...)
	end
end

ctf_teams.team_allocator = function(...)
	local current_mode = ctf_modebase:get_current_mode()

	if not current_mode or #ctf_teams.current_team_list <= 0 then return end

	if current_mode.team_allocator then
		return current_mode.team_allocator(...)
	else
		return ctf_teams.default_team_allocator(...)
	end
end

local default_calc_knockback = minetest.calculate_knockback
minetest.calculate_knockback = function(...)
	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.calculate_knockback then
		return current_mode.calculate_knockback(...)
	else
		return default_calc_knockback(...)
	end
end

--
--- can_drop_item()

local default_item_drop = minetest.item_drop
minetest.item_drop = function(itemstack, dropper, ...)
	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.is_bound_item then
		if current_mode.is_bound_item(dropper, itemstack:get_name()) then
			return itemstack
		end
	end

	return default_item_drop(itemstack, dropper, ...)
end

dropondie.register_drop_filter(function(player, name)
	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.is_bound_item then
		return not current_mode.is_bound_item(player, name)
	end

	return true
end)

minetest.register_allow_player_inventory_action(function(player, action, inventory, info)
	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.is_bound_item and
	action == "take" and current_mode.is_bound_item(player, info.stack:get_name()) then
		return 0
	end
end)

ctf_ranged.can_use_gun = function(player, name)
	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.is_restricted_item then
		return not current_mode.is_restricted_item(player, name)
	end

	return true
end

function ctf_modebase.match_mode(param)
	local _, _, opt_param, mode_param = string.find(param, "^(.*) +mode:([^ ]*)$")

	if not mode_param then
		_, _, mode_param, opt_param = string.find(param, "^mode:([^ ]*) *(.*)$")
	end

	if not mode_param then
		opt_param = param
	end

	if not mode_param or mode_param == "" then
		mode_param = nil
	end
	if not opt_param or opt_param == "" then
		opt_param = nil
	end

	return opt_param, mode_param
end

function ctf_modebase.on_match_start()
	ctf_modebase.summary.on_match_start()
	ctf_modebase.bounties.on_match_start()
	ctf_modebase.skip_vote.on_match_start()

	ctf_modebase.match_started = true
end

function ctf_modebase.on_match_end()
	ctf_modebase.bounties.on_match_end()
	ctf_modebase.build_timer.on_match_end()
	ctf_modebase.flag_huds.on_match_end()
	ctf_modebase.respawn_delay.on_match_end()
	ctf_modebase.skip_vote.on_match_end()
	ctf_modebase.summary.on_match_end()
	ctf_modebase.update_wear.cancel_updates()

	if ctf_modebase.current_mode then
		ctf_modebase:get_current_mode().on_match_end()
	end
end

--- end
--