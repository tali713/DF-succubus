-- Test if the succubus is able to learn a power
--[[
	This script is uses the reaction complete job and not reaction trigger.
	It will add extra requirements and simulate a canceled reaction if needed.

	The syndromes related to the powers have either the MAJOR_POWER or MINOR_POWER class?
	If the worker already have a syndrome of this class upon attempting to acquire a new power, the script will not add the new power.
	Then the reagents are saved to avoid spoiling.

	Ran upon map load for a succubus civ.

	@requires unit/syndrome-change : https://github.com/Pheosics/roses_collection/blob/master/Scripts/raw/scripts/unit/syndrome-change.lua
	@author Boltgun
]]
local eventful = require 'plugins.eventful'
local utils = require 'utils'

--http://lua-users.org/wiki/StringRecipes  (removed indents since I am not using them)
function wrap(str, limit)--, indent, indent1)
	--indent = indent or ""
	--indent1 = indent1 or indent
	local limit = limit or 72
	local here = 1 ---#indent1
	return str:gsub("(%s+)()(%S+)()",	--indent1..str:gsub(
							function(sp, st, word, fi)
								if fi-here > limit then
									here = st -- - #indent
									return "\n"..word --..indent..word
								end
							end)
end

-- Simulate a canceled reaction message, save the reagents
local function cancelReaction(reaction, unit, input_reagents, message)
	local lines = utils.split_string(wrap(
			string.format("%s, %s cancels %s: %s.", dfhack.TranslateName(dfhack.units.getVisibleName(unit)), dfhack.units.getProfessionName(unit), reaction.name, message)
		) , NEWLINE)
	for _, v in ipairs(lines) do
		dfhack.gui.showAnnouncement(v, COLOR_RED)
	end

	for _, v in ipairs(input_reagents or {}) do
		v.flags.PRESERVE_REAGENT = true
	end
end

-- Make sure that there is not already a power on the unit.
function hasSyndromeClass(unit, isMajor)
	local synClass
	if(isMajor) then
		synClass = 'MAJOR_POWER'
	else
		synClass = 'MINOR_POWER'
	end

	for i,unitSyndrome in ipairs(unit.syndromes.active) do
		local syndrome = df.syndrome.find(unitSyndrome.type)
			for _,class in ipairs(syndrome.syn_class) do
				if class.value == synClass then
					return true
				end
			end
		end
	return false
end

-- Adds the power on the unit
function activatePower(unit, code)
	local synName

	if code == 'LUA_HOOK_SUCCUBUS_UPGRADE_FIRE_SECRET' then
		synName = 'Pyromaniac (fireballs, directed ash, firejet)'
		synMessageName = 'the secrets of hellfire'
	elseif code == 'LUA_HOOK_SUCCUBUS_UPGRADE_LUST_SECRET' then
		synName = 'Courtesan (pheromones, crowd control)'
		synMessageName = 'the secrets of lust'
	elseif code == 'LUA_HOOK_SUCCUBUS_UPGRADE_DEPRAVITY_SECRET' then
		synName = 'Debauchee (support allies)'
		synMessageName = 'the secrets of depravity'
	elseif code == 'LUA_HOOK_SUCCUBUS_UPGRADE_PHASING' then
		synName = 'Dimensional Phasing (local teleport)'
		synMessageName = 'dimensional phasing'
	elseif code == 'LUA_HOOK_SUCCUBUS_UPGRADE_FACE_MELTER' then
		synName = 'Face melter'
		synMessageName = 'face melter'
	elseif code == 'LUA_HOOK_SUCCUBUS_UPGRADE_SLAM' then
		synName = 'Abyssal Gravity'
		synMessageName = 'Abyssal Gravity'
	end

	dfhack.run_script('modtools/add-syndrome', '-target', unit.id, '-syndrome', synName, '-resetPolicy', 'DoNothing')
	announcement(unit, synMessageName)
end

-- Adds a message telling the user that this was a success.
function announcement(unit, synName)
	local lines = utils.split_string(wrap(
			string.format("%s has learned %s.", dfhack.TranslateName(dfhack.units.getVisibleName(unit)), synName)
		) , NEWLINE)
	for _, v in ipairs(lines) do
		dfhack.gui.showAnnouncement(v, COLOR_WHITE)
	end
end

-- Added on the reaction complete events, check for the class, cancels if found, add the syndrome otherwise
eventful.onReactionComplete.succubusPower = function(reaction, reaction_product, unit, input_items, input_reagents, output_items, call_native)
	local isMajor, message

	if 
		reaction.code == 'LUA_HOOK_SUCCUBUS_UPGRADE_FIRE_SECRET' or
		reaction.code == 'LUA_HOOK_SUCCUBUS_UPGRADE_LUST_SECRET' or
		reaction.code == 'LUA_HOOK_SUCCUBUS_UPGRADE_DEPRAVITY_SECRET'
	then
		isMajor = true
		message = 'already have a major power'
	elseif
		reaction.code == 'LUA_HOOK_SUCCUBUS_UPGRADE_PHASING' or
		reaction.code == 'LUA_HOOK_SUCCUBUS_FACE_MELTER' or 
		reaction.code == 'LUA_HOOK_SUCCUBUS_SLAM'
	then
		isMajor = false
		message = 'already have a minor power'
	else
		-- Not a reaction handled by this script, abort
		return
	end

	if hasSyndromeClass(unit, isMajor) then
		cancelReaction(reaction, unit, input_reagents, message)
	else
		activatePower(unit, reaction.code)
	end
end

print("Succubus power reactions: Loaded.")
