-- Chronicle Armory Link
-- OctoWoW / Vanilla-style client
-- Version 0.1.1

ChronicleArmory = {}

-- Change this if your OctoWoW realm uses a different Chronicle realm name.
ChronicleArmory.REALM = "N'Zoth"
ChronicleArmory.BASE_URL = "https://octo.chronicleclassic.com/armory/"
ChronicleArmory.BUTTON = "CHRONICLE_ARMORY"

local function BuildURL(name)
  if not name or name == "" then return nil end
  return ChronicleArmory.BASE_URL .. ChronicleArmory.REALM .. "/" .. name
end

-- ============================================================
-- Copyable popup, modeled after pfUI's URL copy window.
-- ============================================================

local popup = CreateFrame("Frame", "ChronicleArmoryCopy", UIParent)
popup:Hide()
popup:SetWidth(330)
popup:SetHeight(78)
popup:SetFrameStrata("FULLSCREEN")
popup:SetPoint("CENTER", 0, 0)

if CreateBackdrop then
  CreateBackdrop(popup, nil, nil, 0.8)
else
  popup:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  popup:SetBackdropColor(0, 0, 0, 0.8)
end

popup:SetMovable(true)
popup:EnableMouse(true)
popup:RegisterForDrag("LeftButton")
popup:SetScript("OnDragStart", function()
  this:StartMoving()
end)
popup:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
end)

popup:SetScript("OnShow", function()
  this.text:SetFocus()
  this.text:HighlightText()
end)

popup.text = CreateFrame("EditBox", "ChronicleArmoryCopyEditBox", popup)
popup.text:SetWidth(305)
popup.text:SetHeight(20)
popup.text:SetPoint("TOP", popup, "TOP", 0, -10)
popup.text:SetFontObject(GameFontNormal)
popup.text:SetJustifyH("CENTER")
popup.text:SetAutoFocus(false)
popup.text:SetTextColor(0.2, 1, 0.8, 1)

if CreateBackdrop then
  CreateBackdrop(popup.text)
end

popup.text:SetScript("OnEscapePressed", function()
  popup:Hide()
end)
popup.text:SetScript("OnEnterPressed", function()
  popup:Hide()
end)
popup.text:SetScript("OnEditFocusLost", function()
  -- Do not hide here. Clicking the Close button would otherwise be awkward,
  -- and the user may click elsewhere before copying.
end)

popup.close = CreateFrame("Button", "ChronicleArmoryCopyClose", popup, "UIPanelButtonTemplate")
popup.close:SetWidth(70)
popup.close:SetHeight(18)
popup.close:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 8)
popup.close:SetText("Close")
popup.close:SetScript("OnClick", function()
  popup:Hide()
end)

function ChronicleArmory.ShowURL(url)
  if not url then return end
  popup.text:SetText(url)
  popup:Show()
end

-- ============================================================
-- Right-click player/unit menus
-- ============================================================

UnitPopupButtons[ChronicleArmory.BUTTON] = {
  text = "Inspect Armory",
  dist = 0,
}

-- Add the option to the menus commonly used by chat names,
-- target frames, party frames, and raid frames.
-- PFUI can use several different UnitPopup menu types depending on
-- which portrait was clicked.  In particular, its custom raid frames use
-- the PARTY menu, while the player/target frames use their normal dropdowns.
local menus = {
  "SELF",
  "PLAYER",
  "PARTY",
  "RAID",
  "TARGET",
  "FRIEND",
}

local function AddArmoryMenuEntries()
  for _, menu in ipairs(menus) do
    if UnitPopupMenus[menu] then
      local alreadyThere = false
      for _, value in ipairs(UnitPopupMenus[menu]) do
        if value == ChronicleArmory.BUTTON then
          alreadyThere = true
          break
        end
      end
      if not alreadyThere then
        table.insert(UnitPopupMenus[menu], ChronicleArmory.BUTTON)
      end
    end
  end
end

-- Run once now and again after login.  This covers clients where one or
-- more UnitPopupMenus tables are created after addons begin loading.
AddArmoryMenuEntries()
local menuInit = CreateFrame("Frame")
menuInit:RegisterEvent("PLAYER_LOGIN")
menuInit:SetScript("OnEvent", AddArmoryMenuEntries)

-- When our menu entry is clicked, UnitPopup gives us the player's name.
hooksecurefunc("UnitPopup_OnClick", function()
  local button = this.value
  if button ~= ChronicleArmory.BUTTON then return end

  local dropdownFrame = _G[UIDROPDOWNMENU_INIT_MENU]
  if not dropdownFrame then return end

  local name = dropdownFrame.name

  -- PFUI's custom party/raid portrait menus provide a unit token even when
  -- the dropdown does not expose .name.  Prefer the actual unit name.
  if dropdownFrame.unit and UnitExists(dropdownFrame.unit) then
    local unitName = UnitName(dropdownFrame.unit)
    if unitName and unitName ~= "" then
      name = unitName
    end
  end

  -- Some menus provide only .name, so retain that as a fallback.

  if name then
    ChronicleArmory.ShowURL(BuildURL(name))
  end
end)

-- ============================================================
-- Optional PFUI integration:
-- If PFUI is installed, its existing URL-copy window can be used.
-- We still keep our own popup so this addon works without PFUI.
-- ============================================================

function ChronicleArmory.ShowURLWithPFUI(url)
  if pfUI and pfUI.chat and pfUI.chat.urlcopy and pfUI.chat.urlcopy.CopyText then
    pfUI.chat.urlcopy.CopyText(url)
  else
    ChronicleArmory.ShowURL(url)
  end
end

-- Simple slash command for testing without opening a unit menu:
SLASH_CHRONICLEARMORY1 = "/carmory"
SlashCmdList["CHRONICLEARMORY"] = function(msg)
  local name = msg
  if not name or name == "" then
    name = UnitName("target")
  end

  if name and name ~= "" then
    ChronicleArmory.ShowURLWithPFUI(BuildURL(name))
  else
    DEFAULT_CHAT_FRAME:AddMessage("Chronicle Armory: target a player or use /carmory PlayerName")
  end
end
