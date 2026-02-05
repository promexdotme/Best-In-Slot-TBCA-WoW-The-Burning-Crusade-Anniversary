local LibExtraTip = _G.LibStub and _G.LibStub("LibExtraTip-1", true) or nil
ExoLink.BIS = ExoLink.BIS or {}
ExoLink.Items = ExoLink.Items or {}

local DEFAULT_SETTINGS = {
	maxPhase = 1,
	hitCapped = false,
	showPercent = true,
	minimap = true,
	window = false,
}

ExoLink_BISDB = ExoLink_BISDB or {}
for k, v in pairs(DEFAULT_SETTINGS) do
	if ExoLink_BISDB[k] == nil then
		ExoLink_BISDB[k] = v
	end
end

local addonName, addonTable = ...
local iconpath = "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes"
local iconCutoff = 6
local tooltipHooked = false
local configFrame
local minimapButton

local function iconOffset(col, row)
	local offsetString = (col * 64 + iconCutoff) .. ":" .. ((col + 1) * 64 - iconCutoff)
	return offsetString .. ":" .. (row * 64 + iconCutoff) .. ":" .. ((row + 1) * 64 - iconCutoff)
end

local function addLine(tooltip, text, r, g, b, embed)
	tooltip:AddLine(text, r, g, b)
end

local function addDoubleLine(tooltip, left, right, lr, lg, lb, rr, rg, rb, embed)
	tooltip:AddDoubleLine(left, right, lr, lg, lb, rr, rg, rb)
end

local function applyMinimapVisibility()
	if not minimapButton then
		return
	end
	if ExoLink_BISDB.minimap then
		minimapButton:Show()
	else
		minimapButton:Hide()
	end
end

local function updateConfigUI()
	if not configFrame then
		return
	end
	local v = clampPhase(ExoLink_BISDB.maxPhase)
	if configFrame.phaseValue then
		configFrame.phaseValue:SetText(tostring(v))
	end
	if configFrame.phaseDropdown then
		UIDropDownMenu_SetSelectedValue(configFrame.phaseDropdown, v)
		UIDropDownMenu_SetText(configFrame.phaseDropdown, tostring(v))
	end
	if configFrame.hitcap then
		configFrame.hitcap:SetChecked(ExoLink_BISDB.hitCapped)
	end
	if configFrame.percent then
		configFrame.percent:SetChecked(ExoLink_BISDB.showPercent)
	end
	if configFrame.minimap then
		configFrame.minimap:SetChecked(ExoLink_BISDB.minimap)
	end
end

local function createConfigUI()
	if configFrame then
		return
	end

	local f = CreateFrame("Frame", "ExoLinkBISConfig", UIParent, "BasicFrameTemplateWithInset")
	f:SetSize(280, 200)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)

	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.title:SetPoint("CENTER", f.TitleBg, "CENTER")
	f.title:SetText("FatExoLink BiS Settings")

	local phaseLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	phaseLabel:SetPoint("TOPLEFT", 16, -40)
	phaseLabel:SetText("Max Phase")

	local phaseValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	phaseValue:SetPoint("LEFT", phaseLabel, "RIGHT", 8, 0)
	phaseValue:SetText("1")
	f.phaseValue = phaseValue

	local dropdown = CreateFrame("Frame", "ExoLinkBISPhaseDropdown", f, "UIDropDownMenuTemplate")
	dropdown:SetPoint("TOPLEFT", phaseLabel, "BOTTOMLEFT", -12, -6)
	UIDropDownMenu_SetWidth(dropdown, 80)
	UIDropDownMenu_JustifyText(dropdown, "LEFT")
	UIDropDownMenu_Initialize(dropdown, function(self, level)
		for i = 1, 5 do
			local info = UIDropDownMenu_CreateInfo()
			info.text = tostring(i)
			info.value = i
			info.func = function()
				ExoLink_BISDB.maxPhase = i
				updateConfigUI()
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end)
	f.phaseDropdown = dropdown

	local hitcap = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	hitcap:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 16, -6)
	hitcap.Text:SetText("HitCapped")
	hitcap:SetScript("OnClick", function(self)
		ExoLink_BISDB.hitCapped = self:GetChecked() and true or false
	end)
	f.hitcap = hitcap

	local percent = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	percent:SetPoint("TOPLEFT", hitcap, "BOTTOMLEFT", 0, -4)
	percent.Text:SetText("Show Percent")
	percent:SetScript("OnClick", function(self)
		ExoLink_BISDB.showPercent = self:GetChecked() and true or false
	end)
	f.percent = percent

	local minimap = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	minimap:SetPoint("TOPLEFT", percent, "BOTTOMLEFT", 0, -4)
	minimap.Text:SetText("Show Minimap Button")
	minimap:SetScript("OnClick", function(self)
		ExoLink_BISDB.minimap = self:GetChecked() and true or false
		applyMinimapVisibility()
	end)
	f.minimap = minimap

	configFrame = f
	updateConfigUI()
end

local function createMinimapButton()
	if minimapButton or not Minimap then
		return
	end

	local btn = CreateFrame("Button", "ExoLinkBIS_MinimapButton", Minimap)
	btn:SetSize(32, 32)
	btn:SetFrameStrata("MEDIUM")
	btn:SetMovable(true)
	btn:EnableMouse(true)
	btn:RegisterForDrag("LeftButton")
	btn:SetClampedToScreen(true)
	btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	btn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
	btn:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	btn:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	local icon = btn:CreateTexture(nil, "BACKGROUND")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER")
	icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
	btn.icon = icon

	local border = btn:CreateTexture(nil, "OVERLAY")
	border:SetSize(54, 54)
	border:SetPoint("TOPLEFT")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	btn.border = border

	btn:SetScript("OnClick", function()
		createConfigUI()
		if configFrame:IsShown() then
			configFrame:Hide()
			ExoLink_BISDB.window = false
		else
			configFrame:Show()
			ExoLink_BISDB.window = true
			updateConfigUI()
		end
	end)

	minimapButton = btn
	applyMinimapVisibility()
end

local SPEC_TO_CLASS = {
	Aff = "WARLOCK",
	Dest = "WARLOCK",
	Arc = "MAGE",
	Fire = "MAGE",
	BM = "HUNTER",
	SV = "HUNTER",
	Bear = "DRUID",
	Cat = "DRUID",
	Owl = "DRUID",
	Tree = "DRUID",
	Rog = "ROGUE",
	Shad = "PRIEST",
	Arms = "WARRIOR",
	Fury = "WARRIOR",
	Tank = "WARRIOR",
}

local function clampPhase(phase)
	phase = tonumber(phase) or DEFAULT_SETTINGS.maxPhase
	if phase < 1 then
		return 1
	end
	if phase > 5 then
		return 5
	end
	return phase
end

local function getBaseline(row, maxPhase, hitCapped)
	local arr = hitCapped and row.mh or row.m
	if not arr then
		return nil
	end
	return arr[maxPhase]
end

local function getValue(row, hitCapped)
	if hitCapped then
		return row.h or 0
	end
	return row.e or 0
end

local function formatLine(row, settings)
	local spec = row.s or "?"
	local slot = row.sl or ""
	local phase = row.p or 0
	local rank = row.r or 0
	local phaseRank = "P" .. phase .. "-R" .. rank

	local left = spec
	if slot ~= "" then
		left = left .. " " .. slot
	end
	left = left .. " " .. phaseRank

	if not settings.showPercent then
		return left, ""
	end

	local num = getValue(row, settings.hitCapped)
	local denom = getBaseline(row, settings.maxPhase, settings.hitCapped)
	if not denom or denom <= 0 or not num or num <= 0 then
		return left, "n/a"
	end

	local pct = (num / denom) * 100
	local pctRounded = math.floor(pct + 0.5)
	return left, tostring(pctRounded) .. "%"
end

local function sortRows(a, b)
	local ca = SPEC_TO_CLASS[a.s] or "ZZZ"
	local cb = SPEC_TO_CLASS[b.s] or "ZZZ"
	if ca ~= cb then
		return ca < cb
	end
	local sa = a.s or ""
	local sb = b.s or ""
	if sa ~= sb then
		return sa < sb
	end
	local ra = a.r or 0
	local rb = b.r or 0
	if ra ~= rb then
		return ra < rb
	end
	local pa = a.p or 0
	local pb = b.p or 0
	if pa ~= pb then
		return pa < pb
	end
	local sla = a.sl or ""
	local slb = b.sl or ""
	return sla < slb
end

local function buildExtraTip(tooltip, rows)
	if not rows or #rows == 0 then
		return
	end

	local r, g, b = .9, .8, .5
	local settings = ExoLink_BISDB
	settings.maxPhase = clampPhase(settings.maxPhase)

	addLine(tooltip, " ", r, g, b, true)
	addLine(
		tooltip,
		("BiS (maxPhase=%d, HitCapped=%s)"):format(settings.maxPhase, settings.hitCapped and "Y" or "N"),
		r,
		g,
		b,
		true
	)

	local filtered = {}
	for _, row in ipairs(rows) do
		if row.p and row.p == settings.maxPhase then
			table.insert(filtered, row)
		end
	end

	table.sort(filtered, sortRows)

	for _, row in ipairs(filtered) do
		local left, right = formatLine(row, settings)
		local class = SPEC_TO_CLASS[row.s]
		local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
		local classfontstring = ""

		if class and CLASS_ICON_TCOORDS then
			local coords = CLASS_ICON_TCOORDS[class]
			classfontstring = "|T" .. iconpath .. ":14:14:::256:256:" .. iconOffset(coords[1] * 4, coords[3] * 4) .. "|t "
		end

		if color then
			addDoubleLine(tooltip, classfontstring .. left, right, color.r, color.g, color.b, 1, 1, 1, true)
		else
			addDoubleLine(tooltip, classfontstring .. left, right, 1, 1, 1, 1, 1, 1, true)
		end
	end

	addLine(tooltip, " ", r, g, b, false)
end

local function buildLegacyTip(tooltip, entry)
	local r, g, b = .9, .8, .5
	addLine(tooltip, " ", r, g, b, true)
	addLine(tooltip, "# BiS for:  ( NeedHit vs HitCap )", r, g, b, true)

	for k, v in pairs(entry) do
		local bisEntry = ExoLink.BIS[k]
		if bisEntry then
			local class = bisEntry.class:upper()
			local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
			local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
			local classfontstring = ""
			if coords then
				classfontstring = "|T" .. iconpath .. ":14:14:::256:256:" .. iconOffset(coords[1] * 4, coords[3] * 4) .. "|t"
			end

			local displayText = bisEntry.class .. " " .. bisEntry.spec
			addDoubleLine(tooltip, classfontstring .. " " .. displayText, v, color.r, color.g, color.b, 1, 1, 1, true)
		end
	end

	addLine(tooltip, " ", r, g, b, false)
end

local function onTooltipSetItem(tooltip, itemLink, quantity)
	if not itemLink and tooltip and tooltip.GetItem then
		_, itemLink = tooltip:GetItem()
	end
	if not itemLink then
		return
	end

	local itemString = string.match(itemLink, "item[%-?%d:]+")
	if not itemString then
		return
	end

	local itemId = tonumber(({ string.split(":", itemString) })[2])
	if not itemId then
		return
	end

	if ExoLink_BiSData and ExoLink_BiSData.byItem then
		local rows = ExoLink_BiSData.byItem[itemId]
		if rows then
			buildExtraTip(tooltip, rows)
			return
		end
	end

	local itemIdStr = tostring(itemId)
	if ExoLink.Items[itemIdStr] then
		buildLegacyTip(tooltip, ExoLink.Items[itemIdStr])
	end
end

local function safeOnTooltipSetItem(...)
	pcall(onTooltipSetItem, ...)
	return nil
end

local eventframe = CreateFrame("FRAME",addonName.."Events")

local function onEvent(self,event,arg)
    if event == "PLAYER_ENTERING_WORLD" then
        eventframe:UnregisterEvent("PLAYER_ENTERING_WORLD")
		if not tooltipHooked then
			tooltipHooked = true
			local tooltips = { GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip }
			for _, tt in ipairs(tooltips) do
				if tt and tt.HookScript then
					tt:HookScript("OnTooltipSetItem", safeOnTooltipSetItem)
				end
			end
		end

		createMinimapButton()
		if ExoLink_BISDB.window then
			createConfigUI()
			configFrame:Show()
		end
    end
end

eventframe:RegisterEvent("PLAYER_ENTERING_WORLD")
eventframe:SetScript("OnEvent", onEvent)

local function printStatus()
	local s = ExoLink_BISDB
	DEFAULT_CHAT_FRAME:AddMessage(
		("BiS settings: maxPhase=%d, hitCapped=%s, showPercent=%s"):format(
			tonumber(s.maxPhase) or 1,
			s.hitCapped and "Y" or "N",
			s.showPercent and "Y" or "N"
		)
	)
end

SLASH_BIS1 = "/bis"
function SlashCmdList.BIS(msg)
	msg = (msg or ""):lower()
	if msg == "on" then
		ExoLink_BISDB.minimap = true
		applyMinimapVisibility()
		return
	elseif msg == "off" then
		ExoLink_BISDB.minimap = false
		applyMinimapVisibility()
		if configFrame then
			configFrame:Hide()
			ExoLink_BISDB.window = false
		end
		return
	end

	createConfigUI()
	if configFrame:IsShown() then
		configFrame:Hide()
		ExoLink_BISDB.window = false
	else
		configFrame:Show()
		ExoLink_BISDB.window = true
		updateConfigUI()
	end
end

SLASH_BISPHASE1 = "/bisphase"
function SlashCmdList.BISPHASE(msg)
	local n = tonumber(msg)
	if not n then
		printStatus()
		return
	end
	ExoLink_BISDB.maxPhase = clampPhase(n)
	updateConfigUI()
	printStatus()
end

SLASH_BISHITCAP1 = "/bishitcap"
function SlashCmdList.BISHITCAP(msg)
	msg = (msg or ""):lower()
	if msg == "on" or msg == "1" or msg == "true" then
		ExoLink_BISDB.hitCapped = true
	elseif msg == "off" or msg == "0" or msg == "false" then
		ExoLink_BISDB.hitCapped = false
	else
		ExoLink_BISDB.hitCapped = not ExoLink_BISDB.hitCapped
	end
	updateConfigUI()
	printStatus()
end

SLASH_BISPERCENT1 = "/bispercent"
function SlashCmdList.BISPERCENT(msg)
	msg = (msg or ""):lower()
	if msg == "on" or msg == "1" or msg == "true" then
		ExoLink_BISDB.showPercent = true
	elseif msg == "off" or msg == "0" or msg == "false" then
		ExoLink_BISDB.showPercent = false
	else
		ExoLink_BISDB.showPercent = not ExoLink_BISDB.showPercent
	end
	updateConfigUI()
	printStatus()
end

SLASH_BISSTATUS1 = "/bisstatus"
function SlashCmdList.BISSTATUS()
	printStatus()
end

function ExoLink:RegisterBIS(class, spec, comment)
	if not spec then spec = "" end
	if not comment then comment = "" end
	
    local bis = {
		class = class,
		spec = spec,
		comment = comment
	}
	
	bis.ID = class..spec..comment

    ExoLink.BIS[bis.ID] = bis
    return bis
end

function ExoLink:BISitem(bisEntry, id, slot, description, phase)
	if not ExoLink.Items[id] then
		ExoLink.Items[id] = {}
	end

	ExoLink.Items[id][bisEntry.ID] = phase
end
