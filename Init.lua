--[[========================================================================================
	
	
	Author: Ferodra [Arenima - Alleria EU]
		Email: ferodra@gmx.de

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the 'Software'), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense copies of the 
	Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
    ========================================================================================]]

--[[
	This Addon provides a big, dynamic library of methods to instantly create unitframes for every need.

	'local *' and 'E.*' explaination:
		'local' defines the private scope in LUA
		'E' is our 'class' name in this case and lets us access everything defined within.
	
	Since we want to access some variables across our AddOn, we have to throw them into this private(/public) scope (local(/E)).
	
	Important Lua-Garbage note:
		Setting the value of any table via {} creates a NEW table and will contribute to generating garbage!
		To properly do this, empty a table with 'wipe(t)' and set values with: 'table.val = newvalue'
]]--

	
--[[===========================
		Init and Caching
=============================]]
local PlaySound = PlaySound
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata


local AddOnName, E							= ... -- AddOn-Name, Engine
local AceAddon = _G.LibStub('AceAddon-3.0')
---@class E
local AddOn = AceAddon:NewAddon(AddOnName, 'AceHook-3.0')
AddOn.AddOnName = AddOnName
AddOn.AddonVersion = GetAddOnMetadata(AddOnName, 'Version')

E[1] = AddOn
E[2] = {}

-- Expansions
AddOn.IsTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC -- not used
AddOn.IsCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
AddOn.IsWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
AddOn.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
AddOn.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

-- Add optional AddOns in the TOC section 'OptionalDeps'
AddOn.Libs = {
	['AceAddon'] 	= AceAddon,
	['Callbacks'] 	= LibStub('CallbackHandler-1.0'):New(E),
	['LSM']			= LibStub("LibSharedMedia-3.0")
}

-- Callback table
AddOn.Callbacks = {}

-- Global to access the API everywhere
_G['YGM'] = E
--------------------------------------------------

local AlertFrame = CreateFrame("Frame", nil, UIParent)
local LSM_Sounds = AddOn.Libs.LSM:HashTable('sound')
local LastPlayed = 0
local SoundPath = "Interface/AddOns/YouveGotMail/sounds/"
local SOUNDS = {
	["AOL Mailsound (English)"] = SoundPath .. "AOL_mailsound_en.mp3",
	["AOL Mailsound (German)"] = SoundPath .. "AOL_mailsound_de.mp3",
	["Notification 1"] = SoundPath .. "mailsound_notify_1.mp3",
	["Notification 2"] = SoundPath .. "mailsound_notify_2.mp3",
	["ICQ Mail"] = SoundPath .. "ICQ_mailsound_1.mp3",
	["ICQ Message 1"] = SoundPath .. "ICQ_dmsound_1.mp3",
	["ICQ Message 2"] = SoundPath .. "ICQ_dmsound_2.mp3",
	["Pedro"] = SoundPath .. "pedro.mp3",
	["Wow"] = SoundPath .. "wow.mp3",
	["Dun Dun Duuuun"] = SoundPath .. "dun_dun_duuun.mp3",
	["UwU"] = SoundPath .. "uwu.mp3",
	["Hello There"] = SoundPath .. "hellothere.mp3",
	["Was ist denn hier los?"] = SoundPath .. "was-ist-denn-hier-los.mp3",
	["What da dog doin?"] = SoundPath .. "what-da-dog-doin.mp3",
	["Gas Gas Gas"] = SoundPath .. "gas-gas-gas.mp3",
	["You what?"] = SoundPath .. "you-what.mp3",
	["E"] = SoundPath .. "e.mp3",
	["Markiplier Smash"] = SoundPath .. "markiplier-smash.mp3",
	["Metal Pipe"] = SoundPath .. "metal-pipe-clang.mp3",
	["Yippee!"] = SoundPath .. "yippee-meme-sound-effect.mp3",
}

do
	for k,v in pairs(SOUNDS) do
		AddOn.Libs.LSM:Register('sound', k, v)
	end
end

function AddOn:PlaySetSound()
	PlaySoundFile(self.Libs.LSM:Fetch('sound', self.db.global.SoundToUse) or SOUNDS[self.ConfigDefaults.global.SoundToUse], self.db.global.SoundChannel or 'Master')
end

local function OnEvent(self, event, arg1)
	if HasNewMail() and not self.LastState and LastPlayed + 2 < GetTime() then
		if not AddOn.db.global.AlwaysPlaySound and AlertFrame:IsEventRegistered("PLAYER_ENTERING_WORLD") then
			AlertFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end
		
		AddOn:PlaySetSound()
		self.LastState = true
		LastPlayed = GetTime()
	elseif not HasNewMail() then
		self.LastState = false
	end
end

function AddOn:GetTOCString(name)
    return GetAddOnMetadata(self.AddOnName, name)
end

function AddOn:OnInitialize()
	self:InitConfig()
end

function AddOn:OnEnable()
	AlertFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	AlertFrame:RegisterEvent("UPDATE_PENDING_MAIL")
	AlertFrame:SetScript("OnEvent", OnEvent)
end