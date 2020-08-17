--TOADD
--ItemMorellosBane
--ItemWillBoltSpellBase
--ItemSoFBoltSpellBase
--MeleeOnlyItems
require("common.log")
module("HUtils", package.seeall, log.setup)
-- REQUIEREMENTS
local Orb = require("lol/Modules/Common/Orb")
local ts = require("lol/Modules/Common/simpleTS")
-- API
local _Core = _G.CoreEx
local ObjManager, EventManager, Input, Enums, Game, Renderer, Vector  = _Core.ObjectManager, _Core.EventManager, _Core.Input, _Core.Enums, _Core.Game, _Core.Renderer, _Core.Geometry.Vector
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
local Player = ObjManager.Player


local _Q = SpellSlots.Q
local _W = SpellSlots.W
local _E = SpellSlots.E
local _R = SpellSlots.R

-- FUNCTIONS

local function UseItemsCombo(target)	
	for i=SpellSlots.Item1, SpellSlots.Item6 do
		local _item = Player:GetSpell(i)
		if _item ~= nil and _item then
			-- BOTRK + HEXTECH GUNBLADE + RANDUIN
			if _item.Name == "ItemSwordOfFeastAndFamine" or _item.Name == "BilgewaterCutlass" or _item.Name == "HextechGunblade" or _item.Name == "RanduinsOmen" then
				if Player:GetSpellState(i) == SpellStates.Ready then
					if Player.Position:Distance(target.Position) <= _item.DisplayRange then
						Input.Cast(i, target)
					end
					break
				end
			end
		end
	end
end

local function UseItemsAuto()
for i=SpellSlots.Item1, SpellSlots.Item6 do
		local _item = Player:GetSpell(i)
		if _item ~= nil and _item then
			-- Auto Potion
			if _item.Name == "RegenerationPotion" or _item.Name == "ItemCrystalFlask" or _item.Name == "ItemDarkCrystalFlask" then
				if Player:GetSpellState(i) == SpellStates.Ready then
					if Player.Health <= (Player.MaxHealth*0.2) then
						Input.Cast(i)
					end
					break
				end
			end
		end
	end
end

-- EVENTS

function OnTeleport(hero, name, idk, duration, status)
	Game.PrintChat(hero.CharName.." "..name.." "..status)
end

local function OnTick()
	UseItemsAuto()
	local target = Orb.Mode.Combo and ts:GetTarget(1200, ts.Priority.LowestHealth)
	if target then
		UseItemsCombo(target)
	end
end

local function OnDraw()
	for s=_Q,_R do
		if Player:GetSpellState(s) == SpellStates.Ready then
			local srange = Player:GetSpell(s).DisplayRange
			local draw_S = Renderer.DrawCircle3D(Player.Position, srange, 30, 1, 0xFF0000FF)
		end
	end	
end

local function OnBuffGain(Player, buffInst)
	for i=SpellSlots.Item1, SpellSlots.Item6 do
		local _item = Player:GetSpell(i)
		if _item ~= nil and _item then
		-- Auto QSS
			if _item.Name == "QuicksilverSash" or _item.Name == "ItemMercurial" then
				if Player:GetSpellState(i) == SpellStates.Ready then
					if buffInst.IsCC then
						Input.Cast(i)
					end
				end
				break
			end
		end
	end
end

function OnLoad()
	EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	EventManager.RegisterCallback(Enums.Events.OnBuffGain, OnBuffGain)
	EventManager.RegisterCallback(Enums.Events.OnTeleport, OnTeleport)
	Orb.Load()
	Game.PrintChat("HUtils Loaded !")
	return true
end
