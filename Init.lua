local PlaySound = PlaySound
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local AddonName = 'YouveGotMail'
--------------------------------------------------

local AlertFrame = CreateFrame("Frame", UIParent)
local AddonVersion = GetAddOnMetadata(AddonName, 'Version')

local AddonDB
local Defaults = {
	["SoundToUse"] = "Notification 2",
	["AlwaysPlaySound"] = true,
}

local LibStub = LibStub
local LSM = LibStub("LibSharedMedia-3.0")
local LSM_Sounds = LSM:HashTable('sound')


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
		LSM:Register('sound', k, v)
	end
end

local function PlaySetSound()
	PlaySoundFile(LSM:Fetch('sound', AddonDB.SoundToUse) or SOUNDS[Defaults.SoundToUse], 'Master')
end

local function OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "YouveGotMail" then
		self:UnregisterEvent(event)
		
		if YGMDB == nil then
			YGMDB = {}
		end
		
		AddonDB = YGMDB
		for k,v in pairs(Defaults) do
			if AddonDB[k] == nil then
				AddonDB[k] = v
			end
		end
		
		self.IsInitialized = true
		return
	end
	
	if not self.IsInitialized then return end
	
	if HasNewMail() and not self.LastState and LastPlayed + 2 < GetTime() then
		if not AddonDB.AlwaysPlaySound and AlertFrame:IsEventRegistered("PLAYER_ENTERING_WORLD") then
			AlertFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end
		
		PlaySetSound()
		self.LastState = true
		LastPlayed = GetTime()
	elseif not HasNewMail() then
		self.LastState = false
	end
end

local function UpdateConfig()
	if not AddonDB.AlwaysPlaySound then
		AlertFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	else
		if not AlertFrame:IsEventRegistered("PLAYER_ENTERING_WORLD") then
			AlertFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		end
	end
end

local function SortByName(a, b)
	if not a or not b then return true end
	if a > b then
		return false
	else
		return true
	end
end

local function GetMediaTable()
	local LSMData = LSM:HashTable('sound')
	local Data = {}
	
	for k,v in pairs(LSMData) do
		Data[#Data+1] = k
	end
	
	table.sort(Data, SortByName)
	
	return Data
end

local function ShowTooltip(owner, anchor, text)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(text, 1, 1, 1)
	GameTooltip:Show()
end

local function ProvideOptions(self)
	
	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("You've Got Mail")

	local version = self:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	version:SetPoint("TOPRIGHT", -16, -16)
	version:SetText(string.format("Version %s", AddonVersion))
	
	local info = {}
	local dropdown = CreateFrame("Frame", "YGMSoundDropdown", self, "UIDropDownMenuTemplate")
	dropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -60)
	dropdown:SetWidth(300)
	dropdown.initialize = function()
		for k,v in ipairs(GetMediaTable()) do
			info.text = v
			info.value = v
			
			info.func = function(self)
				AddonDB.SoundToUse = self.value
				dropdown.Text:SetText(self.value)
			end
			info.checked = info.value == AddonDB.SoundToUse
			UIDropDownMenu_AddButton(info)
		end
	end
	
	dropdown.Text:SetText(AddonDB.SoundToUse or DefaultSound)
	
	local checkButton = CreateFrame("CheckButton", "YGMSoundCondition", self, "ChatConfigCheckButtonTemplate")
	checkButton:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 13, -35)
	checkButton:SetSize(32, 32)
	checkButton:HookScript("OnClick", function(btn)
		local Checked = btn:GetChecked()
		AddonDB.AlwaysPlaySound = Checked
		UpdateConfig()
	end);
	checkButton:HookScript("OnEnter", function(btn)
		ShowTooltip(btn, "ANCHOR_RIGHT", "When enabled, the sound always is played after loading screens, when there still is pending mail.")
	end)
	checkButton:HookScript("OnLeave", function(btn)
		GameTooltip:Hide()
	end)
	checkButton:SetChecked(AddonDB.AlwaysPlaySound)
	
	checkButton.title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	checkButton.title:ClearAllPoints()
	checkButton.title:SetPoint("LEFT", checkButton, "LEFT", 40, 0)
	checkButton.title:SetText("Always Play Sound")
	
	local test = CreateFrame("Button", "YGMTest", self, "UIPanelButtonTemplate")
	test:SetText("Test")
	test:SetWidth(177)
	test:SetHeight(24)
	test:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 250, -60)
	test:SetScript("OnClick", function()
		PlaySetSound()
	end)
	
	self:SetScript("OnShow", nil)
end

local function AddOptions()
	local panel = CreateFrame("Frame")
	panel.name = "You've Got Mail"
	
	
	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
	else
		local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name);
		Settings.RegisterAddOnCategory(category);
	end
	
	panel:SetScript("OnShow", ProvideOptions)
end

do
	AlertFrame.IsInitialized = false
	AlertFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	AlertFrame:RegisterEvent("UPDATE_PENDING_MAIL")
	AlertFrame:RegisterEvent("ADDON_LOADED")
	AlertFrame:SetScript("OnEvent", OnEvent)
	
	AddOptions()
end