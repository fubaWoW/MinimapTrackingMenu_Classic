-- This AddOn is inspired by "TrackingEye" and "Tukui Tracking Menu" and of course World of Warcraft Retail itself! ;)

local AddOnName, AddOn = ...
local MinimapTrackingMenu = CreateFrame("Frame")
local MiniMapTrackingFrame = _G.MiniMapTrackingFrame
local Minimap = _G.Minimap
local tracking = MinimapCluster.Tracking or MinimapCluster.TrackingFrame or _G.MiniMapTrackingFrame or _G.MiniMapTracking

local TrackingSpells = {
	1494, -- Track Beasts (Hunter)
	2383, -- Find Herbs (Herbalism)
	2481, -- Find Treasure (Dwarf racial)
	2580, -- Find Minerals (Mining)
	5225, -- Track Humanoids (Druid)
	5500, -- Sense Demons (Warlock)
	5502, -- Sense Undead (Paladin)
	19878, -- Track Demons (Hunter)
	19879, -- Track Dragonkin (Hunter)
	19880, -- Track Elementals (Hunter)
	19882, -- Track Giants (Hunter)
	19883, -- Track Humanoids (Hunter)
	19884, -- Track Undead (Hunter)
	19885, -- Track Hidden (Hunter)
}

local ElvUI_menuList = {
	{
		text = _G.CHARACTER_BUTTON,
		func = function()
			ToggleCharacter("PaperDollFrame")
		end,
	},
	{
		text = _G.SPELLBOOK_ABILITIES_BUTTON,
		func = function()
			if not _G.SpellBookFrame:IsShown() then
				ShowUIPanel(_G.SpellBookFrame)
			else
				HideUIPanel(_G.SpellBookFrame)
			end
		end,
	},
	{
		text = _G.TALENTS_BUTTON,
		func = function()
			if not _G.TalentFrame then
				_G.TalentFrame_LoadUI()
			end

			if not TalentFrame:IsShown() then
				ShowUIPanel(TalentFrame)
			else
				HideUIPanel(TalentFrame)
			end
		end,
	},
	{ text = _G.CHAT_CHANNELS, func = _G.ToggleChannelFrame },
	{
		text = _G.TIMEMANAGER_TITLE,
		func = function()
			ToggleFrame(_G.TimeManagerFrame)
		end,
	},
	{ text = _G.SOCIAL_LABEL, func = ToggleFriendsFrame },
	{
		text = _G.GUILD,
		func = function()
			if IsInGuild() then
				ToggleFriendsFrame(3)
			else
				ToggleGuildFrame()
			end
		end,
	},
	{
		text = _G.MAINMENU_BUTTON,
		func = function()
			if not _G.GameMenuFrame:IsShown() then
				if _G.VideoOptionsFrame:IsShown() then
					_G.VideoOptionsFrameCancel:Click()
				elseif _G.AudioOptionsFrame:IsShown() then
					_G.AudioOptionsFrameCancel:Click()
				elseif _G.InterfaceOptionsFrame:IsShown() then
					_G.InterfaceOptionsFrameCancel:Click()
				end

				CloseMenus()
				CloseAllWindows()
				PlaySound(850) --IG_MAINMENU_OPEN
				ShowUIPanel(_G.GameMenuFrame)
			else
				PlaySound(854) --IG_MAINMENU_QUIT
				HideUIPanel(_G.GameMenuFrame)
				MainMenuMicroButton_SetNormal()
			end
		end,
	},
	{ text = _G.HELP_BUTTON, func = ToggleHelpFrame },
}

local function EasyMenu_Initialize( frame, level, menuList )
	for index = 1, #menuList do
		local value = menuList[index]
		if (value.text) then
			value.index = index;
			UIDropDownMenu_AddButton( value, level );
		end
	end
end

local EasyMenu = _G.EasyMenu or function(menuList, menuFrame, anchor, x, y, displayMode, autoHideDelay )
	if ( displayMode == "MENU" ) then
		menuFrame.displayMode = displayMode;
	end
	UIDropDownMenu_Initialize(menuFrame, EasyMenu_Initialize, displayMode, nil, menuList);
	ToggleDropDownMenu(1, nil, menuFrame, anchor, x, y, menuList, nil, autoHideDelay);
end

local function UpdateLastTracking(SpellID)
	if not MinimapTrackingMenuDB then
		MinimapTrackingMenuDB = {}
	end
	MinimapTrackingMenuDB.lastTrack = SpellID
end

local function ClearLastTracking()
	if not MinimapTrackingMenuDB then
		MinimapTrackingMenuDB = {}
	end
	MinimapTrackingMenuDB.lastTrack = nil
end

local function CastLastTrackingSpell()
	if MinimapTrackingMenuDB then
		local lastTrack = MinimapTrackingMenuDB.lastTrack
		if lastTrack and IsPlayerSpell(lastTrack) then
			CastSpellByID(lastTrack)
		end
	end
end

function AddOn:OnInitialize()
	if tracking == nil then
		return
	end

	tracking:SetFrameStrata(Minimap:GetFrameStrata())
	tracking:SetFrameLevel(Minimap:GetFrameLevel() + 5)

	AddOn.Button = CreateFrame("Button", "fuba_TrackingMenu_Button", tracking)
	AddOn.Button:SetAllPoints()
	AddOn.Button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	AddOn.Button:SetScript("OnClick", function()
		AddOn:OnButtonClick()
	end)

	AddOn.Button:RegisterEvent("MINIMAP_UPDATE_TRACKING")
	AddOn.Button:SetScript("OnEvent", function(_, event)
		if event == "MINIMAP_UPDATE_TRACKING" then
			AddOn:UpdateIcon()
		end
	end)

	AddOn.Menu = CreateFrame("Frame", "fuba_TrackingMenu_DropDown", UIParent, "UIDropDownMenuTemplate")
	AddOn.Menu:Hide()

	AddOn.MenuButtons = {}
	for i = 1, #TrackingSpells do
		local SpellID = TrackingSpells[i]
		table.insert(AddOn.MenuButtons, {
			_spellID = SpellID,
			text = GetSpellInfo(SpellID),
			icon = GetSpellTexture(SpellID),
			func = function()
				CastSpellByID(SpellID)
			end,
		})
	end
	table.sort(AddOn.MenuButtons, function(lh, rh)
		return strcmputf8i(lh.text, rh.text) < 0
	end)

	table.insert(AddOn.MenuButtons, 1, {
		_spellID = "none",
		text = MINIMAP_TRACKING_NONE,
		icon = "Interface\\MINIMAP\\TRACKING\\None",
		func = function()
			AddOn:CancelTracking()
		end,
	})

	table.insert(AddOn.MenuButtons, 2, {
		_spellID = "seperator",
		text = "",
		hasArrow = false,
		dist = 0,
		isTitle = true,
		isUninteractable = true,
		notCheckable = true,
		iconOnly = true,
		icon = "Interface\\Common\\UI-TooltipDivider-Transparent",
		tCoordLeft = 0,
		tCoordRight = 1,
		tCoordTop = 0,
		tCoordBottom = 1,
		tSizeX = 0,
		tSizeY = 8,
		tFitDropDownSizeX = true,
		iconInfo = {
			tCoordLeft = 0,
			tCoordRight = 1,
			tCoordTop = 0,
			tCoordBottom = 1,
			tSizeX = 0,
			tSizeY = 8,
			tFitDropDownSizeX = true,
		},
	})

	if not ElvUI then
		tracking:HookScript("OnHide", function()
			AddOn:ShowIcon()
		end)

		AddOn:ShowIcon()
	end
	AddOn:UpdateIcon()
end

function AddOn:CancelTracking()
	CancelTrackingBuff()
	ClearLastTracking()
end

function AddOn:OnButtonClick()
	local MouseButton = GetMouseButtonClicked()
	if MouseButton == "LeftButton" then
		AddOn:OpenMenu()
	elseif MouseButton == "RightButton" then
		AddOn:CancelTracking()
	end
end

function AddOn:UpdateIcon()
	if GetTrackingTexture() == nil then
		MiniMapTrackingIcon:SetTexture("Interface\\MINIMAP\\TRACKING\\None")
	end
end

function AddOn:OpenMenu(frame, left)
	local anchor
	local CurrentTexture = GetTrackingTexture()
	local VisibleButtons = {}
	for i = 1, #AddOn.MenuButtons do
		local MenuButton = AddOn.MenuButtons[i]
		if MenuButton._spellID == "none" then
			MenuButton.checked = not CurrentTexture
			table.insert(VisibleButtons, MenuButton)
		elseif MenuButton._spellID == "seperator" then
			table.insert(VisibleButtons, MenuButton)
		else
			if IsPlayerSpell(MenuButton._spellID) then
				MenuButton.checked = MenuButton.icon == CurrentTexture
				table.insert(VisibleButtons, MenuButton)
			end
		end
	end

	if frame then
		anchor = frame
	else
		anchor = tracking
	end
	if left then
		EasyMenu(VisibleButtons, AddOn.Menu, anchor, 0, 0, "MENU", 2)
	else
		EasyMenu(VisibleButtons, AddOn.Menu, anchor, -160, 0, "MENU", 2)
	end
end

function AddOn:ShowIcon()
	local HasTrackingSpells = false
	for i = 1, #TrackingSpells do
		if IsPlayerSpell(TrackingSpells[i]) then
			HasTrackingSpells = true
			break
		end
	end
	if HasTrackingSpells then
		tracking:Show()
	end
end

function AddOn:ElvUI_Minimap_OnMouseDown(btn)
	local menuFrame = _G["MinimapRightClickMenu"]
	if menuFrame then
		menuFrame:Hide()
	else
		return
	end
	local E, L, V, P, G = unpack(ElvUI)
	local position = self:GetPoint()
	if btn == "MiddleButton" then
		if position:match("LEFT") then
			E:DropDown(ElvUI_menuList, menuFrame)
		else
			E:DropDown(ElvUI_menuList, menuFrame, -160, 0)
		end
	elseif btn == "RightButton" then
		AddOn:OpenMenu("cursor")
	else
		_G.Minimap_OnClick(self)
	end
end

if ElvUI then
	local E, L, V, P, G = unpack(ElvUI)
	local M = E:GetModule("Minimap")
	if not M then
		return
	end
	M.Minimap_OnMouseDown = AddOn.ElvUI_Minimap_OnMouseDown
else
	Minimap:SetScript("OnMouseDown", function(self, btn)
		if btn == "RightButton" then
			AddOn:OpenMenu("cursor")
		else
			_G.Minimap_OnClick(self)
		end
	end)
end
Minimap:SetScript("OnMouseUp", function() end)

MinimapTrackingMenu:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		AddOn:OnInitialize()
	elseif event == "VARIABLES_LOADED" then
		if not MinimapTrackingMenuDB then
			MinimapTrackingMenuDB = {}
		end
	elseif event == "PLAYER_LOGIN" then
		CastLastTrackingSpell()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local _, _, spellID = ...
		if spellID and IsPlayerSpell(spellID) then
			if tContains(TrackingSpells, spellID) then
				UpdateLastTracking(spellID)
			end
		end
	elseif (event == "PLAYER_UNGHOST") or (event == "PLAYER_ALIVE") then
		CastLastTrackingSpell()
	end
end)

MinimapTrackingMenu:RegisterEvent("ADDON_LOADED")
MinimapTrackingMenu:RegisterEvent("VARIABLES_LOADED")
MinimapTrackingMenu:RegisterEvent("PLAYER_LOGIN")
MinimapTrackingMenu:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
MinimapTrackingMenu:RegisterEvent("PLAYER_UNGHOST")
MinimapTrackingMenu:RegisterEvent("PLAYER_ALIVE")