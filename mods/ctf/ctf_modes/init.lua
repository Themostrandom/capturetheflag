local rankings = ctf_rankings:init()
local recent_rankings = ctf_modebase.recent_rankings(rankings)
local features = ctf_modebase.features(rankings, recent_rankings)

local tool = ctf_core.include_files("item.lua")

local old_bounty_reward_func = ctf_modebase.bounties.bounty_reward_func
local old_get_next_bounty = ctf_modebase.bounties.get_next_bounty
ctf_modebase.register_mode("epic", {
	hp_regen = 2,
	treasures = {
		["default:ladder_wood" ] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		["default:torch"       ] = {                max_count = 20, rarity = 0.3, max_stacks = 5},
		
		["ctf_mode_epic:disappearing_block"] = {min_count = 45, max_count = 99, rarity = 0.4, max_stacks = 4},
		["default:cobble"      ] = {min_count = 45, max_count = 99, rarity = 0.4, max_stacks = 4},
		["default:wood"        ] = {min_count = 10, max_count = 60, rarity = 0.4, max_stacks = 4},

		["ctf_teams:door_steel"] = {rarity = 0.3, max_stacks = 3},

		["default:axe_mese"   ] = {rarity = 0.4, max_stacks = 2},

		["default:pick_diamond"  ] = {rarity = 0.05, max_stacks = 3},
		["default:shovel_diamond"] = {rarity = 0.05, max_stacks = 2},
		["default:axe_diamond"   ] = {rarity = 0.05, max_stacks = 2},

		["ctf_melee:sword_steel" ] = {rarity = 0.3  , max_stacks = 1},
		["ctf_melee:sword_mese"  ] = {rarity = 0.2 , max_stacks = 1},
		["ctf_melee:sword_diamond"  ] = {rarity = 0.1 , max_stacks = 1},


		["ctf_ranged:pistol_loaded" ] = {rarity = 0.2 , max_stacks = 2},
		["ctf_ranged:rifle_loaded"  ] = {rarity = 0.2                 },
		["ctf_ranged:shotgun_loaded"] = {rarity = 0.1               },
		["ctf_ranged:smg_loaded"    ] = {rarity = 0.05                },

		["ctf_map:spike"] = {min_count = 1, max_count =  15, max_stacks = 3, rarity = 0.2},
		["ctf_landmine:landmine"] = {min_count = 1, max_count =  10, max_stacks = 1, rarity = 0.2},
		["ctf_map:damage_cobble"    ] = {min_count = 10, max_count = 15, max_stacks = 2, rarity = 0.2},
		["ctf_map:reinforced_cobble"] = {min_count = 10, max_count = 15, max_stacks = 2, rarity = 0.2},

		["ctf_ranged:ammo"     ] = {min_count = 3, max_count = 10, rarity = 0.3  , max_stacks = 2},
		["ctf_healing:bandage" ] = {                               rarity = 0.08 , max_stacks = 2},
		["default:apple" ] = {min_count = 3, max_count = 25, rarity = 0.3  , max_stacks = 2},

		["grenades:smoke"] = {rarity = 0.1, max_stacks = 1},
		["grenades:poison"] = {rarity = 0.2, max_stacks = 1},
		["grenades:frag" ] = {rarity = 0.15, max_stacks = 2},
		
		["ctf_mode_epic:ender_pearl"] = {rarity = 0.1, max_stacks = 2},
		["ctf_mode_epic:cobble_wall_generator"] = {rarity = 0.1, max_stacks = 2},
		["ctf_mode_epic:speed"] = {rarity = 0.1, max_stacks = 2},
		["ctf_mode_epic:jump_boost"] = {rarity = 0.1, max_stacks = 2},
		["ctf_mode_epic:slow_falling"] = {rarity = 0.1, max_stacks = 2},
		["ctf_mode_epic:mlg"] = {rarity = 0.1, max_stacks = 2},
		["ctf_mode_epic:kb_stick"] = {rarity = 0.1, max_stacks = 2},
	},
	crafts = {
		"ctf_map:damage_cobble",
		"ctf_map:spike",
		"ctf_map:reinforced_cobble 2",
		"ctf_melee:sword_steel",
		"ctf_melee:sword_mese",
		"ctf_melee:sword_diamond",
	},
	physics = {sneak_glitch = true, new_move = true},
	team_chest_items = {
		"ctf_map:damage_cobble 40", "ctf_map:reinforced_cobble 40",
		"default:torch 30", "ctf_teams:door_steel 4",
	},
	rankings = rankings,
	recent_rankings = recent_rankings,
	summary_ranks = {
		_sort = "score",
		"score",
		"flag_captures", "flag_attempts",
		"kills", "kill_assists", "bounty_kills",
		"deaths",
		"hp_healed",
		"reward_given_to_enemy"
	},
	build_timer = 60 * 2,

	is_bound_item = function(_, name)
		if name:match("ctf_mode_epic:") then
			return true
		end
	end,
	stuff_provider = function(player)
		return {
			"ctf_mode_epic:knockback_grenade_tool",
			"ctf_melee:sword_steel",
			"default:apple 7",
			"default:pick_steel"
		}
	end,
	initial_stuff_item_levels = features.initial_stuff_item_levels,
	on_mode_start = function()
		ctf_modebase.bounties.bounty_reward_func = ctf_modebase.bounty_algo.kd.bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = ctf_modebase.bounty_algo.kd.get_next_bounty
	end,
	on_mode_end = function()
		ctf_modebase.bounties.bounty_reward_func = old_bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = old_get_next_bounty
	end,
	on_new_match = features.on_new_match,
	on_match_end = features.on_match_end,
	team_allocator = features.team_allocator,
	on_allocplayer = features.on_allocplayer,
	on_leaveplayer = features.on_leaveplayer,
	on_dieplayer = features.on_dieplayer,
	on_respawnplayer = features.on_respawnplayer,
	can_take_flag = features.can_take_flag,
	on_flag_take = features.on_flag_take,
	on_flag_drop = features.on_flag_drop,
	on_flag_capture = features.on_flag_capture,
	on_flag_rightclick = function() end,
	get_chest_access = features.get_chest_access,
	can_punchplayer = features.can_punchplayer,
	on_punchplayer = features.on_punchplayer,
	on_healplayer = features.on_healplayer,
	calculate_knockback = function()
		return 0
	end,
})

