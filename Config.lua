---@class E
local E = unpack(select(2, ...)) -- Engine

local GetAddOnMetadata = C_AddOns.GetAddOnMetadata

E.ConfigDefaults = {
    ['global'] = {
        ["SoundToUse"] = "Notification 2",
	    ["AlwaysPlaySound"] = true,
        ["SoundChannel"] = 'Master',
    }
}

SoundChannels = {
    [1] = 'Master',
    [2] = 'Music',
    [3] = 'SFX',
    [4] = 'Ambience',
    [5] = 'Dialog',
}


function E:UpdateConfig()
	if not E.db.global.AlwaysPlaySound then
		AlertFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	else
		if not AlertFrame:IsEventRegistered("PLAYER_ENTERING_WORLD") then
			AlertFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		end
	end
end

function E:ProfileUpdate()

end

function E:OnDatabaseShutdown()

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
	local LSMData = E.Libs.LSM:HashTable('sound')
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
	title:SetText(E:GetTOCString('Title'))
    local desc = self:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	desc:SetPoint("TOPLEFT", 16, -32)
	desc:SetText(E:GetTOCString('Notes'))

	local version = self:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	version:SetPoint("TOPRIGHT", -16, -16)
    version:SetText(string.format("Version %s", E.AddonVersion))
	
	local info = {}
	local SoundDropdown = CreateFrame("Frame", "YGMSoundDropdown", self, "UIDropDownMenuTemplate")
	SoundDropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -60)
	SoundDropdown:SetWidth(300)
	SoundDropdown.initialize = function()
		for k,v in ipairs(GetMediaTable()) do
			info.text = v
			info.value = v
			
			info.func = function(self)
				E.db.global.SoundToUse = self.value
				SoundDropdown.Text:SetText(self.value)
			end
			info.checked = info.value == E.db.global.SoundToUse
			UIDropDownMenu_AddButton(info)
		end
	end
    UIDropDownMenu_SetWidth(SoundDropdown, 200)
	
	SoundDropdown.Text:SetText(E.db.global.SoundToUse or E.ConfigDefaults.global.SoundToUse)

    local SoundDropdownTitle = self:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	SoundDropdownTitle:ClearAllPoints()
	SoundDropdownTitle:SetPoint("BOTTOMLEFT", SoundDropdown, "TOPLEFT", 15, 0)
    SoundDropdownTitle:SetText("Sound To Use")

     SoundDropdown:HookScript("OnEnter", function()
		ShowTooltip(SoundDropdown, "ANCHOR_RIGHT", "Sets which sound is played. This may also be something from another addon!")
	end)
	SoundDropdown:HookScript("OnLeave", function()
		GameTooltip:Hide()
	end)

    --------CHANNEL
    --------------------------------------------------
    local ChannelDropdown = CreateFrame("Frame", "YGMSoundDropdown", self, "UIDropDownMenuTemplate")
	ChannelDropdown:SetPoint("TOPLEFT", SoundDropdown, "BOTTOMLEFT", 0, -25)
	ChannelDropdown:SetWidth(300)
	ChannelDropdown.initialize = function()
		for k,v in ipairs(SoundChannels) do
			info.text = v
			info.value = v
			
			info.func = function(self)
				E.db.global.SoundChannel = self.value
				ChannelDropdown.Text:SetText(self.value)
			end
			info.checked = info.value == E.db.global.SoundChannel
			UIDropDownMenu_AddButton(info)
		end
	end
    UIDropDownMenu_SetWidth(ChannelDropdown, 110)
	
	ChannelDropdown.Text:SetText(E.db.global.SoundChannel or E.ConfigDefaults.global.SoundChannel)

    ChannelDropdown:HookScript("OnEnter", function()
		ShowTooltip(ChannelDropdown, "ANCHOR_RIGHT", "Controls which channel the sound is played on. Depending on your game's sound settings, it may not play at all. So make sure to test it after changing")
	end)
	ChannelDropdown:HookScript("OnLeave", function(btn)
		GameTooltip:Hide()
	end)

    local ChannelDropdownTitle = self:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	ChannelDropdownTitle:ClearAllPoints()
	ChannelDropdownTitle:SetPoint("BOTTOMLEFT", ChannelDropdown, "TOPLEFT", 15, 0)
    ChannelDropdownTitle:SetText("Channel")
    --------------------------------------------------
	
	local checkButton = CreateFrame("CheckButton", "YGMSoundCondition", self, "ChatConfigCheckButtonTemplate")
	checkButton:SetPoint("TOPLEFT", ChannelDropdown, "TOPLEFT", 13, -35)
	checkButton:SetSize(32, 32)
	checkButton:HookScript("OnClick", function(btn)
		local Checked = btn:GetChecked()
		E.db.global.AlwaysPlaySound = Checked
		E:UpdateConfig()
	end);
	checkButton:HookScript("OnEnter", function(btn)
		ShowTooltip(btn, "ANCHOR_RIGHT", "When enabled, the sound always is played after loading screens, when there still is pending mail.")
	end)
	checkButton:HookScript("OnLeave", function(btn)
		GameTooltip:Hide()
	end)
	checkButton:SetChecked(E.db.global.AlwaysPlaySound)
	
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
		E:PlaySetSound()
	end)
	
	self:SetScript("OnShow", nil)
end

function E:AddOptions()
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

function E:InitConfig()
    self.db	= LibStub('AceDB-3.0'):New('YGMDB', E.ConfigDefaults)
	
	self.db.RegisterCallback(self, 'OnProfileChanged', 'ProfileUpdate')
	self.db.RegisterCallback(self, 'OnProfileCopied', 'ProfileUpdate')
	self.db.RegisterCallback(self, 'OnProfileReset', 'ProfileUpdate')
	self.db.RegisterCallback(self, 'OnDatabaseShutdown', 'OnDatabaseShutdown')
    
    self:AddOptions()
end