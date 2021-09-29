-- custom particle effects
local effect = function(pos, amount, texture, min_size, max_size, radius, gravity, glow)

	radius = radius or 2
	min_size = min_size or 0.5
	max_size = max_size or 1
	gravity = gravity or -10
	glow = glow or 0

	minetest.add_particlespawner({
		amount = amount,
		time = 0.25,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -radius, y = -radius, z = -radius},
		maxvel = {x = radius, y = radius, z = radius},
		minacc = {x = 0, y = gravity, z = 0},
		maxacc = {x = -20, y = gravity, z = 15},
		minexptime = 0.1,
		maxexptime = 1,
		minsize = min_size,
		maxsize = max_size,
		texture = texture,
		glow = glow,
	})
end

--death
function nm_hq_die(self)
	local timer = 1.5
	local start = true
	local func = function()
		if start then
			mobkit.lq_fallover(self)
			self.logic = function() end	-- brain dead as well
			start=false
		end
		timer = timer-self.dtime
		if timer < 0 then
			local pos = self.object:get_pos()
			pos.y = pos.y + 0.5
			effect(pos, 30, "nether_particle.png", 0.1, 2, 3, 5)
			pos.y = pos.y + 0.25
			effect(pos, 30, "nether_particle.png", 0.1, 2, 3, 5)
			self.object:remove()
		end
	end
	mobkit.queue_high(self,func,100)
end

function nm_brain(self)
    --if mobkit.timer(self,1) then fl_wildlife.node_dps_dmg(self) end --if in nodes with damage take damage
    mobkit.vitals(self)

    if self.hp <= 0 then --kill self if 0 hp

        mobkit.clear_queue_high(self)
		local pos =  mobkit.get_stand_pos(self)

        --model rotation point is middle, so on death, model rotates in middle instead of feet
		nm_hq_die(self)

		local item_count = 0
		for _, drop in pairs(self.drops) do
			local count = 1
			if drop.min or drop.max then
				count = math.random(drop.min or 1, drop.max or drop.min+5)
			end

			if self.drops.max_items then
				if self.drops.max_items >= item_count then return end
				if (count+item_count) > self.drops.max_items then
					count = self.drops.max_items - item_count
				end
			end

			if drop.chance and math.random(1, drop.chance) ~= drop.chance then return end

			minetest.add_item(pos, drop.name .. " " .. count)
			item_count = item_count+count
		end

        return
    end

    if mobkit.timer(self,1) then
        local prty = mobkit.get_queue_priority(self)

        if prty < 20 and self.isinliquid then
            mobkit.hq_liquid_recovery(self,20)
            return
        end

        if mobkit.is_queue_empty_high(self) then
            mobkit.hq_roam(self,0)
        end

    end

end

minetest.register_entity("nether_mobs:netherman", {
    initial_properties = {
        physical = true,
        stepheight = 1.2,
        collide_with_objects = true,
        collisionbox = {-0.4, -1, -0.4, 0.4, 0.8, 0.4},
        visual = "mesh",
        mesh = "mobs_netherman.b3d",
        textures = {"mobs_netherman.png"},
        static_save = true,
        damage_texture_modifier = "^[colorize:#FF000040"
    },

    on_step = mobkit.stepfunc,
    on_activate = mobkit.actfunc,
    get_staticdata = mobkit.statfunc,

    --mobkit properties
    buoyancy = 0,
    max_speed = 5,
    jump_height = 1,
    view_range = 8,
    lung_capacity = 10,
    max_hp = 20,
    timeout = 0,
    attack={range=0.5,damage_groups={fleshy=3}},
    --no sounds atm
    animation = {
        stand = {range = {x=0,y=39}, speed = 7, loop = true},
        walk = {range = {x=41,y=72}, speed = 15, loop = true},
        run = {range = {x=74,y=105}, speed = 15, loop = true},
        punch = {range = {x=74,y=105}, speed = 10, loop = true},
    },
	drops = {
		{name = "nether:sand", chance = 1, min = 3, max = 5},
		{name = "nether:rack", chance = 3, min = 2, max = 4},
		{name = "nether:brick", chance = 5, min = 1, max = 2},
	},
	sounds = {
		random = "mobs_netherman",
	},

    brainfunc = nm_brain,

    --more mte properties
    on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
        --fl_wildlife.flash_color(self)
        self.object:set_velocity({x=hvel.x,y=2,z=hvel.z})
        mobkit.make_sound(self,'random')
        mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)
        if mobkit.is_alive(self) and puncher:is_player() then
			mobkit.hq_hunt(self,20,puncher)
        end
    end,
})

--egg as requested
minetest.register_craftitem("nether_mobs:netherman", {
	description = "nether man spaw egg",
	inventory_image = "nether_mobs_egg.png^(nether_mobs_egg_overlay.png^[colorize:#6f4644)",
	stack_max = 99,
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.under
		pos.y = pos.y+2
		minetest.add_entity(pos, "nether_mobs:netherman")
		itemstack:take_item()
		return itemstack
	end,
})

--[[
--using mobs_redo might work for spawning since it accepts a entity name?
--no idea if it checks if it is a mobs_redo mob or not
mobs:spawn({
	max_light = 15,
	name = "nether_mobs:netherman",
	nodes = {"nether:sand", "nether:rack"},
	interval = 2,
	chance = 2,
	day_toggle = nil,
	active_object_count = 2,
	on_spawn = function(self, pos)
		pos.y = pos.y + 0.5
		effect(pos, 30, "nether_particle.png", 0.1, 2, 3, 5)
		pos.y = pos.y + 0.25
		effect(pos, 30, "nether_particle.png", 0.1, 2, 3, 5)
	end,
})
--]]