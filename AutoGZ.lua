--[[-----------------------------------------------------------------------------
AutoGZ – Automatische GZ-Sprüche (Gilde)
- Erkennung über Chat-Filter
- Optionsfenster mit dynamischer Nachrichtenliste (UIPanelScrollFrameTemplate)
- Keine Überlappung, exakt 1 „Leerzeile“ zwischen Einträgen (dynamisch gemessen)
-----------------------------------------------------------------------------]]--

-- Fallback: CopyTable, falls auf deiner Version nicht vorhanden
local function ShallowCopy(tbl)
  local t = {}
  for k, v in pairs(tbl or {}) do t[k] = v end
  return t
end
local CopyTable = CopyTable or ShallowCopy

-- Slash zum Öffnen der Optionen
SLASH_AUTOGZOPTIONS1 = "/gzoptions"
SLASH_AUTOGZOPTIONS2 = "/autogoptions"
SlashCmdList["AUTOGZOPTIONS"] = function()
  if not AutoGZOptionsFrame then
    CreateInterfaceOptions()
  end
  if AutoGZOptionsFrame:IsShown() then
    AutoGZOptionsFrame:Hide()
  else
    AutoGZOptionsFrame:Show()
    if UpdateMessagesList then UpdateMessagesList() end
  end
end

-- Standard-Konfiguration
local defaultMessages = {
  "GZ %s! Und jetzt ab zur Weltherrschaft!",
  "Na endlich %s! Schon gedacht, du schaffst das nie ;)",
  "Wusste ich doch, dass du's drauf hast - irgendwann!",
  "Das Achievement hat dich mehr verdient als du es!",
  "Du bist jetzt offiziell kein Noob mehr - zumindest bei diesem Erfolg ;)",
  "Ein weiteres Kapitel in der Saga deiner Größe!",
  "Glückwunsch %s, wieder ein Pixel mehr Ruhm!",
  "Die Götter von Azeroth applaudieren dir leise, %s.",
  "Du hast es geschafft %s! Jetzt noch die anderen 9999 Erfolge!",
  "Wow, du hast es tatsächlich geschafft! Jetzt kannst du dich 'Erfolgreich' nennen!",
  "GZ, du gottgleiche Legende!",
  "Komm, gib's zu - das war aus Versehen. GZ ;)",
  "GZ %s, du bist eine Maschine!",
  "Ehre wem Ehre gebührt – stark gemacht, %s!",
  "Boom! %s schlägt wieder zu!",
  "GG %s – epischer Erfolg!",
  "%s, du hast den Titel 'Legende' verdient!",
  "Alle mal klatschen für %s!",
  "%s hat's geschafft! Und wir feiern mit!",
  "Na toll – jetzt setzt du die Messlatte wieder so hoch, dass wir alle hinterherhecheln müssen. Herzlichen Glückwunsch, %s!",
  "Und du sagst immer, du hättest keinen Plan... dabei reißt du hier Erfolge ab, als wär’s ein Sonderangebot!",
  "Herzlichen Glückwunsch! Wieder ein Beweis, dass du eigentlich nur mit Superkräften undercover unterwegs bist, %s!",
}

-- SavedVariables / Laufzeitwerte
local messages       = defaultMessages
local globalCooldown = 10
local playerCooldown = 120
local lastGlobalTime = 0
local playerLastTime = {}
local Enabled        = true
local Initialized    = false

-- GZ senden
local function Congratulate(playerName)
  if not Enabled then return end
  local now = GetTime()
  if playerName == UnitName("player") then return end
  if now - lastGlobalTime < globalCooldown then return end
  if now - (playerLastTime[playerName] or 0) < playerCooldown then return end

  local text = string.format(messages[random(#messages)], playerName)
  SendChatMessage(text, "GUILD")

  lastGlobalTime = now
  playerLastTime[playerName] = now
end

-- Prüfen, ob Name in Gilde (namensteil vor -Realm)
local function InGuild(name)
  if not IsInGuild() then return false end
  for i = 1, GetNumGuildMembers() do
    local n = GetGuildRosterInfo(i)
    if n and n:match("([^-]+)") == name then return true end
  end
  return false
end

-- Chat-Filter: Achievements erkennen
local function AchievementFilter(self, event, msg, author, ...)
  local name
  if event == "CHAT_MSG_SYSTEM" then
    name = msg:match("^%[?([^%]%s]+)%]? hat den Erfolg")
  else
    name = author
  end
  if name then
    name = name:match("([^-]+)")
    if name ~= UnitName("player") and InGuild(name) then
      Congratulate(name)
    end
  end
  return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", AchievementFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD_ACHIEVEMENT", AchievementFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_ACHIEVEMENT", AchievementFilter)

-- /gz Befehle
SLASH_GZ1 = "/gz"
SlashCmdList["GZ"] = function(msg)
  local args = {}
  for w in msg:gmatch("%S+") do table.insert(args, w) end
  local cmd = (args[1] or ""):lower()

  if cmd == "test" then
    local name = args[2] or UnitName("player")
    local text = string.format(messages[random(#messages)], name)
    SendChatMessage(text, "WHISPER", nil, UnitName("player"))
    return
  elseif cmd == "toggle" then
    Enabled = not Enabled
    AutoGZDB.enabled = Enabled
    print("AutoGZ ist jetzt " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
    return
  elseif cmd == "cooldown" then
    local sub = args[2] and args[2]:lower()
    local val = tonumber(args[3])
    if sub == "global" and val then
      globalCooldown = val; AutoGZDB.globalCooldown = val
      print("Globaler Cooldown auf " .. val .. " Sek. gesetzt.")
    elseif sub == "player" and val then
      playerCooldown = val; AutoGZDB.playerCooldown = val
      print("Spieler-Cooldown auf " .. val .. " Sek. gesetzt.")
    else
      print("/gz cooldown [global|player] [Sekunden]")
    end
    return
  elseif cmd == "add" then
    local text = table.concat(args, " ", 2)
    if text ~= "" then
      table.insert(messages, text)
      AutoGZDB.messages = messages
      print("Neuer Spruch (#" .. #messages .. "): " .. text)
      if UpdateMessagesList then UpdateMessagesList() end
    else
      print("Verwendung: /gz add <Text>")
    end
    return
  elseif cmd == "remove" then
    local idx = tonumber(args[2])
    if idx and messages[idx] then
      local old = messages[idx]
      table.remove(messages, idx)
      AutoGZDB.messages = messages
      print("Spruch #" .. idx .. " entfernt: " .. old)
      if UpdateMessagesList then UpdateMessagesList() end
    else
      print("Ungültiger Index. Nutze /gz list, um die Nummern zu sehen.")
    end
    return
  elseif cmd == "list" then
    print("|cff00ff00Aktuelle GZ-Sprüche:|r")
    for i, v in ipairs(messages) do print(i .. ". " .. v) end
    return
  elseif cmd == "options" or cmd == "config" or msg == "options" or msg == "config" then
    if not AutoGZOptionsFrame then CreateInterfaceOptions() end
    if AutoGZOptionsFrame:IsShown() then
      AutoGZOptionsFrame:Hide()
    else
      AutoGZOptionsFrame:Show()
      if UpdateMessagesList then UpdateMessagesList() end
    end
    return
  else
    print("|cff00ff00AutoGZ Befehle:|r")
    print("/gz test [Name]      – Testausgabe per Whisper")
    print("/gz toggle          – An/Aus")
    print("/gz cooldown [..]   – Cooldowns setzen")
    print("/gz add <Text>      – Neuen Spruch hinzufügen")
    print("/gz remove <Index>  – Spruch löschen")
    print("/gz list            – Alle Sprüche auflisten")
    print("/gz options         – Einstellungsmenü öffnen")
  end
end

-- =========================================================
-- Optionsfenster (mit normalem ScrollFrame für die Nachrichten)
-- =========================================================
AutoGZOptionsFrame = nil

local function CreateOptionsFrame()
  if AutoGZOptionsFrame then return AutoGZOptionsFrame end

  -- Hauptframe
  AutoGZOptionsFrame = CreateFrame("Frame", "AutoGZOptionsFrame", UIParent, "BackdropTemplate")
  AutoGZOptionsFrame:SetFrameStrata("DIALOG")
  AutoGZOptionsFrame:SetSize(480, 500)
  AutoGZOptionsFrame:SetPoint("CENTER")
  AutoGZOptionsFrame:SetMovable(true)
  AutoGZOptionsFrame:EnableMouse(true)
  AutoGZOptionsFrame:RegisterForDrag("LeftButton")
  AutoGZOptionsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
  AutoGZOptionsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  AutoGZOptionsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  AutoGZOptionsFrame:SetBackdropColor(0,0,0,1)
  AutoGZOptionsFrame:Hide()

  -- Titel + Close
  local titleBar = CreateFrame("Frame", nil, AutoGZOptionsFrame)
  titleBar:SetPoint("TOPLEFT", 12, -8)
  titleBar:SetPoint("TOPRIGHT", -12, -8)
  titleBar:SetHeight(24)
  local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -6)
  title:SetText("AutoGZ - Automatische Erfolgsglückwünsche")
  local closeButton = CreateFrame("Button", nil, AutoGZOptionsFrame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", -5, -5)

  -- Scroll-Container für den gesamten Inhalt
  local scrollContainer = CreateFrame("ScrollFrame", "AutoGZOptionsScrollFrame", AutoGZOptionsFrame, "UIPanelScrollFrameTemplate")
  scrollContainer:SetPoint("TOPLEFT", 26, -32)
  scrollContainer:SetPoint("BOTTOMRIGHT", -36, 16)

  local contentFrame = CreateFrame("Frame", "AutoGZOptionsContent", scrollContainer)
  contentFrame:SetSize(410, 600)
  scrollContainer:SetScrollChild(contentFrame)

  -- Enable Checkbox
  local enableCheckbox = CreateFrame("CheckButton", "AutoGZStandaloneEnableCheckbox", contentFrame, "ChatConfigCheckButtonTemplate")
  enableCheckbox:SetPoint("TOPLEFT", 10, -15)
  _G[enableCheckbox:GetName() .. "Text"]:SetText("AutoGZ aktivieren")
  enableCheckbox:SetChecked(Enabled)
  enableCheckbox:SetScript("OnClick", function(self)
    Enabled = self:GetChecked()
    AutoGZDB.enabled = Enabled
    print("AutoGZ ist jetzt " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
  end)

  -- Cooldowns
  local cooldownHeader = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  cooldownHeader:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -20)
  cooldownHeader:SetText("Cooldown-Einstellungen")

  local globalCooldownLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  globalCooldownLabel:SetPoint("TOPLEFT", cooldownHeader, "BOTTOMLEFT", 10, -12)
  globalCooldownLabel:SetText("Globaler Cooldown (Sek.):")

  local globalCooldownSlider = CreateFrame("Slider", "AutoGZStandaloneGlobalCooldownSlider", contentFrame, "OptionsSliderTemplate")
  globalCooldownSlider:SetPoint("TOPLEFT", globalCooldownLabel, "BOTTOMLEFT", 0, -15)
  globalCooldownSlider:SetWidth(200)
  globalCooldownSlider:SetMinMaxValues(0, 60)
  globalCooldownSlider:SetValueStep(1)
  globalCooldownSlider:SetValue(globalCooldown)
  globalCooldownSlider.tooltipText = "Zeit in Sekunden zwischen zwei Glückwünschen im Gildenchat"
  _G[globalCooldownSlider:GetName() .. "Low"]:SetText("0")
  _G[globalCooldownSlider:GetName() .. "High"]:SetText("60")
  _G[globalCooldownSlider:GetName() .. "Text"]:SetText(globalCooldown)
  globalCooldownSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    globalCooldown = value
    AutoGZDB.globalCooldown = value
    _G[self:GetName() .. "Text"]:SetText(value)
  end)

  local playerCooldownLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  playerCooldownLabel:SetPoint("TOPLEFT", globalCooldownSlider, "BOTTOMLEFT", 0, -25)
  playerCooldownLabel:SetText("Spieler-Cooldown (Sek.):")

  local playerCooldownSlider = CreateFrame("Slider", "AutoGZStandalonePlayerCooldownSlider", contentFrame, "OptionsSliderTemplate")
  playerCooldownSlider:SetPoint("TOPLEFT", playerCooldownLabel, "BOTTOMLEFT", 0, -15)
  playerCooldownSlider:SetWidth(200)
  playerCooldownSlider:SetMinMaxValues(10, 300)
  playerCooldownSlider:SetValueStep(10)
  playerCooldownSlider:SetValue(playerCooldown)
  playerCooldownSlider.tooltipText = "Zeit in Sekunden, bevor ein Spieler wieder einen Glückwunsch erhalten kann"
  _G[playerCooldownSlider:GetName() .. "Low"]:SetText("10")
  _G[playerCooldownSlider:GetName() .. "High"]:SetText("300")
  _G[playerCooldownSlider:GetName() .. "Text"]:SetText(playerCooldown)
  playerCooldownSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value / 10) * 10
    playerCooldown = value
    AutoGZDB.playerCooldown = value
    _G[self:GetName() .. "Text"]:SetText(value)
  end)

  -- Nachrichtenverwaltung
  local messagesHeader = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  messagesHeader:SetPoint("TOPLEFT", playerCooldownSlider, "BOTTOMLEFT", -10, -25)
  messagesHeader:SetText("Nachrichtenverwaltung")

  local newMessageLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  newMessageLabel:SetPoint("TOPLEFT", messagesHeader, "BOTTOMLEFT", 10, -12)
  newMessageLabel:SetText("Neue Nachricht:")

  local newMessageEditBox = CreateFrame("EditBox", "AutoGZStandaloneNewMessageEditBox", contentFrame, "InputBoxTemplate")
  newMessageEditBox:SetPoint("TOPLEFT", newMessageLabel, "BOTTOMLEFT", 0, -8)
  newMessageEditBox:SetSize(260, 20)
  newMessageEditBox:SetAutoFocus(false)

  local addMessageButton = CreateFrame("Button", "AutoGZStandaloneAddMessageButton", contentFrame, "UIPanelButtonTemplate")
  addMessageButton:SetPoint("LEFT", newMessageEditBox, "RIGHT", 10, 0)
  addMessageButton:SetSize(100, 22)
  addMessageButton:SetText("Hinzufügen")
  addMessageButton:SetScript("OnClick", function()
    local text = newMessageEditBox:GetText()
    if text ~= "" then
      table.insert(messages, text)
      AutoGZDB.messages = messages
      print("Neuer Spruch (#" .. #messages .. "): " .. text)
      newMessageEditBox:SetText("")
      if UpdateMessagesList then UpdateMessagesList() end
    end
  end)

  local messagesListLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  messagesListLabel:SetPoint("TOPLEFT", newMessageLabel, "TOPLEFT", 0, -50)
  messagesListLabel:SetText("Vorhandene Nachrichten:")

  -- Rahmen für die Liste
  local listFrame = CreateFrame("Frame", "AutoGZStandaloneMessagesListFrame", contentFrame)
  listFrame:SetPoint("TOPLEFT", messagesListLabel, "BOTTOMLEFT", 0, -8)
  listFrame:SetSize(400, 270)
  listFrame:SetClipsChildren(true)

  local listBg = listFrame:CreateTexture(nil, "BACKGROUND")
  listBg:SetAllPoints()
  listBg:SetColorTexture(0, 0, 0, 0.2)

  -- Normales ScrollFrame mit ScrollChild
  local msgScroll = CreateFrame("ScrollFrame", "AutoGZMessagesScroll", listFrame, "UIPanelScrollFrameTemplate")
  msgScroll:SetPoint("TOPLEFT", 0, 0)
  msgScroll:SetPoint("BOTTOMRIGHT", -28, 0) -- Platz für Scrollbar

  -- Breiten-Konstanten: Item-Breite und reine Textbreite (Platz für Delete rechts)
  local ITEM_W, TEXT_W = 370, 340

  local msgContent = CreateFrame("Frame", "AutoGZMessagesContent", msgScroll)
  msgContent:SetSize(ITEM_W, 1)  -- Höhe dynamisch
  msgScroll:SetScrollChild(msgContent)

  -- Pool für Item-Frames
  local itemPool = {}
  local function AcquireItem(i)
    local item = itemPool[i]
    if not item then
      item = CreateFrame("Button", "AutoGZMessageItem" .. i, msgContent)
      item:SetWidth(ITEM_W) -- Höhe dynamisch

      item.text = item:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      item.text:SetPoint("TOPLEFT", 5, -2)
      item.text:SetWidth(TEXT_W)           -- <<< feste Textbreite für stabiles Wrapping
      item.text:SetJustifyH("LEFT")
      item.text:SetJustifyV("TOP")
      item.text:SetWordWrap(true)
      item.text:SetSpacing(2)              -- etwas mehr Zeilenabstand im Eintrag

      item.delete = CreateFrame("Button", "AutoGZDeleteButton" .. i, item)
      item.delete:SetPoint("RIGHT", 0, 0)
      item.delete:SetSize(20, 20)
      item.delete:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
      item.delete:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
      item.delete:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
      item.delete:SetScript("OnClick", function(self)
        local id = self.id
        if id and messages[id] then
          local old = messages[id]
          table.remove(messages, id)
          AutoGZDB.messages = messages
          print("Spruch #" .. id .. " entfernt: " .. old)
          UpdateMessagesList()
        end
      end)

      itemPool[i] = item
    end
    return item
  end

  -- ***** Hilfsfunktionen für verlässliche, dynamische Abstände *****

  -- Robuste Höhenmessung eines FontStrings (falls noch nicht gerendert)
  local function GetFSHeight(fs)
    local h = fs:GetStringHeight()
    if h == 0 then fs:Hide(); fs:Show(); h = fs:GetStringHeight() end
    return math.ceil(h)
  end

  -- Dynamische Zeilenhöhe messen (genau 1 Zeile, inkl. Spacing), basierend auf der Item-Font
  local probeFS
  local function MeasureLineHeight(refFS)
    if not probeFS then
      probeFS = msgContent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      probeFS:Hide()
      probeFS:SetJustifyH("LEFT"); probeFS:SetJustifyV("TOP")
      probeFS:SetWordWrap(true)
    end
    local font, size, flags = refFS:GetFont()
    probeFS:SetFont(font, size, flags)
    probeFS:SetSpacing(refFS:GetSpacing() or 0)
    probeFS:SetWidth(TEXT_W)
    probeFS:ClearAllPoints()
    probeFS:SetPoint("TOPLEFT", msgContent, "TOPLEFT", 5, -2)

    probeFS:SetText("X")
    local h1 = GetFSHeight(probeFS)
    probeFS:SetText("X\nX")
    local h2 = GetFSHeight(probeFS)

    return math.max(6, h2 - h1) -- echte Zeilenhöhe, min. 6px
  end

  -- Update-Funktion: baut die Liste vollständig mit dynamischen Abständen
  _G["UpdateMessagesListStandalone"] = function()
    local INNER_TOP    = 3    -- Innenabstand oben im Item
    local INNER_BOTTOM = 3    -- Innenabstand unten im Item
    local SAFETY       = 2    -- kleine Sicherheits-Pixel gegen Rundungsfehler

    -- Referenz-Item sicherstellen und exakte Zeilenhöhe messen
    local ref = AcquireItem(1)
    local LINE = MeasureLineHeight(ref.text)   -- genau 1 „Leerzeile“
    local ITEM_GAP = LINE

    local prev
    local totalH = 0

    for i = 1, #messages do
      local item = AcquireItem(i)
      local msg  = tostring(messages[i])

      -- Nummer + Einzug für umgebrochene Folgezeilen
      local formatted = i .. ". " .. msg:gsub("\n", "\n     ")
      item.text:SetWidth(TEXT_W)       -- sicherstellen, dass Breite stimmt
      item.text:SetText(formatted)

      -- verlässliche Texthöhe + Padding → Itemhöhe
      local textH = GetFSHeight(item.text)
      local h = math.max(22, textH + INNER_TOP + INNER_BOTTOM + SAFETY)
      item:SetHeight(h)

      -- Positionieren: unter das vorherige + genau 1 Zeilenhöhe Abstand
      item:ClearAllPoints()
      if not prev then
        item:SetPoint("TOPLEFT", msgContent, "TOPLEFT", 5, 0)
      else
        item:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -ITEM_GAP)
      end
      prev = item

      item.delete.id = i
      item:Show()

      totalH = totalH + h + (i > 1 and ITEM_GAP or 0)
    end

    -- ScrollChild-Höhe → Scrollbar stimmt exakt
    msgContent:SetHeight(math.max(totalH, 1))
  end

  -- Buttons unter der Liste
  local buttonsFrame = CreateFrame("Frame", "AutoGZButtonsFrame", contentFrame)
  buttonsFrame:SetPoint("TOPLEFT", listFrame, "BOTTOMLEFT", 0, -20)
  buttonsFrame:SetSize(400, 40)

  local testButton = CreateFrame("Button", "AutoGZStandaloneTestButton", buttonsFrame, "UIPanelButtonTemplate")
  testButton:SetPoint("CENTER", buttonsFrame, "CENTER", -75, 0)
  testButton:SetSize(110, 26)
  testButton:SetText("Test")
  testButton:SetScript("OnClick", function()
    local name = UnitName("player")
    local text = string.format(messages[random(#messages)], name)
    SendChatMessage(text, "WHISPER", nil, UnitName("player"))
  end)

  local resetButton = CreateFrame("Button", "AutoGZStandaloneResetButton", buttonsFrame, "UIPanelButtonTemplate")
  resetButton:SetPoint("CENTER", buttonsFrame, "CENTER", 75, 0)
  resetButton:SetSize(150, 26)
  resetButton:SetText("Standardsprüche")
  resetButton:SetScript("OnClick", function()
    StaticPopupDialogs["AUTOGZ_RESET_CONFIRM"] = {
      text = "Möchtest du wirklich alle Sprüche auf die Standardwerte zurücksetzen?",
      button1 = "Ja", button2 = "Nein",
      OnAccept = function()
        messages = CopyTable(defaultMessages)
        AutoGZDB.messages = messages
        print("AutoGZ: Sprüche wurden auf Standardwerte zurückgesetzt.")
        UpdateMessagesList()
        scrollContainer:SetVerticalScroll(0)
      end,
      timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopup_Show("AUTOGZ_RESET_CONFIRM")
  end)

  AutoGZOptionsFrame:SetScript("OnShow", function()
    UpdateMessagesList()
    -- Contenthöhe an Buttons anpassen (damit nichts abgeschnitten wird)
    C_Timer.After(0.05, function()
      local needed = math.abs(buttonsFrame:GetBottom() - contentFrame:GetTop()) + 30
      contentFrame:SetHeight(math.max(needed, 430))
    end)
  end)

  return AutoGZOptionsFrame
end

-- Alias für Slash/Minimap
function CreateInterfaceOptions()
  return CreateOptionsFrame()
end

-- Wrapper lässt bestehende Aufrufe weiter funktionieren
_G["UpdateMessagesList"] = function()
  if _G["UpdateMessagesListStandalone"] then _G["UpdateMessagesListStandalone"]() end
end

-- =================
-- Minimap-Button
-- =================
local MinimapButton = CreateFrame("Button", "AutoGZMinimapButton", Minimap)
MinimapButton:SetSize(31, 31)
MinimapButton:SetFrameStrata("MEDIUM")
MinimapButton:SetMovable(true)
MinimapButton:EnableMouse(true)
MinimapButton:RegisterForDrag("LeftButton")
MinimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

MinimapButton.position = 45 -- Grad
MinimapButton.icon = MinimapButton:CreateTexture(nil, "BACKGROUND")
MinimapButton.icon:SetSize(18, 18)
MinimapButton.icon:SetPoint("CENTER")
MinimapButton.icon:SetTexture(236669)
MinimapButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

MinimapButton.border = MinimapButton:CreateTexture(nil, "OVERLAY")
MinimapButton.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
MinimapButton.border:SetSize(50, 50)
MinimapButton.border:SetPoint("TOPLEFT")

MinimapButton:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine("AutoGZ Optionen")
  GameTooltip:AddLine("Linksklick: Optionen öffnen", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Rechtsklick: AutoGZ " .. (Enabled and "deaktivieren" or "aktivieren"), 0.8, 0.8, 0.8)
  GameTooltip:Show()
end)
MinimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

MinimapButton:SetScript("OnClick", function(self, button)
  if button == "LeftButton" then
    local frame = CreateOptionsFrame()
    if frame:IsShown() then
      frame:Hide()
    else
      frame:Show()
      UpdateMessagesList()
    end
  elseif button == "RightButton" then
    Enabled = not Enabled
    AutoGZDB.enabled = Enabled
    print("AutoGZ ist jetzt " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
  end
end)

local function UpdateMinimapButtonPosition()
  local radius = 110
  local angle = math.rad(MinimapButton.position or 45)
  local x = math.cos(angle) * radius
  local y = math.sin(angle) * radius
  MinimapButton:ClearAllPoints()
  MinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

MinimapButton:SetScript("OnDragStart", function(self)
  self:RegisterForDrag("LeftButton")
  self.isMoving = true
end)
MinimapButton:SetScript("OnDragStop", function(self)
  self.isMoving = false
  if AutoGZDB then AutoGZDB.minimapPos = MinimapButton.position end
end)
MinimapButton:SetScript("OnUpdate", function(self)
  if self.isMoving then
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    px, py = px / scale, py / scale
    local dx, dy = px - mx, py - my
    local angle = math.deg(math.atan2(dy, dx))
    MinimapButton.position = angle
    UpdateMinimapButtonPosition()
  end
end)

local function InitializeMinimapButton()
  if AutoGZDB and AutoGZDB.minimapPos then
    MinimapButton.position = AutoGZDB.minimapPos
  end
  UpdateMinimapButtonPosition()
  MinimapButton:Show()
end

-- =========
-- Events
-- =========
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
  if event == "ADDON_LOADED" then
    -- Passe "AutoGZ" ggf. an deinen tatsächlichen Addon-Namen in der TOC an
    if addon == "AutoGZ" and not Initialized then
      Initialized       = true
      AutoGZDB          = AutoGZDB or {}
      Enabled           = AutoGZDB.enabled        ~= false
      messages          = AutoGZDB.messages       or CopyTable(defaultMessages)
      globalCooldown    = AutoGZDB.globalCooldown or 10
      playerCooldown    = AutoGZDB.playerCooldown or 120

      InitializeMinimapButton()
      print("AutoGZ geladen – Status: " ..
        (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r") ..
        " (Klicke auf den Minimap-Button für Optionen)")
    end
  end
end)
