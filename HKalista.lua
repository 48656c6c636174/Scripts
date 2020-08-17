require("common.log")
module("HKalista", package.seeall, log.setup)

local Orb = require("lol/Modules/Common/Orb")
local ts = require("lol/Modules/Common/simpleTS")

local _Core = _G.CoreEx
local ObjManager, EventManager, Input, Enums, Game, Renderer, Vector  = _Core.ObjectManager, _Core.EventManager, _Core.Input, _Core.Enums, _Core.Game, _Core.Renderer, _Core.Geometry.Vector
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
local Player = ObjManager.Player

local _Q = SpellSlots.Q
local _W = SpellSlots.W
local _E = SpellSlots.E
local _R = SpellSlots.R

local function E_Logic(target, buffCount)
	if buffCount > 0 and Player.TotalAD then
		local Ebasedmg = {20, 30, 40, 50, 60}
		local Estackdmg = {10, 14, 19, 25, 32}
		local Estackadmg = {0.2, 0.2375, 0.275, 0.3125, 0.35}
		local Ebaselvl = Ebasedmg[Player:GetSpell(_E).Level]
		local Estacklvl = Estackdmg[Player:GetSpell(_E).Level]
		local Estackalvl = Estackadmg[Player:GetSpell(_E).Level]
		local Etotaldmg = Ebaselvl + Player.TotalAD * 0.6 + (Estacklvl + Player.TotalAD * Estackalvl) * (buffCount-1)
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

local function Combo(target)
	local PlayerPos = Player.Position
	if Player:GetSpellState(_E) == SpellStates.Ready then
		local target = ts:GetTarget(1100,ts.Priority.LowestHealth)
		local buffCountSpear = countEStacks(target)
	end
	--[[if Player:GetSpellState(_Q) == SpellStates.Ready then
		local missiles = ObjManager.Get("ally", "missiles")
		for handle, obj in pairs(missiles) do        
			local _QMissile = obj.AsN       
		local _QMissile = Player:GetSpell(_Q):AsMissile(_Q)
		local _Qlogic = _QMissile.StartPos(Player.Position)
	end]]
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

			if dist <= 1100 and buffCountSpear and E_Logic(hero,buffCountSpear) > (hero.Health) then				
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
	end
end

local function OnDraw()
	local target = ts:GetTarget(1100,ts.Priority.LowestHealth)
	if target then 
		local E_Info = Renderer.DrawText(target.HealthBarScreenPos, Vector(100,100,0), 'E Damage: ' .. E_Logic(target,countEStacks(target)),  0xFFFFFFFF)
		local Target_HP = Renderer.DrawText(target.HealthBarScreenPos-Vector(0,-10,0), Vector(110,100,0), 'Target HP: ' .. target.Health,  0xFFFFFFFF)
	else 
		local Target_Lost = Renderer.DrawText(Player.HealthBarScreenPos, Vector(100,100,0), 'Target Lost',  0xFFFFFFFF)
	end
end

function OnLoad()
	if Player.CharName ~= "Kalista" then return false end 
	EventManager.RegisterCallback(Enums.Events.OnTick, OnTick)
	EventManager.RegisterCallback(Enums.Events.OnDraw, OnDraw)
	Orb.Load()
	Game.PrintChat("HKalista Loaded!")
	return true
end
