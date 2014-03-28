-- Slam siegers to the ground
if not dfhack.isMapLoaded() then qerror('Map is not loaded.') end
if not ... then qerror('Please enter a creature ID.') end

local args = {...}
local unitSource = df.unit.find(tonumber(args[1]))
if not unitSource then qerror('crazed-invaders : Unit not found.') end

local invaders = {}
local targetId, unit, k

-- Todo more effect depending of the originating civ
local function rating(unit)
	local number = math.random(1, 3)
	return number
end

-- Gets all the invaders, not their leaders
for k, unit in ipairs(df.global.world.units.all) do
	if unit.flags1.active_invader and unit.relations.group_leader_id > -1 then	
		table.insert(invaders, unit.id) 
	end
end

if #invaders == 0 then qerror('dimension-pull: No invader found.') end

for i = 0, rating(unitSource) do
	targetId = invaders[math.random(1, #invaders)]
	dfhack.run_script('addsyndrome', 'SYNDROME_BERSERK', targetId)
end