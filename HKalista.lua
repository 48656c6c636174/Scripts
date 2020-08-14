require("common.log")
module("HKalista", package.seeall, log.setup)

local Orb = require("lol/Modules/Common/Orb")
local ts = require("lol/Modules/Common/simpleTS")

local _Core = _G.CoreEx
local ObjManager, EventManager, Input, Enums, Game  = _Core.ObjectManager, _Core.EventManager, _Core.Input, _Core.Enums, _Core.Game
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
local Player = ObjManager.Player

local _Q = SpellSlots.Q
local _W = SpellSlots.W
local _E = SpellSlots.E
local _R = SpellSlots.R

local function E_Logic(target, buffCount)
	if buffCount > 0 and Player.BonusAD then
		local Ebasedmg = {20, 30, 40, 50, 60}
		local Estackdmg = {10, 14, 19, 25, 32}
		local Estackadmg = {0.2, 0.2375, 0.275, 0.3125, 0.35}
		local Ebaselvl = Ebasedmg[Player:GetSpell(_E).Level]
		local Estacklvl = Estackdmg[Player:GetSpell(_E).Level]
		local Estackalvl = Estackadmg[Player:GetSpell(_E).Level]
		local Etotaldmg = Ebaselvl + Player.TotalAD * 0.6 + (Estacklvl + Player.TotalAD * Estackalvl) * buffCount
		return Etotaldmg * (100.0 / (100 + target.Armor ) )
	else
		return 0
	end
end

local function countEStacks(target) 
	local ai = target.AsAI
    if ai and ai.IsValid then
		for i = 0, ai.BuffCount do
			local buff = ai:GetBuff(i)
			if buff then
				if buff.Name == "kalistaexpungemarker" then
					if buff.Count ~= nil then
						return buff.Count
					end
				end
			end
		end
	end

	return 0
end

local function UseItems(target)	
	for i=SpellSlots.Item1, SpellSlots.Item6 do
		local _item = Player:GetSpell(i)
		if _item ~= nil and _item then
			local itemInfo = _item.Name

			if itemInfo == "ItemSwordOfFeastAndFamine" or itemInfo == "BilgewaterCutlass" then
				if Player:GetSpellState(i) == SpellStates.Ready then
					Input.Cast(i, target)
				end
				break
			end
		end
	end
end

local function Combo(target)
	if Player:GetSpellState(_E) == SpellStates.Ready then
		local target = ts:GetTarget(1200,ts.Priority.LowestHealth)
		local buffCountSpear = countEStacks(target)
	end
end

local function AutoE()
	local enemies = ObjManager.Get("enemy", "heroes")
	local myPos, myRange = Player.Position, (Player.AttackRange + Player.BoundingRadius)	
	
	if Player:GetSpellState(_E) ~= SpellStates.Ready then return end

	for handle, obj in pairs(enemies) do        
		local hero = obj.AsHero        
		if hero and hero.IsTargetable then
			local buffCountSpear = countEStacks(hero)
			local dist = myPos:Distance(hero.Position)

			if dist <= 1200 and buffCountSpear and E_Logic(hero,buffCountSpear) > (hero.Health) then				
				Input.Cast(_E)      
			end
		end		
	end	
end 

local function OnTick()	
	AutoE()
	local target = Orb.Mode.Combo and ts:GetTarget(Player.AttackRange + Player.BoundingRadius, ts.Priority.LowestHealth)
	if target then 
		Combo(target)
		if Player.Position:Distance(target.Position) <= 550 then
			UseItems(target)
		end
	end
end


function OnLoad()
    if not Player.CharName == "Kalista" then return false end
	EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	Orb.Load()
	Orb.Setting.Drawing.BoundingRadius.EnemyMinion.Active = false
	Game.PrintChat("HKalista Loaded!")
	return true
end
