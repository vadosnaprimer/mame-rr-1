print("CPS-2 Marvel series hitbox viewer")
print("March 17, 2011")
print("http://code.google.com/p/mame-rr/")
print("Lua hotkey 1: toggle blank screen")
print("Lua hotkey 2: toggle object axis")
print("Lua hotkey 3: toggle hitbox axis")
print("Lua hotkey 4: toggle pushboxes")
print("Lua hotkey 5: toggle throwboxes and throwable boxes") print()

local VULNERABILITY_COLOR      = 0x7777FF40
local ATTACK_COLOR             = 0xFF000040
local PROJ_VULNERABILITY_COLOR = 0x00FFFF40
local PROJ_ATTACK_COLOR        = 0xFF66FF60
local PUSH_COLOR               = 0x00FF0020
local THROW_COLOR              = 0xFFFF0060
local THROWABLE_COLOR          = 0xFFFFFF20
local AXIS_COLOR               = 0xFFFFFFFF
local BLANK_COLOR              = 0xFFFFFFFF
local AXIS_SIZE                = 12
local MINI_AXIS_SIZE           = 2
local DRAW_DELAY               = 1
local BLANK_SCREEN             = false
local DRAW_AXIS                = false
local DRAW_MINI_AXIS           = false
local DRAW_PUSHBOXES           = true
local DRAW_THROWBOXES          = false

local GAME_PHASE_NOT_PLAYING = 0
local VULNERABILITY_BOX      = 1
local ATTACK_BOX             = 2
local PROJ_VULNERABILITY_BOX = 3
local PROJ_ATTACK_BOX        = 4
local PUSH_BOX               = 5
local THROW_BOX              = 6
local THROWABLE_BOX          = 7

local fill = {
	VULNERABILITY_COLOR,
	ATTACK_COLOR,
	PROJ_VULNERABILITY_COLOR,
	PROJ_ATTACK_COLOR,
	PUSH_COLOR,
	THROW_COLOR,
	THROWABLE_COLOR,
}

local outline = {
	bit.bor(0xFF, VULNERABILITY_COLOR),
	bit.bor(0xFF, ATTACK_COLOR),
	bit.bor(0xFF, PROJ_VULNERABILITY_COLOR),
	bit.bor(0xFF, PROJ_ATTACK_COLOR),
	bit.bor(0xC0, PUSH_COLOR),
	bit.bor(0xFF, THROW_COLOR),
	bit.bor(0xC0, THROWABLE_COLOR),
}

local function beq(func, val)
	return (func(val) == 0)
end


local function bne(func, val)
	return (func(val) ~= 0)
end


local profile = {
	{
		game = "xmcota",
		number_players = 2,
		address = {
			player           = 0xFF4000,
			projectile_ptr   = 0xFFD6C4,
			game_phase       = 0xFF4BA4,
			stage            = 0xFF488F,
			stage_camera = {
				[0x0] = 0xFF498C, --Savage Land (Wolverine)
				[0x1] = 0xFF4A0C, --Moon Night (Psylocke)
				[0x2] = 0xFF4A0C, --Mutant Hunting (Colossus)
				[0x3] = 0xFF4A0C, --Danger Room (Cyclops)
				[0x4] = 0xFF4A0C, --On the Blackbird (Storm)
				[0x5] = 0xFF4A0C, --Ice on the Beach (Iceman)
				[0x6] = 0xFF4A0C, --Mojo World (Spiral)
				[0x7] = 0xFF4A0C, --Samurai Shrine (Silver Samurai)
				[0x8] = 0xFF4A0C, --The Deep (Omega Red)
				[0x9] = 0xFF4A0C, --Genosha (Sentinel)
				[0xA] = 0xFF4A0C, --Space Port (Juggernaut)
				[0xB] = 0xFF498C, --Avalon (Magneto)
			},
		},
		offset = {
			facing_dir           = 0x4D,
			char_id              = 0x50,
			invulnerable         = 0xF7,
			no_push              = 0x10A,
			throw_count          = 0x11E,
			projectile_ptr_space = 0x1C8,
		},
		box_list = {
			{id_ptr = 0xA2, type = PUSH_BOX},
			{addr_table_ptr = 0x88, id_ptr = 0x7C, type = THROWABLE_BOX},
			{addr_table_ptr = 0x88, id_ptr = 0x74, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x88, id_ptr = 0x76, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x88, id_ptr = 0x78, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x88, id_ptr = 0x7A, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x88, id_ptr = 0x70, type = ATTACK_BOX},
			{addr_table_ptr = 0x88, id_ptr = 0x72, type = ATTACK_BOX},
		},
		pushbox_base = {
			[0x0B7642] = {"xmcotajr"}, --941208
			[0x0C08F6] = {"xmcotaa", "xmcotaj3"}, --941217
			[0x0C0A90] = {"xmcotaj2"}, --941219
			[0x0C0ABE] = {"xmcotaj1"}, --941222
			[0x0C15E2] = {"xmcota", "xmcotad", "xmcotahr1", "xmcotaj", "xmcotau"}, --950105
			[0x0C1618] = {"xmcotah"}, --950331
		},
		unthrowable = {
			{offset = 0x125, compfunc = bne, readfunc = memory.readbyte},
			{offset = 0x137, compfunc = bne, readfunc = memory.readbyte},
		},
		unthrowable_status = {},
	},
	{
		game = "msh",
		number_players = 2,
		address = {
			player           = 0xFF4000,
			projectile_ptr   = 0xFFE400,
			game_phase       = 0xFF8EC3,
			stage            = 0xFF4893,
			stage_camera = {
				[0x0] = 0xFF4A0C, --Spider-Man
				[0x1] = 0xFF4A0C, --Captain America
				[0x2] = 0xFF4A0C, --Hulk
				[0x3] = 0xFF4A0C, --Iron Man
				[0x4] = 0xFF498C, --Wolverine
				[0x5] = 0xFF4A0C, --Psylocke
				[0x6] = 0xFF4B0C, --BlackHeart
				[0x7] = 0xFF4A0C, --Shuma-Gorath
				[0x8] = 0xFF4A0C, --Juggernaut
				[0x9] = 0xFF4A0C, --Magneto
				[0xA] = 0xFF4A0C, --Dr.Doom
				[0xA] = 0xFF4A0C, --Thanos
			},
		},
		offset = {
			facing_dir           = 0x4D,
			char_id              = 0x50,
			invulnerable         = 0xF7,
			no_push              = 0x10A,
			throw_count          = 0x11E,
			projectile_ptr_space = 0x148,
		},
		box_list = {
			{id_ptr = 0xA2, type = PUSH_BOX},
			{addr_table_ptr = 0x90, id_ptr = 0x80, type = THROWABLE_BOX},
			{addr_table_ptr = 0x90, id_ptr = 0x78, type = VULNERABILITY_BOX, active = 0x86},
			{addr_table_ptr = 0x90, id_ptr = 0x7A, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x90, id_ptr = 0x7C, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x90, id_ptr = 0x7E, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x90, id_ptr = 0x74, type = ATTACK_BOX, active = 0x86},
			{addr_table_ptr = 0x90, id_ptr = 0x76, type = ATTACK_BOX},
		},
		pushbox_base = {
			[0x09E82C] = {"msh", "msha", "mshjr1", "mshud", "mshu"}, --951024
			[0x09E95E] = {"mshb", "mshh", "mshj"}, --951117
		},
		unthrowable = {
			{offset = 0x125, compfunc = bne, readfunc = memory.readbyte},
			{offset = 0x137, compfunc = bne, readfunc = memory.readbyte},
		},
		unthrowable_status = {},
	},
	{
		game = "xmvsf",
		number_players = 4,
		pushable_players = 2,
		address = {
			player           = 0xFF4000,
			projectile_ptr   = 0xFFE3D8,
			game_phase       = 0xFFA015,
			stage            = 0xFF5113,
			stage_camera = {
				[0x0] = 0xFF534C, --Apocalypse Now!
				[0x1] = 0xFF524C, --Showdown in the Park
				[0x2] = 0xFF524C, --Death Valley
				[0x3] = 0xFF52CC, --The Cataract
				[0x4] = 0xFF524C, --The Temple of Fists
				[0x5] = 0xFF524C, --On the Hilltop
				[0x6] = 0xFF534C, --Manhattan
				[0x7] = 0xFF524C, --Raging Inferno
				[0x8] = 0xFF52CC, --Code Red
				[0x9] = 0xFF524C, --Dead or Live: The Show
				[0xA] = 0xFF524C, --Mall Mayhem
			},
		},
		offset = {
			facing_dir           = 0x4B,
			char_id              = 0x52,
			invulnerable         = 0xF7,
			no_push              = 0x105,
			throw_count          = 0x10A,
			projectile_ptr_space = 0x150,
		},
		box_list = {
			{id_ptr = 0xA4, projectile_id_ptr = 0xB2, type = PUSH_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x7C, type = THROWABLE_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x74, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x76, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x78, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x7A, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x70, type = ATTACK_BOX, active = 0x82},
			{addr_table_ptr = 0x6C, id_ptr = 0x72, type = ATTACK_BOX},
		},
		pushbox_base = {
			[0x08AEB4] = {"xmvsfjr2", apoc = 0x05D08C}, --960909
			[0x08AEEE] = {"xmvsfar2", "xmvsfr1", "xmvsfjr1", apoc = 0x05D092}, --960910
			[0x08B022] = {"xmvsf", "xmvsfar1", "xmvsfh", "xmvsfj", "xmvsfu1d", "xmvsfur1", apoc = 0x05D0FA}, --960919, 961004
			[0x08B050] = {"xmvsfa", "xmvsfb", "xmvsfu", apoc = 0x05D10C}, --961023
		},
		unthrowable = {
			{offset = 0x083, compfunc = beq, readfunc = memory.readbyte},
			{offset = 0x120, compfunc = bne, readfunc = memory.readbyte},
			{offset = 0x221, compfunc = bne, readfunc = memory.readbyte},
		},
		unthrowable_status = {0xC},
	},
	{
		game = "mshvsf",
		number_players = 4,
		address = {
			player           = 0xFF3800,
			projectile_ptr   = 0xFFE32E,
			game_phase       = 0xFF48C9,
			stage            = 0xFF4913,
			stage_camera = {
				[0x0] = 0xFF4B4C, --Apocalypse Now!
				[0x1] = 0xFF4A4C, --Showdown in the Park
				[0x2] = 0xFF4A4C, --Death Valley
				[0x3] = 0xFF4ACC, --The Cataract
				[0x4] = 0xFF4A4C, --The Temple of Fists
				[0x5] = 0xFF4A4C, --On the Hilltop
				[0x6] = 0xFF4B4C, --Manhattan
				[0x7] = 0xFF4A4C, --Raging Inferno
				[0x8] = 0xFF4ACC, --Code Red
				[0x9] = 0xFF4A4C, --Dead or Live: The Show
				[0xA] = 0xFF4A4C, --Mall Mayhem
				[0xB] = 0xFF4A4C, --Raging Inferno 2
				[0xC] = 0xFF4A4C, --Death Valley 2
			},
		},
		offset = {
			facing_dir           = 0x4B,
			char_id              = 0x52,
			invulnerable         = 0xF7,
			no_push              = 0x105,
			throw_count          = 0x10A,
			projectile_ptr_space = 0x150,
		},
		box_list = {
			{id_ptr = 0xA4, projectile_id_ptr = 0xB2, type = PUSH_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x7C, type = THROWABLE_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x74, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x76, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x78, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x7A, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x70, type = ATTACK_BOX, active = 0x82},
			{addr_table_ptr = 0x6C, id_ptr = 0x72, type = ATTACK_BOX},
		},
		pushbox_base = {
			[0x137E90] = {"mshvsfa1", apoc = 0x0875DC}, --970620
			[0x137EE2] = {"mshvsf", "mshvsfa", "mshvsfb1", "mshvsfh", "mshvsfj2", "mshvsfu1", "mshvsfu1d", apoc = 0x087610}, --970625
			[0x138158] = {"mshvsfj1", apoc = 0x087606}, --970702
			[0x1381E4] = {"mshvsfj", apoc = 0x087606}, --970707
			[0x1381C6] = {"mshvsfu", "mshvsfb", apoc = 0x0875E4}, --970827
		},
		unthrowable = {
			{offset = 0x083, compfunc = beq, readfunc = memory.readbyte},
			{offset = 0x120, compfunc = bne, readfunc = memory.readbyte},
			{offset = 0x261, compfunc = bne, readfunc = memory.readbyte},
		},
		unthrowable_status = {0x8, 0xC},
	},
	{
		game = "mvsc",
		number_players = 4,
		address = {
			player           = 0xFF3000,
			projectile_ptr   = 0xFFDF1A,
			game_phase       = 0xFF62B7,
			stage            = 0xFF4113,
			stage_camera = {
				[0x0] = 0xFF426C, --Honda's bath house
				[0x1] = 0xFF426C, --Lord Rapter concert
				[0x2] = 0xFF426C, --Strider Kazakh SSR
				[0x3] = 0xFF42EC, --Dr. Wily's lab
				[0x4] = 0xFF42EC, --Marvel stuff
				[0x5] = 0xFF426C, --Avengers HQ
				[0x6] = 0xFF426C, --Moon base
				[0x7] = 0xFF41EC, --Daily Bugle rooftop
				[0x8] = 0xFF41EC, --Mountain
				[0x9] = 0xFF436C, --Onslaught
			},
		},
		offset = {
			facing_dir           = 0x4B,
			char_id              = 0x52,
			invulnerable         = 0x107,
			no_push              = 0x115,
			throw_count          = 0x11A,
			projectile_ptr_space = 0x158,
		},
		box_list = {
			{id_ptr = 0xB4, type = PUSH_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x7C, type = THROWABLE_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x74, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x76, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x78, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x7A, type = VULNERABILITY_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x70, type = ATTACK_BOX},
			{addr_table_ptr = 0x6C, id_ptr = 0x72, type = ATTACK_BOX},
		},
		pushbox_base = {
			[0x0E5DA6] = {"mvscur1"}, --971222
			[0x0E5EF4] = {"mvscar1", "mvscr1", "mvscjr1"}, --980112
			[0x0E6FEE] = {"mvsc", "mvsca", "mvscb", "mvsch", "mvscj", "mvscud", "mvscu"}, --980123
		},
		unthrowable = {
			{offset = 0x000, compfunc = beq, readfunc = memory.readbyte},
			{offset = 0x083, compfunc = beq, readfunc = memory.readbyte},
			{offset = 0x130, compfunc = bne, readfunc = memory.readbyte},
			{offset = 0x270, compfunc = beq, readfunc = memory.readword},
		},
		unthrowable_status = {0x8, 0xC},
	},
}

for game in ipairs(profile) do
	local g = profile[game]
	g.pushable_players = g.pushable_players or g.number_players
	g.offset.player_space = 0x400
	g.offset.x_position   = 0x0C
	g.offset.y_position   = 0x10
	g.offset.status       = 0x06
	g.box = {
		radius_read = memory.readword,
		offset_read = memory.readwordsigned,
		hval = 0x0, hrad = 0x2, vval = 0x4, vrad = 0x6,
	}
	for entry in ipairs(g.box_list) do
		g.box_list[entry].address_func = g.box_list[entry].addr_table_ptr and 1 or 2
	end
	g.address.projectile_limit = g.address.player + g.offset.player_space * g.number_players
end

local game, pushbox_base, apoc_value
local globals = {
	game_phase       = 0,
	left_screen_edge = 0,
	top_screen_edge  = 0,
}
local player       = {}
local projectiles  = {}
local frame_buffer = {}
if fba then
	DRAW_DELAY = DRAW_DELAY + 1
end


--------------------------------------------------------------------------------
-- prepare the hitboxes

local function update_globals()
	local curr_stage = memory.readbyte(game.address.stage)
	if not game.address.stage_camera[curr_stage] then
		curr_stage = 1
	end
	globals.left_screen_edge = memory.readwordsigned(game.address.stage_camera[curr_stage]) + 0x40
	globals.top_screen_edge  = memory.readwordsigned(game.address.stage_camera[curr_stage] + 0x4)
	globals.game_phase       = memory.readbyte(game.address.game_phase)
end


local function get_x(x)
	return x - globals.left_screen_edge
end


local function get_y(y)
	return y - globals.top_screen_edge - 15
end


local get_address = {
	function(obj, entry, box)
		box.id = memory.readword(obj.base + game.box_list[entry].id_ptr)
		if box.id == 0 or (game.box_list[entry].active and memory.readbyte(obj.base + game.box_list[entry].active) == 0) then
			return true
		end

		if obj.projectile then
			if box.type == ATTACK_BOX then
				box.type = PROJ_ATTACK_BOX
			elseif box.type == VULNERABILITY_BOX then
				box.type = PROJ_VULNERABILITY_BOX
			end
		elseif box.type == ATTACK_BOX and bit.band(box.id, 0xF000) == 0x8000 then
			box.type = THROW_BOX
		end

		local addr_table = memory.readdword(obj.base + game.box_list[entry].addr_table_ptr)
		box.address = addr_table + bit.band(box.id, 0x0FFF) * 0x8
	end,

	function(obj, entry, box) --pushbox
		if not pushbox_base or (obj.projectile and not obj.apoc_fist) then
			return true
		end

		box.id = memory.readbyte(obj.base + (obj.projectile and game.box_list[entry].projectile_id_ptr or game.box_list[entry].id_ptr))
		box.address = memory.readdword(pushbox_base + box.id * 0x2) + memory.readword(obj.base + game.offset.char_id) * 0x4
	end,
}


local function define_box(obj, entry)
	local box = {type = game.box_list[entry].type}

	if get_address[game.box_list[entry].address_func](obj, entry, box) then
		return nil
	end

	box.hrad = game.box.radius_read(box.address + game.box.hrad)
	box.vrad = game.box.radius_read(box.address + game.box.vrad)
	box.hval = game.box.offset_read(box.address + game.box.hval)
	box.vval = game.box.offset_read(box.address + game.box.vval)

	box.hval   = obj.pos_x + box.hval * (bit.band(obj.facing_dir, 1) > 0 and -1 or 1)
	box.vval   = obj.pos_y + box.vval * (bit.band(obj.facing_dir, 2) > 0 and game.box_list[entry].addr_table_ptr and -1 or 1)
	box.left   = box.hval - box.hrad
	box.right  = box.hval + box.hrad
	box.top    = box.vval - box.vrad
	box.bottom = box.vval + box.vrad

	return box
end


local function update_game_object(obj)
	obj.facing_dir   = memory.readbyte(obj.base + game.offset.facing_dir)
	obj.pos_x        = get_x(memory.readwordsigned(obj.base + game.offset.x_position))
	obj.pos_y        = get_y(memory.readwordsigned(obj.base + game.offset.y_position))

	for entry in ipairs(game.box_list) do
		obj[entry] = define_box(obj, entry)
	end
end


local function read_projectiles()
	local current_projectiles = {}

	for player = 0, 1 do
		local i = 1
		while i do
			local obj = {base = memory.readdword(game.address.projectile_ptr + player * game.offset.projectile_ptr_space - i * 4)}
			if obj.base < game.address.projectile_limit then
				i = nil
			else
				obj.projectile = true
				obj.apoc_fist = apoc_value and memory.readdword(obj.base + 0xAC) == apoc_value and true
				update_game_object(obj)
				table.insert(current_projectiles, obj)
				i = i + 1
			end
		end
	end

	return current_projectiles
end


local function update_unthrowable(base)
	for _, value in ipairs(game.unthrowable_status) do
		if memory.readword(base + game.offset.status) == value then
			return true
		end
	end
	for _, case in ipairs(game.unthrowable) do
		if case.compfunc(case.readfunc, base + case.offset) then
			return true
		end
	end
	if memory.readbyte(base + game.offset.throw_count) > 1 then
		return true
	end
	return false
end


local function update_marvel_hitboxes()
	if not game then
		return
	end
	update_globals()

	for p = 1, game.number_players do
		player[p] = {base = game.address.player + (p-1) * game.offset.player_space}
		if game.number_players <= 2 or memory.readword(player[p].base) >= 0x100 then
			player[p].hurt = memory.readword(player[p].base + game.offset.status) > 0
			player[p].invulnerable = memory.readbyte(player[p].base + game.offset.invulnerable) > 0
			player[p].unthrowable = update_unthrowable(player[p].base)
			player[p].no_push = memory.readbyte(player[p].base + game.offset.no_push) > 0 or p > game.pushable_players
			update_game_object(player[p])
		end
	end

	for f = 1, DRAW_DELAY do
		for p = 1, game.number_players do
			frame_buffer[f][player][p] = copytable(frame_buffer[f+1][player][p])
		end
		frame_buffer[f][projectiles] = copytable(frame_buffer[f+1][projectiles])
	end

	for p = 1, game.number_players do
		frame_buffer[DRAW_DELAY+1][player][p] = copytable(player[p])
	end
	frame_buffer[DRAW_DELAY+1][projectiles] = read_projectiles()

end


emu.registerafter( function()
	update_marvel_hitboxes()
end)


--------------------------------------------------------------------------------
-- draw the hitboxes

local function draw_hitbox(obj, entry, no_push_next_frame)
	local hb = obj[entry]
	local no_draw = {
		not DRAW_PUSHBOXES and hb.type == PUSH_BOX,
		not DRAW_THROWBOXES and (hb.type == THROW_BOX or hb.type == THROWABLE_BOX),
		obj.invulnerable and hb.type == VULNERABILITY_BOX,
		obj.unthrowable and hb.type == THROWABLE_BOX,
		obj.hurt and hb.type == THROW_BOX,
		obj.no_push and hb.type == PUSH_BOX,
		no_push_next_frame and hb.type == PUSH_BOX, --deprecate ASAP
	}
	for _, condition in ipairs(no_draw) do
		if condition == true then
			return
		end
	end

	if DRAW_MINI_AXIS then
		gui.drawline(hb.hval, hb.vval-MINI_AXIS_SIZE, hb.hval, hb.vval+MINI_AXIS_SIZE, outline[hb.type])
		gui.drawline(hb.hval-MINI_AXIS_SIZE, hb.vval, hb.hval+MINI_AXIS_SIZE, hb.vval, outline[hb.type])
		--gui.text(hb.hval, hb.vval, string.format("%02X", hb.id)) --debug
	end

	gui.box(hb.left, hb.top, hb.right, hb.bottom, fill[hb.type], outline[hb.type])
end


local function draw_axis(obj)
	if not obj or not obj.pos_x then
		return
	end
	
	gui.drawline(obj.pos_x, obj.pos_y-AXIS_SIZE, obj.pos_x, obj.pos_y+AXIS_SIZE, AXIS_COLOR)
	gui.drawline(obj.pos_x-AXIS_SIZE, obj.pos_y, obj.pos_x+AXIS_SIZE, obj.pos_y, AXIS_COLOR)
	--gui.text(obj.pos_x, obj.pos_y, string.format("%06X", obj.base)) --debug
end


local function render_marvel_hitboxes()
	gui.clearuncommitted()
	if not game or globals.game_phase == GAME_PHASE_NOT_PLAYING then
		return
	end

	if BLANK_SCREEN then
		gui.box(0, 0, emu.screenwidth(), emu.screenheight(), BLANK_COLOR)
	end

	for entry in ipairs(game.box_list) do
		for p = 1, game.number_players do
			local obj = frame_buffer[1][player][p]
			local no_push_next_frame = frame_buffer[2][player][p] and frame_buffer[2][player][p].no_push --deprecate ASAP
			if obj and obj[entry] then
				draw_hitbox(obj, entry, no_push_next_frame)
			end
		end

		for i in ipairs(frame_buffer[1][projectiles]) do
			local obj = frame_buffer[1][projectiles][i]
			if obj[entry] then
				draw_hitbox(obj, entry)
			end
		end
	end

	if DRAW_AXIS then
		for p = 1, game.number_players do
			draw_axis(frame_buffer[1][player][p])
		end
		for i,obj in ipairs(frame_buffer[1][projectiles]) do
			draw_axis(frame_buffer[1][projectiles][i])
		end
	end

end


gui.register( function()
	render_marvel_hitboxes()
end)


--------------------------------------------------------------------------------
-- hotkey functions

input.registerhotkey(1, function()
	BLANK_SCREEN = not BLANK_SCREEN
	render_marvel_hitboxes()
	print((BLANK_SCREEN and "activated" or "deactivated") .. " blank screen mode")
end)


input.registerhotkey(2, function()
	DRAW_AXIS = not DRAW_AXIS
	render_marvel_hitboxes()
	print((DRAW_AXIS and "showing" or "hiding") .. " object axis")
end)


input.registerhotkey(3, function()
	DRAW_MINI_AXIS = not DRAW_MINI_AXIS
	render_marvel_hitboxes()
	print((DRAW_MINI_AXIS and "showing" or "hiding") .. " hitbox axis")
end)


input.registerhotkey(4, function()
	DRAW_PUSHBOXES = not DRAW_PUSHBOXES
	render_marvel_hitboxes()
	print((DRAW_PUSHBOXES and "showing" or "hiding") .. " pushboxes")
end)


input.registerhotkey(5, function()
	DRAW_THROWBOXES = not DRAW_THROWBOXES
	render_marvel_hitboxes()
	print((DRAW_THROWBOXES and "showing" or "hiding") .. " throwboxes and throwable boxes")
end)


--------------------------------------------------------------------------------
-- initialize on game startup

local function whatversion(game)
	for base,version_set in pairs(game.pushbox_base) do
		for _,version in ipairs(version_set) do
			if emu.romname() == version then
				return base, version_set.apoc
			end
		end
	end
	print("unrecognized version (" .. emu.romname() .. "): cannot draw pushboxes")
	return nil
end


local function whatgame()
	game = nil
	for n, module in ipairs(profile) do
		if emu.romname() == module.game or emu.parentname() == module.game then
			print("drawing " .. module.game .. " hitboxes")
			game = module
			pushbox_base, apoc_value = whatversion(game)
			for p = 1, game.number_players do
				player[p] = {}
			end
			for f = 1, DRAW_DELAY + 1 do
				frame_buffer[f] = {}
				frame_buffer[f][player] = {}
				frame_buffer[f][projectiles] = {}
			end
			return
		end
	end
	print("not prepared for " .. emu.romname() .. " hitboxes")
end


emu.registerstart( function()
	whatgame()
end)