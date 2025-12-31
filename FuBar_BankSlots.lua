-- Global addon object
BankSlotsFu = nil

-- Required libraries
local tablet = AceLibrary("Tablet-2.0")
local dewdrop = AceLibrary("Dewdrop-2.0")

-- Localization table
local L = {
	TOOLTIP_TITLE = "Bank",
	TOOLTIP_TEXT = "Free Slots:",
	HINT_BANK_OPEN = "Right-click for options.",
	HINT_BANK_CLOSED = "Open the bank to see slot details.",
	FORMAT = "%d / %d",
	MENU_TEXT_COLOR = "Text Color",
	COLOR_WHITE = "White",
	COLOR_GREEN = "Green",
	COLOR_YELLOW = "Yellow",
	PREFIX_TEXT = "Bank: ",
	NOT_AVAILABLE = "*",
}

-- Color mapping
local colorMap = {
	white = "|cffffffff",
	green = "|cff00ff00",
	yellow = "|cffffff00",
}

-- Main addon definition
BankSlotsFu = AceLibrary("AceAddon-2.0"):new("FuBarPlugin-2.0", "AceEvent-2.0", "AceDB-2.0")

-- FuBar Plugin properties
BankSlotsFu.hasIcon = true
BankSlotsFu.canHideText = true
BankSlotsFu.hasNoColor = true
BankSlotsFu.cannotDetachTooltip = true

-- Addon state
BankSlotsFu.isBankOpen = false

-----------------------------------------------------------------------
-- Addon Methods
-----------------------------------------------------------------------

function BankSlotsFu:OnInitialize()
	self:RegisterDB("FuBar_BankSlotsDB")
	self:RegisterDefaults("profile", {
		textColor = "white",
	})
	self:SetIcon("Interface\\Icons\\INV_Box_01")
end

function BankSlotsFu:OnEnable()
	self:RegisterEvent("BANKFRAME_OPENED", "HandleBankOpened")
	self:RegisterEvent("BANKFRAME_CLOSED", "HandleBankClosed")

	-- Check if bank is already open on login/reload
	if BankFrame:IsVisible() then
		self:HandleBankOpened()
	else
		self:Update() -- Initial update to show "N/A"
	end
end

function BankSlotsFu:OnDisable()
	self:UnregisterAllEvents()
end

function BankSlotsFu:HandleBankOpened()
	self.isBankOpen = true
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", "Update")
	self:Update()
end

function BankSlotsFu:HandleBankClosed()
	self.isBankOpen = false
	-- FIX: Check if the event is registered before unregistering it.
	if self:IsEventRegistered("PLAYERBANKSLOTS_CHANGED") then
		self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
	end
	self:Update()
end

-- Helper function to get slot counts
function BankSlotsFu:GetSlotCount()
	local freeSlots, totalSlots = 0, 0
	-- Bank (-1) and bank bags (5-11)
	local bankBags = {-1, 5, 6, 7, 8, 9, 10, 11}
	for _, i in ipairs(bankBags) do
		local numContainerSlots = GetContainerNumSlots(i)
		if numContainerSlots and numContainerSlots > 0 then
			totalSlots = totalSlots + numContainerSlots
			for slot = 1, numContainerSlots do
				if not GetContainerItemLink(i, slot) then
					freeSlots = freeSlots + 1
				end
			end
		end
	end
	return freeSlots, totalSlots
end

-- Text update function
function BankSlotsFu:OnTextUpdate()
	if not self.isBankOpen then
		self:SetText(L.NOT_AVAILABLE)
		return
	end

	local freeSlots, totalSlots = self:GetSlotCount()
	local prefix = L.PREFIX_TEXT
	local colorCode = colorMap[self.db.profile.textColor] or colorMap.white
	local numberString = string.format(L.FORMAT, freeSlots, totalSlots)
	local finalText = prefix .. colorCode .. numberString .. "|r"

	self:SetText(finalText)
end

-- Tooltip update function
function BankSlotsFu:OnTooltipUpdate()
	-- If the bank is closed, display "N/A" and a hint, then stop.
	if not self.isBankOpen then
		local cat = tablet:AddCategory(
			'text', L.TOOLTIP_TITLE,
			'columns', 2
		)
		cat:AddLine(
			'text', L.TOOLTIP_TEXT,
			'text2', L.NOT_AVAILABLE
		)
		tablet:SetHint(L.HINT_BANK_CLOSED)
		return -- Stop execution to prevent errors.
	end

	-- If bank is open, proceed with showing full details.
	local freeSlots, totalSlots = self:GetSlotCount()

	local cat = tablet:AddCategory(
		'text', L.TOOLTIP_TITLE,
		'columns', 2,
		'child_textR', 1, 'child_textG', 1, 'child_textB', 1,
		'child_text2R', 1, 'child_text2G', 1, 'child_text2B', 1
	)

	cat:AddLine(
		'text', L.TOOLTIP_TEXT,
		'text2', string.format(L.FORMAT, freeSlots, totalSlots)
	)

	tablet:SetHint(L.HINT_BANK_OPEN)
end

-- Menu request function
function BankSlotsFu:OnMenuRequest(level, value)
	if level == 1 then
		dewdrop:AddLine()
		dewdrop:AddLine(
			'text', L.MENU_TEXT_COLOR,
			'hasArrow', true,
			'value', 'color_menu'
		)
	elseif level == 2 and value == 'color_menu' then
		dewdrop:AddLine(
			'text', L.COLOR_WHITE,
			'isRadio', true,
			'checked', self.db.profile.textColor == 'white',
			'func', function()
				self.db.profile.textColor = 'white'
				self:Update()
			end,
			'closeWhenClicked', true
		)
		dewdrop:AddLine(
			'text', L.COLOR_GREEN,
			'isRadio', true,
			'checked', self.db.profile.textColor == 'green',
			'func', function()
				self.db.profile.textColor = 'green'
				self:Update()
			end,
			'closeWhenClicked', true
		)
		dewdrop:AddLine(
			'text', L.COLOR_YELLOW,
			'isRadio', true,
			'checked', self.db.profile.textColor == 'yellow',
			'func', function()
				self.db.profile.textColor = 'yellow'
				self:Update()
			end,
			'closeWhenClicked', true
		)
	end
end
