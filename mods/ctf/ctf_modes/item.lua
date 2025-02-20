local WEAR_MAX = 65535
local function check_hit(pos1, pos2, obj)
	local ray = minetest.raycast(pos1, pos2, true, false)
	local hit = ray:next()

	while hit and (
		(
		 hit.type == "node"
		 and
		 (
			hit.intersection_point:distance(pos2) <= 1
			or
			not minetest.registered_nodes[minetest.get_node(hit.under).name].walkable
		 )
		)
		or
		(
		 hit.type == "object" and hit.ref ~= obj
		)
	) do
		hit = ray:next()
	end

	if hit and hit.type == "object" and hit.ref == obj then
		return true
	end
end

local sounds = {}

local KNOCKBACK_AMOUNT = 40
local KNOCKBACK_RADIUS = 4.5
grenades.register_grenade("ctf_mode_epic:knockback_grenade", {
	description = "Knockback Grenade",
	image = "ctf_mode_epic_knockback_grenade.png",
	groups = {not_in_creative_inventory = 1},
	clock = 1.5,
	on_collide = function()
		return true
	end,
	touch_interaction = "short_dig_long_place",

	on_explode = function(def, obj, pos, name)
		minetest.add_particle({
			pos = pos,
			velocity = {x=0, y=0, z=0},
			acceleration = {x=0, y=0, z=0},
			expirationtime = 0.3,
			size = 15,
			collisiondetection = false,
			collision_removal = false,
			object_collision = false,
			vertical = false,
			texture = "grenades_boom.png",
			glow = 10
		})

		minetest.sound_play("grenades_explode", {
			pos = pos,
			gain = 0.6,
			pitch = 3.0,
			max_hear_distance = KNOCKBACK_RADIUS * 4,
		}, true)

		for _, v in pairs(minetest.get_objects_inside_radius(pos, KNOCKBACK_RADIUS)) do
			local vname = v:get_player_name()
			local player = minetest.get_player_by_name(name)

			if player and v:is_player() and v:get_hp() > 0 and v:get_properties().pointable and
			(vname == name or ctf_teams.get(vname) ~= ctf_teams.get(name)) then
				local footpos = vector.offset(v:get_pos(), 0, 0.1, 0)
				local headpos = vector.offset(v:get_pos(), 0, v:get_properties().eye_height, 0)
				local footdist = vector.distance(pos, footpos)
				local headdist = vector.distance(pos, headpos)
				local target_head = false

				if footdist >= headdist then
					target_head = true
				end

				local hit_pos1 = check_hit(pos, target_head and headpos or footpos, v)

				if hit_pos1 or check_hit(pos, target_head and footpos or headpos, v) then
					v:punch(player, 1, {
						punch_interval = 1,
						damage_groups = {
							fleshy = 1,
							knockback_grenade = 1,
						}
					}, nil)
					minetest.add_particlespawner({
						attached = v,
						amount = 10,
						time = 1,
						minpos = {x = 0, y = 1, z = 0},
						maxpos = {x = 0, y = 1, z = 0},
						minvel = {x = 0, y = 0, z = 0},
						maxvel = v:get_velocity(),
						minacc = {x = 0, y = -9, z = 0},
						maxacc = {x = 0, y = -9, z = 0},
						minexptime = 1,
						maxexptime = 2.8,
						minsize = 3,
						maxsize = 4,
						collisiondetection = false,
						collision_removal = false,
						vertical = false,
						texture = "grenades_smoke.png",
					})

					local kb = KNOCKBACK_AMOUNT

					local dir = vector.direction(pos, headpos)
					if dir.y < 0 then dir.y = 0 end
					local vel = {x = dir.x * kb, y = dir.y * (kb / 1.8), z = dir.z * kb }
					v:add_velocity(vel)
				end
			end
		end
	end,
})

do
	local kb_def = minetest.registered_items["ctf_mode_epic:knockback_grenade"]
	kb_def.name = "ctf_mode_epic:knockback_grenade_tool"
	kb_def.on_use = function(itemstack, user, pointed_thing)
		if itemstack:get_wear() > 1 then return end

		if itemstack:get_wear() <= 1 then
			grenades.throw_grenade("ctf_mode_epic:knockback_grenade", 17, user)
		end

		itemstack:set_wear(WEAR_MAX - 6000)
		ctf_modebase.update_wear.start_update(user:get_player_name(), kb_def.name, WEAR_MAX, true)

		return itemstack
	end
	minetest.register_tool(kb_def.name, kb_def)


	ctf_api.register_on_match_end(function()
		for sound in pairs(sounds) do
			minetest.sound_stop(sound)
		end
		sounds = {}
	end)
end


minetest.register_node("ctf_mode_epic:cobble_wall_generator", {
    description = "Cobble Wall Generator",
    tiles = {"ctf_mode_epic_wall.png"},
    is_ground_content = false,
    groups = {cracky = 3, stone = 2},

    on_place = function(itemstack, placer, pointed_thing)
        local pos = pointed_thing.above
        if pos and placer then
            local radius = 4
            local flag_found = false

            for dx = -radius, radius do
                for dy = -radius, radius do
                    for dz = -radius, radius do
                        local check_pos = {x = pos.x + dx, y = pos.y + dy, z = pos.z + dz}
                        local node = minetest.get_node(check_pos)
                        if node.name == "ctf_modebase:flag" or node.name == "ctf_map:ind_glass_red"  or node.name == "ctf_map:ind_glass"then
                            flag_found = true
                            break
                        end
                    end
                    if flag_found then break end
                end
                if flag_found then break end
            end

            if flag_found then
                minetest.chat_send_player(placer:get_player_name(), "You cannot place this block near a flag, a border or indestructible red glass.")
                return itemstack
            end

            local dir = placer:get_look_dir()
            local dirx = math.floor(dir.x + 0.5)
            local dirz = math.floor(dir.z + 0.5)

            local perp_x = -dirz
            local perp_z = dirx

            local start_x = pos.x - perp_x
            local start_z = pos.z - perp_z

            local function table_contains(table, value)
                for _, v in pairs(table) do
                    if v == value then
                        return true
                    end
                end
                return false
            end

            for x = 0, 3 do
                for y = 0, 3 do
                    for z = 0, 0 do 
                        local target_pos = {x = start_x + perp_x * x, y = pos.y + y, z = start_z + perp_z * x}
                        local node = minetest.get_node(target_pos)

                        local replace_blocks = {
                            "default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5",
                            "default:dry_grass_1", "default:dry_grass_2", "default:dry_grass_3", "default:dry_grass_4", "default:dry_grass_5",
                            "default:junglegrass", "default:marram_grass_1", "default:marram_grass_2", "default:marram_grass_3",
                            "default:marram_grass_4", "default:marram_grass_5", "flowers:rose", "flowers:tulip", "flowers:viola",
                            "flowers:geranium", "flowers:tulip_black", "flowers:dandelion_white", "flowers:dandelion_yellow",
                            "flowers:chrysanthemum_green"
                        }

                        if node.name == "air" or table_contains(replace_blocks, node.name) then
                            minetest.set_node(target_pos, {name = "default:cobble"})
                        end
                    end
                end
            end
            itemstack:take_item()
        end
        return itemstack
    end,
})

ctf_mode_epic = {}
local function find_teleport_pos(pos, pl_pos)
  local dir = vector.direction(pos, pl_pos)
  local tries = {
    vector.normalize(vector.new(dir.x, 0.7, dir.z)),
    dir * 2,
    dir * 3,
    dir * 4,
    dir * 10
  }

  for _, d in ipairs(tries) do
    local teleport_pos = vector.add(pos, d)
    local head_pos = vector.add(teleport_pos, vector.new(0, 1.5, 0))
    local node = minetest.get_node_or_nil(teleport_pos)
    local head_node = minetest.get_node_or_nil(head_pos)

    if node and head_node then
      local def = minetest.registered_nodes[node.name]
      local head_def = minetest.registered_nodes[head_node.name]

      if (def and not def.walkable) and (head_def and not head_def.walkable) then
        return teleport_pos
      end
    end
  end
  return pos
end

minetest.register_craftitem("ctf_mode_epic:ender_pearl", {
  description = "Ender Pearl\nLeft click to launch",
  inventory_image = "ctf_mode_epic_enderpearl.png",
  stack_max = 1,
  on_use = function(_, player, pointed_thing)
    local throw_starting_pos = vector.add({x=0, y=1.5, z=0}, player:get_pos())
    local thrown_pearl = minetest.add_entity(throw_starting_pos, "ctf_mode_epic:thrown_ender_pearl", player:get_player_name())

    minetest.after(0, function() player:get_inventory():remove_item("main", "ctf_mode_epic:ender_pearl") end)

    minetest.sound_play("enderpearl_throw", {max_hear_distance = 10, pos = player:get_pos()})
  end,
})


local thrown_ender_pearl = {
  initial_properties = {
    hp_max = 1,
    physical = true,
    collide_with_objects = false,
    collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
    visual = "wielditem",
    visual_size = {x = 0.4, y = 0.4},
    textures = {"ctf_mode_epic:ender_pearl"},
    spritediv = {x = 1, y = 1},
    initial_sprite_basepos = {x = 0, y = 0},
    pointable = false,
    speed = 45,
    gravity = 35,
    damage = 2,
    lifetime = 10
  },
  player_name = ""
}

function thrown_ender_pearl:on_step(dtime, moveresult)
  local collided_with_node = moveresult.collisions[1] and moveresult.collisions[1].type == "node"

  if collided_with_node then
    local player = minetest.get_player_by_name(self.player_name)

    if not player or player:get_meta():get_string("ep_can_teleport") == "false" then
      self.object:remove()
      return
    end

    player:add_velocity(vector.multiply(player:get_velocity(), -1))
    player:set_pos(find_teleport_pos(self.object:get_pos(), player:get_pos()))
    player:set_hp(player:get_hp() - self.initial_properties.damage, "enderpearl")
    minetest.sound_play("enderpearl_teleport", {max_hear_distance = 10, pos = player:get_pos()})

    self.object:remove()
  end
end

function thrown_ender_pearl:on_activate(staticdata)
  if not staticdata or not minetest.get_player_by_name(staticdata) then
    self.object:remove()
    return
  end

  self.player_name = staticdata
  local player = minetest.get_player_by_name(staticdata)
  local yaw = player:get_look_horizontal()
  local pitch = player:get_look_vertical()
  local dir = player:get_look_dir()

  self.object:set_rotation({x = -pitch, y = yaw, z = 0})
  self.object:set_velocity({
    x = dir.x * self.initial_properties.speed,
    y = dir.y * self.initial_properties.speed,
    z = dir.z * self.initial_properties.speed,
  })
  self.object:set_acceleration({x = dir.x * -4, y = -self.initial_properties.gravity, z = dir.z * -4})

  minetest.after(self.initial_properties.lifetime, function() self.object:remove() end)
end

minetest.register_entity("ctf_mode_epic:thrown_ender_pearl", thrown_ender_pearl)

function ctf_mode_epic.on_teleport(func)
  table.insert(callbacks, func)
end

function ctf_mode_epic.block_teleport(player, duration)
  if duration then
    minetest.after(duration, function()
      if minetest.get_player_by_name(player:get_player_name()) then
        player:get_meta():set_string("ep_can_teleport", "")
      end
    end)
  end

  player:get_meta():set_string("ep_can_teleport", "false")
end

minetest.register_node("ctf_mode_epic:mlg", {
	description = "MLG block",
	tiles = {"ctf_mode_epic_mlg.png"},
	groups = {
		snappy = 3, cracky = 3, choppy = 3, oddly_breakable_by_hand = 3,
		flammable = 2, disable_jump = 1, fall_damage_add_percent = -100,
		leafdecay = 3
	},
	sounds = default.node_sound_stone_defaults()
})

local last_use_time = 0

minetest.register_tool("ctf_mode_epic:kb_stick", {
    description = "KB stick",
    inventory_image = "default_stick.png",
    tool_capabilities = {
        full_punch_interval = 1.0,
        max_drop_level = 0,
        groupcaps = {
            fleshy = {times = {[2] = 1.00, [3] = 0.50}, uses = 100, maxlevel = 1},
        },
        damage_groups = {fleshy = 2},
    },
    on_use = function(itemstack, user, pointed_thing)
        local current_time = minetest.get_gametime()

        if current_time - last_use_time >= 1 then
            last_use_time = current_time  
            
            if pointed_thing.type == "object" and pointed_thing.ref then
                local obj = pointed_thing.ref
                if obj:is_player() then
                    local dir = user:get_look_dir()
                    local push_force = 16 
                    obj:add_velocity({x = dir.x * push_force, y = 3, z = dir.z * push_force})
                end
            end
        else
        end
    end,
})

local active_potions = {}

local potion_effects = {
    jump_boost = {jump = 2.5},
    speed = {speed = 3.0},
    slow_falling = true
}

local function apply_potion_effects(player, effect_type)
    -- Sauvegarde de l'état initial
    local player_name = player:get_player_name()
    if not active_potions[player_name] then
        active_potions[player_name] = {}
    end
    local original_stats = active_potions[player_name].original_stats or {}
    
    if effect_type == "jump_boost" then
        original_stats.jump = player:get_physics_override().jump
        player:set_physics_override({jump = potion_effects.jump_boost.jump})
    elseif effect_type == "speed" then
        original_stats.speed = player:get_physics_override().speed
        player:set_physics_override({speed = potion_effects.speed.speed})
    elseif effect_type == "slow_falling" then
        original_stats.gravity = player:get_physics_override().gravity
        player:set_physics_override({gravity = 0.3})
    end
    
    -- Sauvegarde les statistiques originales
    active_potions[player_name].original_stats = original_stats
end

local function remove_potion_effects(player)
    local player_name = player:get_player_name()
    local original_stats = active_potions[player_name] and active_potions[player_name].original_stats
    if original_stats then
        player:set_physics_override({
            jump = original_stats.jump or 1.0,
            speed = original_stats.speed or 1.0,
            gravity = original_stats.gravity or 1.0
        })
    end
end

local function create_hud(player, effect_type, duration)
    local hud_id = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.5, y = 0.1},
        offset = {x = 0, y = 20},
        text = effect_type .. ": " .. math.floor(duration) .. "s",
        scale = {x = 100, y = 100},
        alignment = {x = 0, y = 0},
        color = red,
    })
    return hud_id
end

local function update_hud(player, hud_id, remaining_time, effect_type)
    player:hud_change(hud_id, "text", effect_type .. ": " .. math.floor(remaining_time) .. "s")
end

local function apply_potion(player, effect_type)
    local player_name = player:get_player_name()

    if active_potions[player_name] then
        return nil
    end

    local duration = 30 
    local hud_id = create_hud(player, effect_type, duration)

    active_potions[player_name] = {effect = effect_type, duration = duration, hud_id = hud_id}

    apply_potion_effects(player, effect_type)

    minetest.after(0.1, function()
        local function update_timer()
            local potion_data = active_potions[player_name]
            if not potion_data or potion_data.duration <= 0 then
                remove_potion_effects(player)
                player:hud_remove(hud_id)
                active_potions[player_name] = nil
            else
                update_hud(player, hud_id, potion_data.duration, effect_type)
                potion_data.duration = potion_data.duration - 0.1
                minetest.after(0.1, update_timer)
            end
        end

        update_timer()
    end)

    return true
end

minetest.register_craftitem("ctf_mode_epic:jump_boost", {
    description = "Potion of Jump Boost",
    inventory_image = "ctf_mode_epic_jump_boost.png",
    on_use = function(itemstack, user, pointed_thing)
        if apply_potion(user, "jump_boost") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

minetest.register_craftitem("ctf_mode_epic:speed", {
    description = "Potion of Speed",
    inventory_image = "ctf_mode_epic_speed.png",
    on_use = function(itemstack, user, pointed_thing)
        if apply_potion(user, "speed") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

minetest.register_craftitem("ctf_mode_epic:slow_falling", {
    description = "Potion of Slow Falling",
    inventory_image = "ctf_mode_epic_slow_falling.png",
    on_use = function(itemstack, user, pointed_thing)
        if apply_potion(user, "slow_falling") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

minetest.register_node("ctf_mode_epic:disappearing_block", {
    description = "Disappearing Block",
    tiles = {"ctf_mode_epic_block.png"},
    groups = {cracky = 3},           

    on_construct = function(pos)
        minetest.after(10, function()
            if minetest.get_node(pos).name == "ctf_mode_epic:disappearing_block" then
                minetest.set_node(pos, {name = "air"}) 
            end
        end)
    end,
})






