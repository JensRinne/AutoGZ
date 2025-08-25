-- AutoGZ v2 – Kombinierte Erkennung über Chat-Filter und Guild-News

-- Direkter Zugriff auf die Optionen
SLASH_AUTOGZOPTIONS1 = "/gzoptions"
SLASH_AUTOGZOPTIONS2 = "/autogoptions"
SlashCmdList["AUTOGZOPTIONS"] = function(msg)
  -- Optionen-Frame erstellen, falls nicht vorhanden
  if not AutoGZOptionsFrame then
    CreateInterfaceOptions()
  end
  
  -- Ein-/Ausblenden des Frames
  if AutoGZOptionsFrame:IsShown() then
    AutoGZOptionsFrame:Hide()
  else
    AutoGZOptionsFrame:Show()
    if UpdateMessagesList then
      UpdateMessagesList()
    end
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
}

-- Lokale Variablen
local messages       = defaultMessages
local globalCooldown = 10
local playerCooldown = 120
local lastGlobalTime = 0
local playerLastTime = {}
local Enabled        = true
local Initialized    = false
local lastNewsIndex  = 0

-- Funktion: GZ senden
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

-- Prüfen, ob Name in Gilde
local function InGuild(name)
  if not IsInGuild() then return false end
  for i = 1, GetNumGuildMembers() do
    local n = GetGuildRosterInfo(i)
    if n and n:match("([^%%-]+)") == name then return true end
  end
  return false
end

-- Chat-Filter zum Abfangen von Achievement-Messages
local function AchievementFilter(self, event, msg, author, ...)
  local name
  if event == "CHAT_MSG_SYSTEM" then
    name = msg:match("^%[?([^%]%s]+)%]? hat den Erfolg")
  else
    name = author
  end
  if name then
    name = name:match("([^%%-]+)")
    if name ~= UnitName("player") and InGuild(name) then
      Congratulate(name)
    end
  end
  return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", AchievementFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD_ACHIEVEMENT", AchievementFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_ACHIEVEMENT", AchievementFilter)


-- Slash-Befehl /gz
SLASH_GZ1 = "/gz"
SlashCmdList["GZ"] = function(msg)
  local args = {}
  for w in msg:gmatch("%S+") do
    table.insert(args, w)
  end
  local cmd = (args[1] or ""):lower()

  if cmd == "test" then
    -- Testmodus: flüstern an dich selbst, ohne Cooldown oder Gilden-Chat
    local name = args[2] or UnitName("player")
    local text = string.format(messages[random(#messages)], name)
    SendChatMessage(text, "WHISPER", nil, UnitName("player"))
    return
  end

  if cmd == "toggle" then
    Enabled = not Enabled
    AutoGZDB.enabled = Enabled
    print("AutoGZ ist jetzt " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
    return

  elseif cmd == "cooldown" then
    local sub = args[2] and args[2]:lower()
    local val = tonumber(args[3])
    if sub == "global" and val then
      globalCooldown = val
      AutoGZDB.globalCooldown = val
      print("Globaler Cooldown auf " .. val .. " Sek. gesetzt.")
    elseif sub == "player" and val then
      playerCooldown = val
      AutoGZDB.playerCooldown = val
      print("Spieler-Cooldown auf " .. val .. " Sek. gesetzt.")
    else
      print("/gz cooldown [global|player] [Sekunden]")
    end
    return

  elseif cmd == "add" then
    -- /gz add <Text>
    local text = table.concat(args, " ", 2)
    if text ~= "" then
      table.insert(messages, text)
      AutoGZDB.messages = messages
      print("Neuer Spruch (#" .. #messages .. "): " .. text)
    else
      print("Verwendung: /gz add <Text>")
    end
    return

  elseif cmd == "remove" then
    -- /gz remove <Index>
    local idx = tonumber(args[2])
    if idx and messages[idx] then
      local old = messages[idx]
      table.remove(messages, idx)
      AutoGZDB.messages = messages
      print("Spruch #" .. idx .. " entfernt: " .. old)
    else
      print("Ungültiger Index. Nutze /gz list, um die Nummern zu sehen.")
    end
    return

  elseif cmd == "list" then
    -- /gz list
    print("|cff00ff00Aktuelle GZ‑Sprüche:|r")
    for i, v in ipairs(messages) do
      print(i .. ". " .. v)
    end
    return

  elseif cmd == "options" or cmd == "config" or msg == "options" or msg == "config" then
    -- Eigenständige Optionen öffnen
    if not AutoGZOptionsFrame then
      CreateInterfaceOptions()
    end
    
    if AutoGZOptionsFrame:IsShown() then
      AutoGZOptionsFrame:Hide()
    else
      AutoGZOptionsFrame:Show()
      UpdateMessagesList()
    end
    return

  else
    -- Hilfe
    print("|cff00ff00AutoGZ Befehle:|r")
    print("/gz test [Name]      – Testausgabe per Whisper")
    print("/gz toggle          – An/Aus")
    print("/gz cooldown [..]   – Cooldowns setzen")
    print("/gz add <Text>      – Neuen Spruch hinzufügen")
    print("/gz remove <Index>  – Spruch löschen")
    print("/gz list            – Alle Sprüche auflisten")
    print("/gz options         – Einstellungsmenü öffnen")
    return
  end
end

-- Eigenständige Benutzeroberfläche erstellen
local AutoGZOptionsFrame = nil

local function CreateOptionsFrame()
  -- Wenn das Frame bereits existiert, geben wir es zurück
  if AutoGZOptionsFrame then
    return AutoGZOptionsFrame
  end
  
  -- Hauptframe erstellen
  AutoGZOptionsFrame = CreateFrame("Frame", "AutoGZOptionsFrame", UIParent, "BackdropTemplate")
  AutoGZOptionsFrame:SetFrameStrata("DIALOG")
  AutoGZOptionsFrame:SetWidth(480)
  AutoGZOptionsFrame:SetHeight(500) -- Zurück zur ursprünglichen Höhe für kleinere Bildschirme
  AutoGZOptionsFrame:SetPoint("CENTER")
  AutoGZOptionsFrame:SetMovable(true)
  AutoGZOptionsFrame:EnableMouse(true)
  AutoGZOptionsFrame:RegisterForDrag("LeftButton")
  AutoGZOptionsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
  AutoGZOptionsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  AutoGZOptionsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  AutoGZOptionsFrame:SetBackdropColor(0, 0, 0, 1)
  AutoGZOptionsFrame:Hide()
  
  -- Titelleiste
  local titleBar = CreateFrame("Frame", nil, AutoGZOptionsFrame)
  titleBar:SetPoint("TOPLEFT", 12, -8)
  titleBar:SetPoint("TOPRIGHT", -12, -8)
  titleBar:SetHeight(24)
  
  local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", titleBar, "TOP", 0, -6)
  title:SetText("AutoGZ - Automatische Erfolgsglückwünsche")
  
  -- Schließen-Button
  local closeButton = CreateFrame("Button", nil, AutoGZOptionsFrame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", -5, -5)
  
  -- Scroll Container für den gesamten Inhalt
  local scrollContainer = CreateFrame("ScrollFrame", "AutoGZOptionsScrollFrame", AutoGZOptionsFrame, "UIPanelScrollFrameTemplate")
  scrollContainer:SetPoint("TOPLEFT", 26, -32) -- Mehr Platz am linken Rand (von 16 auf 26)
  scrollContainer:SetPoint("BOTTOMRIGHT", -36, 16) -- Platz für Scrollbar
  
  -- Inhalt
  local contentFrame = CreateFrame("Frame", "AutoGZOptionsContent", scrollContainer)
  contentFrame:SetWidth(scrollContainer:GetWidth())
  scrollContainer:SetScrollChild(contentFrame)
  
  -- Breite für den Inhalt setzen (wichtig für ScrollFrame)
  contentFrame:SetWidth(410)
  contentFrame:SetHeight(600) -- Erhöhte Höhe für den Inhalt und genügend Platz für Buttons
  
  -- Aktivieren-Checkbox
  local enableCheckbox = CreateFrame("CheckButton", "AutoGZStandaloneEnableCheckbox", contentFrame, "ChatConfigCheckButtonTemplate")
  enableCheckbox:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -15) -- Mehr Abstand zum Rand und nach oben
  _G[enableCheckbox:GetName() .. "Text"]:SetText("AutoGZ aktivieren")
  enableCheckbox:SetChecked(Enabled)
  enableCheckbox:SetScript("OnClick", function(self)
    Enabled = self:GetChecked()
    AutoGZDB.enabled = Enabled
    print("AutoGZ ist jetzt " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
  end)
  
  -- Cooldown-Einstellungen Header
  local cooldownHeader = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  cooldownHeader:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -20) -- Mehr Abstand nach unten
  cooldownHeader:SetText("Cooldown-Einstellungen")
  
  -- Globaler Cooldown
  local globalCooldownLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  globalCooldownLabel:SetPoint("TOPLEFT", cooldownHeader, "BOTTOMLEFT", 10, -12) -- Eingerückt und mehr Abstand
  globalCooldownLabel:SetText("Globaler Cooldown (Sek.):")
  
  local globalCooldownSlider = CreateFrame("Slider", "AutoGZStandaloneGlobalCooldownSlider", contentFrame, "OptionsSliderTemplate")
  globalCooldownSlider:SetPoint("TOPLEFT", globalCooldownLabel, "BOTTOMLEFT", 0, -15) -- Mehr Abstand zwischen Text und Slider
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
  
  -- Spieler Cooldown
  local playerCooldownLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  playerCooldownLabel:SetPoint("TOPLEFT", globalCooldownSlider, "BOTTOMLEFT", 0, -25) -- Mehr Abstand nach unten
  playerCooldownLabel:SetText("Spieler-Cooldown (Sek.):")
  
  local playerCooldownSlider = CreateFrame("Slider", "AutoGZStandalonePlayerCooldownSlider", contentFrame, "OptionsSliderTemplate")
  playerCooldownSlider:SetPoint("TOPLEFT", playerCooldownLabel, "BOTTOMLEFT", 0, -15) -- Mehr Abstand zwischen Text und Slider
  playerCooldownSlider:SetWidth(200)
  playerCooldownSlider:SetMinMaxValues(10, 300)
  playerCooldownSlider:SetValueStep(10)
  playerCooldownSlider:SetValue(playerCooldown)
  playerCooldownSlider.tooltipText = "Zeit in Sekunden, bevor ein Spieler wieder einen Glückwunsch erhalten kann"
  _G[playerCooldownSlider:GetName() .. "Low"]:SetText("10")
  _G[playerCooldownSlider:GetName() .. "High"]:SetText("300")
  _G[playerCooldownSlider:GetName() .. "Text"]:SetText(playerCooldown)
  
  playerCooldownSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value / 10) * 10  -- Auf 10er-Schritte runden
    playerCooldown = value
    AutoGZDB.playerCooldown = value
    _G[self:GetName() .. "Text"]:SetText(value)
  end)
  
  -- Nachrichten-Verwaltung Header
  local messagesHeader = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  -- Wir setzen den Ankerpunkt direkt unter den Spieler-Cooldown-Slider, aber mit Offset zum Hauptabschnitt statt zum eingerückten Slider
  messagesHeader:SetPoint("TOPLEFT", playerCooldownSlider, "BOTTOMLEFT", -10, -25) -- Abstand nach unten und Einrückung zurücknehmen
  messagesHeader:SetText("Nachrichtenverwaltung")
  
  -- Neue Nachricht hinzufügen
  local newMessageLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  newMessageLabel:SetPoint("TOPLEFT", messagesHeader, "BOTTOMLEFT", 10, -12) -- Eingerückt und mehr Abstand
  newMessageLabel:SetText("Neue Nachricht:")
  
  local newMessageEditBox = CreateFrame("EditBox", "AutoGZStandaloneNewMessageEditBox", contentFrame, "InputBoxTemplate")
  newMessageEditBox:SetPoint("TOPLEFT", newMessageLabel, "BOTTOMLEFT", 0, -8) -- Keine zusätzliche Einrückung
  newMessageEditBox:SetWidth(260) -- Deutlich schmaler für den Button
  newMessageEditBox:SetHeight(20)
  newMessageEditBox:SetAutoFocus(false)
  
  local addMessageButton = CreateFrame("Button", "AutoGZStandaloneAddMessageButton", contentFrame, "UIPanelButtonTemplate")
  addMessageButton:SetPoint("LEFT", newMessageEditBox, "RIGHT", 10, 0)
  addMessageButton:SetWidth(100)
  addMessageButton:SetHeight(22)
  addMessageButton:SetText("Hinzufügen")
  addMessageButton:SetScript("OnClick", function()
    local text = newMessageEditBox:GetText()
    if text ~= "" then
      table.insert(messages, text)
      AutoGZDB.messages = messages
      print("Neuer Spruch (#" .. #messages .. "): " .. text)
      newMessageEditBox:SetText("")
      UpdateMessagesList()
    end
  end)
  
  -- Nachrichten-Liste
  local messagesListLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  messagesListLabel:SetPoint("TOPLEFT", newMessageLabel, "TOPLEFT", 0, -50) -- Gleiche horizontale Position wie "Neue Nachricht:"
  messagesListLabel:SetText("Vorhandene Nachrichten:")
  
  -- ScrollFrame für die Nachrichten erstellen
  local listFrame = CreateFrame("Frame", "AutoGZStandaloneMessagesListFrame", contentFrame)
  listFrame:SetPoint("TOPLEFT", messagesListLabel, "BOTTOMLEFT", 0, -8) -- Nicht eingerückt
  listFrame:SetWidth(400) -- Volle Breite
  listFrame:SetHeight(270) -- Optimierte Höhe für 13 Einträge
  
  -- ScrollFrame Hintergrund
  local listBg = listFrame:CreateTexture(nil, "BACKGROUND")
  listBg:SetAllPoints()
  listBg:SetColorTexture(0, 0, 0, 0.2)
  
  -- FauxScrollFrame erstellen
  local scrollFrame = CreateFrame("ScrollFrame", "AutoGZStandaloneMessagesScrollFrame", listFrame, "FauxScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 0, 0)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 0)
  
  -- Nachrichtenobjekte für die Liste
  local messageItems = {}
  for i = 1, 9 do -- Reduzierte Anzahl auf 9 sichtbare Einträge für größere Abstände
    local item = CreateFrame("Button", "AutoGZStandaloneMessageItem" .. i, scrollFrame)
    item:SetHeight(25) -- Standard-Höhe für den Button, wird dynamisch angepasst
    item:SetWidth(370)
    
    -- Wir setzen die Position erst in UpdateMessagesList, damit wir sie dynamisch anpassen können
    
    -- Text der Nachricht
    item.text = item:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    item.text:SetPoint("TOPLEFT", 5, -1) -- Minimaler Abstand nach oben
    item.text:SetWidth(340)
    item.text:SetJustifyH("LEFT")
    item.text:SetSpacing(1) -- Kompakterer Zeilenabstand innerhalb des Textes
    
    -- Lösch-Button
    item.delete = CreateFrame("Button", "AutoGZStandaloneDeleteButton" .. i, item)
    item.delete:SetPoint("RIGHT", 0, 0)
    item.delete:SetWidth(20)
    item.delete:SetHeight(20)
    item.delete:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
    item.delete:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    item.delete:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    item.delete.id = 0
    
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
    
    messageItems[i] = item
  end
  
  -- Buttons-Frame erstellen (separater Container für die Buttons)
  local buttonsFrame = CreateFrame("Frame", "AutoGZButtonsFrame", contentFrame)
  -- Positionierung direkt unter der Nachrichtenliste
  buttonsFrame:SetPoint("TOPLEFT", listFrame, "BOTTOMLEFT", 0, -20) -- 20px Abstand unter der Liste
  buttonsFrame:SetWidth(400)
  buttonsFrame:SetHeight(40)
  
  -- Testbutton in den separaten Container
  local testButton = CreateFrame("Button", "AutoGZStandaloneTestButton", buttonsFrame, "UIPanelButtonTemplate")
  testButton:SetPoint("CENTER", buttonsFrame, "CENTER", -75, 0) -- Links von der Mitte im Container
  testButton:SetWidth(110)
  testButton:SetHeight(26) -- Größer für bessere Sichtbarkeit
  testButton:SetText("Test")
  testButton:SetScript("OnClick", function()
    local name = UnitName("player")
    local text = string.format(messages[random(#messages)], name)
    SendChatMessage(text, "WHISPER", nil, UnitName("player"))
  end)
  
  -- Reset-Button für Standardsprüche im separaten Container
  local resetButton = CreateFrame("Button", "AutoGZStandaloneResetButton", buttonsFrame, "UIPanelButtonTemplate")
  resetButton:SetPoint("CENTER", buttonsFrame, "CENTER", 75, 0) -- Rechts von der Mitte im Container
  resetButton:SetWidth(150)
  resetButton:SetHeight(26) -- Größer für bessere Sichtbarkeit
  resetButton:SetText("Standardsprüche")
  resetButton:SetScript("OnClick", function()
    StaticPopupDialogs["AUTOGZ_RESET_CONFIRM"] = {
      text = "Möchtest du wirklich alle Sprüche auf die Standardwerte zurücksetzen?",
      button1 = "Ja",
      button2 = "Nein",
      OnAccept = function()
        messages = CopyTable(defaultMessages)
        AutoGZDB.messages = messages
        print("AutoGZ: Sprüche wurden auf Standardwerte zurückgesetzt.")
        UpdateMessagesList()
        -- Zum Anfang des ScrollFrames scrollen
        if _G["AutoGZResetScroll"] then
          _G["AutoGZResetScroll"]()
        end
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show("AUTOGZ_RESET_CONFIRM")
  end)
  
  -- Update-Funktion für die Liste als globale Variable definieren
  _G["UpdateMessagesList"] = function()
    local numMessages = #messages
    FauxScrollFrame_Update(scrollFrame, numMessages, 9, 20) -- Auf 9 sichtbare Einträge reduziert
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    
    -- Einheitlicher Abstand zwischen den Elementen in der Liste
    local ITEM_SPACING = 15  -- Reduzierter Abstand zwischen den Nachrichten für mehr Platz
    
    for i = 1, 9 do -- 9 sichtbare Einträge für optimale Darstellung mit erhöhtem Abstand
      local index = i + offset
      local item = messageItems[i]
      
      if index <= numMessages then
        -- Nachricht formatieren und darstellen
        local message = messages[index]
        -- Formatieren mit Einrückung für mehrzeilige Nachrichten
        local formattedMsg = index .. ". " .. message:gsub("\n", "\n     ")
        item.text:SetText(formattedMsg)
        
        -- Die Höhe dynamisch anpassen, basierend auf der Zeilenzahl
        local lineCount = 1
        for _ in message:gmatch("\n") do
          lineCount = lineCount + 1
        end
        
        -- Dynamische Höhe basierend auf Zeilenzahl setzen, optimal für 13 Einträge
        local textHeight = 11 * lineCount + 6  -- Optimierte Grundhöhe + Zeilenhöhe
        item:SetHeight(textHeight)
        
        -- Position des ersten Elements festlegen
        if i == 1 then
          item:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 5, 0)
        else
          -- Vorherige Position löschen und neue setzen
          item:ClearAllPoints()
          item:SetPoint("TOPLEFT", messageItems[i-1], "BOTTOMLEFT", 0, -ITEM_SPACING)
        end
        
        item.delete.id = index
        item:Show()
      else
        item:Hide()
      end
    end
  end
  
  scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, 20, UpdateMessagesList) -- Reduzierte Zeilenhöhe für Scrolling
  end)
  
  -- Positioniere die Buttons unter der Liste mit optimalem Abstand
  local function UpdateButtonsPosition()
    -- Sicherstellen, dass die Buttons immer unter der Liste sind
    buttonsFrame:ClearAllPoints()
    buttonsFrame:SetPoint("TOPLEFT", listFrame, "BOTTOMLEFT", 0, -20) -- 20px Abstand unter der Liste
    buttonsFrame:Show()
  end
  
  AutoGZOptionsFrame:SetScript("OnShow", function()
    UpdateMessagesList()
  end)
  
  -- Nach dem Zurücksetzen der Nachrichten zum Anfang des ScrollFrames scrollen
  local function ResetScroll()
    scrollContainer:SetVerticalScroll(0)
  end
  
  -- ScrollToTop-Funktion global verfügbar machen
  _G["AutoGZResetScroll"] = ResetScroll
  
  -- Anpassung der Höhe des Inhalt-Frames mit berücksichtigter Button-Position
  local function UpdateContentHeight()
    -- Berechne nötige Höhe basierend auf der Button-Position
    local requiredHeight = math.abs(buttonsFrame:GetBottom() - contentFrame:GetTop()) + 30
    
    -- Setze Höhe, aber mit optimiertem Mindestwert für genau 13 Einträge
    contentFrame:SetHeight(math.max(requiredHeight, 430))
    
    -- Stelle sicher, dass die Buttons sichtbar sind
    buttonsFrame:Show()
  end
  
  -- Nach Änderungen der Nachrichtenliste auch die Größe aktualisieren
  local originalUpdateMessagesList = _G["UpdateMessagesList"]
  _G["UpdateMessagesList"] = function()
    originalUpdateMessagesList()
    -- Buttons neu positionieren und dann Höhe anpassen
    UpdateButtonsPosition()
    C_Timer.After(0.05, UpdateContentHeight)
  end
  
  -- Erstmaligen Funktionsaufruf verzögern, damit alle Elemente richtig positioniert sind
  C_Timer.After(0.1, UpdateContentHeight)
  
  return AutoGZOptionsFrame
end

-- Interface-Optionen erstellen
local function CreateInterfaceOptions()
  
  -- Titel
  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("AutoGZ - Automatische Erfolgsglückwünsche")
  
  -- Aktivieren-Checkbox
  local enableCheckbox = CreateFrame("CheckButton", "AutoGZEnableCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
  enableCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
  _G[enableCheckbox:GetName() .. "Text"]:SetText("AutoGZ aktivieren")
  enableCheckbox:SetChecked(Enabled)
  enableCheckbox:SetScript("OnClick", function(self)
    Enabled = self:GetChecked()
    AutoGZDB.enabled = Enabled
    print("AutoGZ ist jetzt " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
  end)
  
  -- Cooldown-Einstellungen Header
  local cooldownHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  cooldownHeader:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -16)
  cooldownHeader:SetText("Cooldown-Einstellungen")
  
  -- Globaler Cooldown
  local globalCooldownLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  globalCooldownLabel:SetPoint("TOPLEFT", cooldownHeader, "BOTTOMLEFT", 0, -8)
  globalCooldownLabel:SetText("Globaler Cooldown (Sek.):")
  
  local globalCooldownSlider = CreateFrame("Slider", "AutoGZGlobalCooldownSlider", panel, "OptionsSliderTemplate")
  globalCooldownSlider:SetPoint("TOPLEFT", globalCooldownLabel, "BOTTOMLEFT", 0, -8)
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
  
  -- Spieler Cooldown
  local playerCooldownLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  playerCooldownLabel:SetPoint("TOPLEFT", globalCooldownSlider, "BOTTOMLEFT", 0, -16)
  playerCooldownLabel:SetText("Spieler-Cooldown (Sek.):")
  
  local playerCooldownSlider = CreateFrame("Slider", "AutoGZPlayerCooldownSlider", panel, "OptionsSliderTemplate")
  playerCooldownSlider:SetPoint("TOPLEFT", playerCooldownLabel, "BOTTOMLEFT", 0, -8)
  playerCooldownSlider:SetWidth(200)
  playerCooldownSlider:SetMinMaxValues(10, 300)
  playerCooldownSlider:SetValueStep(10)
  playerCooldownSlider:SetValue(playerCooldown)
  playerCooldownSlider.tooltipText = "Zeit in Sekunden, bevor ein Spieler wieder einen Glückwunsch erhalten kann"
  _G[playerCooldownSlider:GetName() .. "Low"]:SetText("10")
  _G[playerCooldownSlider:GetName() .. "High"]:SetText("300")
  _G[playerCooldownSlider:GetName() .. "Text"]:SetText(playerCooldown)
  
  playerCooldownSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value / 10) * 10  -- Auf 10er-Schritte runden
    playerCooldown = value
    AutoGZDB.playerCooldown = value
    _G[self:GetName() .. "Text"]:SetText(value)
  end)
  
  -- Nachrichten-Verwaltung Header
  local messagesHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  messagesHeader:SetPoint("TOPLEFT", playerCooldownSlider, "BOTTOMLEFT", 0, -16)
  messagesHeader:SetText("Nachrichtenverwaltung")
  
  -- Neue Nachricht hinzufügen
  local newMessageLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  newMessageLabel:SetPoint("TOPLEFT", messagesHeader, "BOTTOMLEFT", 0, -8)
  newMessageLabel:SetText("Neue Nachricht:")
  
  local newMessageEditBox = CreateFrame("EditBox", "AutoGZNewMessageEditBox", panel, "InputBoxTemplate")
  newMessageEditBox:SetPoint("TOPLEFT", newMessageLabel, "BOTTOMLEFT", 0, -8)
  newMessageEditBox:SetWidth(300)
  newMessageEditBox:SetHeight(20)
  newMessageEditBox:SetAutoFocus(false)
  
  local addMessageButton = CreateFrame("Button", "AutoGZAddMessageButton", panel, "UIPanelButtonTemplate")
  addMessageButton:SetPoint("LEFT", newMessageEditBox, "RIGHT", 10, 0)
  addMessageButton:SetWidth(100)
  addMessageButton:SetHeight(22)
  addMessageButton:SetText("Hinzufügen")
  addMessageButton:SetScript("OnClick", function()
    local text = newMessageEditBox:GetText()
    if text ~= "" then
      table.insert(messages, text)
      AutoGZDB.messages = messages
      print("Neuer Spruch (#" .. #messages .. "): " .. text)
      newMessageEditBox:SetText("")
      UpdateMessagesList()
    end
  end)
  
  -- Nachrichten-Liste
  local messagesListLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  messagesListLabel:SetPoint("TOPLEFT", newMessageEditBox, "BOTTOMLEFT", 0, -16)
  messagesListLabel:SetText("Vorhandene Nachrichten:")
  
  -- ScrollFrame für die Nachrichten erstellen
  local listFrame = CreateFrame("Frame", "AutoGZMessagesListFrame", panel)
  listFrame:SetPoint("TOPLEFT", messagesListLabel, "BOTTOMLEFT", 0, -8)
  listFrame:SetWidth(400)
  listFrame:SetHeight(200)
  
  -- ScrollFrame Hintergrund
  local listBg = listFrame:CreateTexture(nil, "BACKGROUND")
  listBg:SetAllPoints()
  listBg:SetColorTexture(0, 0, 0, 0.2)
  
  -- FauxScrollFrame erstellen
  local scrollFrame = CreateFrame("ScrollFrame", "AutoGZMessagesScrollFrame", listFrame, "FauxScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 0, 0)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 0)
  
  -- Nachrichtenobjekte für die Liste
  local messageItems = {}
  for i = 1, 8 do -- 8 sichtbare Einträge
    local item = CreateFrame("Button", "AutoGZMessageItem" .. i, scrollFrame)
    item:SetHeight(25)
    item:SetWidth(370)
    
    if i == 1 then
      item:SetPoint("TOPLEFT", 5, 0)
    else
      item:SetPoint("TOPLEFT", messageItems[i-1], "BOTTOMLEFT", 0, 0)
    end
    
    -- Text der Nachricht
    item.text = item:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    item.text:SetPoint("LEFT", 5, 0)
    item.text:SetWidth(340)
    item.text:SetJustifyH("LEFT")
    
    -- Lösch-Button
    item.delete = CreateFrame("Button", "AutoGZDeleteButton" .. i, item)
    item.delete:SetPoint("RIGHT", 0, 0)
    item.delete:SetWidth(20)
    item.delete:SetHeight(20)
    item.delete:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
    item.delete:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    item.delete:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    item.delete.id = 0
    
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
    
    messageItems[i] = item
  end
  
  -- Update-Funktion für die Liste (global definieren)
  _G["UpdateMessagesList"] = function()
    local numMessages = #messages
    FauxScrollFrame_Update(scrollFrame, numMessages, 8, 25)
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    
    for i = 1, 8 do
      local index = i + offset
      local item = messageItems[i]
      
      if index <= numMessages then
        item.text:SetText(index .. ". " .. messages[index])
        item.delete.id = index
        item:Show()
      else
        item:Hide()
      end
    end
  end
  
  scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, 25, UpdateMessagesList)
  end)
  
  panel:SetScript("OnShow", function()
    UpdateMessagesList()
  end)
  
  -- Testbutton
  local testButton = CreateFrame("Button", "AutoGZTestButton", panel, "UIPanelButtonTemplate")
  testButton:SetPoint("TOPLEFT", listFrame, "BOTTOMLEFT", 0, -16)
  testButton:SetWidth(100)
  testButton:SetHeight(22)
  testButton:SetText("Test")
  testButton:SetScript("OnClick", function()
    local name = UnitName("player")
    local text = string.format(messages[random(#messages)], name)
    SendChatMessage(text, "WHISPER", nil, UnitName("player"))
  end)
  
  -- Wir haben die Optionen bereits in CreateOptionsFrame() implementiert, daher müssen wir hier nichts mehr tun.
  enableCheckbox:SetPoint("TOPLEFT", 10, -10)
  getglobal(enableCheckbox:GetName() .. "Text"):SetText("AutoGZ aktivieren")
  enableCheckbox:SetChecked(Enabled)
  enableCheckbox:SetScript("OnClick", function(self)
    Enabled = self:GetChecked()
    AutoGZDB.enabled = Enabled
    print("AutoGZ ist jetzt " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
  end)
  
  -- Cooldown-Einstellungen Header
  local cooldownHeader = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  cooldownHeader:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -16)
  cooldownHeader:SetText("Cooldown-Einstellungen")
  
  -- Globaler Cooldown
  local globalCooldownLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  globalCooldownLabel:SetPoint("TOPLEFT", cooldownHeader, "BOTTOMLEFT", 0, -8)
  globalCooldownLabel:SetText("Globaler Cooldown (Sek.):")
  
  local globalCooldownSlider = CreateFrame("Slider", "AutoGZGlobalCooldownSlider", contentFrame, "OptionsSliderTemplate")
  globalCooldownSlider:SetPoint("TOPLEFT", globalCooldownLabel, "BOTTOMLEFT", 0, -8)
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
  
  -- Spieler Cooldown
  local playerCooldownLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  playerCooldownLabel:SetPoint("TOPLEFT", globalCooldownSlider, "BOTTOMLEFT", 0, -16)
  playerCooldownLabel:SetText("Spieler-Cooldown (Sek.):")
  
  local playerCooldownSlider = CreateFrame("Slider", "AutoGZPlayerCooldownSlider", contentFrame, "OptionsSliderTemplate")
  playerCooldownSlider:SetPoint("TOPLEFT", playerCooldownLabel, "BOTTOMLEFT", 0, -8)
  playerCooldownSlider:SetWidth(200)
  playerCooldownSlider:SetMinMaxValues(10, 300)
  playerCooldownSlider:SetValueStep(10)
  playerCooldownSlider:SetValue(playerCooldown)
  playerCooldownSlider.tooltipText = "Zeit in Sekunden, bevor ein Spieler wieder einen Glückwunsch erhalten kann"
  _G[playerCooldownSlider:GetName() .. "Low"]:SetText("10")
  _G[playerCooldownSlider:GetName() .. "High"]:SetText("300")
  _G[playerCooldownSlider:GetName() .. "Text"]:SetText(playerCooldown)
  
  playerCooldownSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value / 10) * 10  -- Auf 10er-Schritte runden
    playerCooldown = value
    AutoGZDB.playerCooldown = value
    _G[self:GetName() .. "Text"]:SetText(value)
  end)
  
  -- Nachrichten-Verwaltung Header
  local messagesHeader = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  messagesHeader:SetPoint("TOPLEFT", playerCooldownSlider, "BOTTOMLEFT", 0, -16)
  messagesHeader:SetText("Nachrichtenverwaltung")
  
  -- Neue Nachricht hinzufügen
  local newMessageLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  newMessageLabel:SetPoint("TOPLEFT", messagesHeader, "BOTTOMLEFT", 0, -8)
  newMessageLabel:SetText("Neue Nachricht:")
  
  local newMessageEditBox = CreateFrame("EditBox", "AutoGZNewMessageEditBox", contentFrame, "InputBoxTemplate")
  newMessageEditBox:SetPoint("TOPLEFT", newMessageLabel, "BOTTOMLEFT", 0, -8)
  newMessageEditBox:SetWidth(300)
  newMessageEditBox:SetHeight(20)
  newMessageEditBox:SetAutoFocus(false)
  
  local addMessageButton = CreateFrame("Button", "AutoGZAddMessageButton", contentFrame, "UIPanelButtonTemplate")
  addMessageButton:SetPoint("LEFT", newMessageEditBox, "RIGHT", 10, 0)
  addMessageButton:SetWidth(100)
  addMessageButton:SetHeight(22)
  addMessageButton:SetText("Hinzufügen")
  addMessageButton:SetScript("OnClick", function()
    local text = newMessageEditBox:GetText()
    if text ~= "" then
      table.insert(messages, text)
      AutoGZDB.messages = messages
      print("Neuer Spruch (#" .. #messages .. "): " .. text)
      newMessageEditBox:SetText("")
      UpdateMessagesList()
    end
  end)
  
  -- Nachrichten-Liste
  local messagesListLabel = contentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  messagesListLabel:SetPoint("TOPLEFT", newMessageEditBox, "BOTTOMLEFT", 0, -16)
  messagesListLabel:SetText("Vorhandene Nachrichten:")
  
  -- ScrollFrame für die Nachrichten erstellen
  local listFrame = CreateFrame("Frame", "AutoGZMessagesListFrame", contentFrame)
  listFrame:SetPoint("TOPLEFT", messagesListLabel, "BOTTOMLEFT", 0, -8)
  listFrame:SetWidth(400)
  listFrame:SetHeight(200)
  
  -- ScrollFrame Hintergrund
  local listBg = listFrame:CreateTexture(nil, "BACKGROUND")
  listBg:SetAllPoints()
  listBg:SetColorTexture(0, 0, 0, 0.2)
  
  -- FauxScrollFrame erstellen
  local scrollFrame = CreateFrame("ScrollFrame", "AutoGZMessagesScrollFrame", listFrame, "FauxScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 0, 0)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 0)
  
  -- Nachrichtenobjekte für die Liste
  local messageItems = {}
  for i = 1, 8 do -- 8 sichtbare Einträge
    local item = CreateFrame("Button", "AutoGZMessageItem" .. i, scrollFrame)
    item:SetHeight(25)
    item:SetWidth(370)
    
    if i == 1 then
      item:SetPoint("TOPLEFT", 5, 0)
    else
      item:SetPoint("TOPLEFT", messageItems[i-1], "BOTTOMLEFT", 0, 0)
    end
    
    -- Text der Nachricht
    item.text = item:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    item.text:SetPoint("LEFT", 5, 0)
    item.text:SetWidth(340)
    item.text:SetJustifyH("LEFT")
    
    -- Lösch-Button
    item.delete = CreateFrame("Button", "AutoGZDeleteButton" .. i, item)
    item.delete:SetPoint("RIGHT", 0, 0)
    item.delete:SetWidth(20)
    item.delete:SetHeight(20)
    item.delete:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
    item.delete:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    item.delete:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    item.delete.id = 0
    
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
    
    messageItems[i] = item
  end
  
  -- Update-Funktion für die Liste (global definieren)
  _G["UpdateMessagesList"] = function()
    local numMessages = #messages
    FauxScrollFrame_Update(scrollFrame, numMessages, 8, 25)
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    
    for i = 1, 8 do
      local index = i + offset
      local item = messageItems[i]
      
      if index <= numMessages then
        item.text:SetText(index .. ". " .. messages[index])
        item.delete.id = index
        item:Show()
      else
        item:Hide()
      end
    end
  end
  
  scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, 25, UpdateMessagesList)
  end)
  
  -- Initial aktualisieren
  optionsFrame:SetScript("OnShow", function()
    if UpdateMessagesList then
      UpdateMessagesList()
    end
  end)
  
  -- Testbutton
  local testButton = CreateFrame("Button", "AutoGZTestButton", contentFrame, "UIPanelButtonTemplate")
  testButton:SetPoint("TOPLEFT", listFrame, "BOTTOMLEFT", 0, -16)
  testButton:SetWidth(100)
  testButton:SetHeight(22)
  testButton:SetText("Test")
  testButton:SetScript("OnClick", function()
    local name = UnitName("player")
    local text = string.format(messages[random(#messages)], name)
    SendChatMessage(text, "WHISPER", nil, UnitName("player"))
  end)
  
  -- Titel
  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("AutoGZ - Automatische Erfolgsglückwünsche")
  
  -- Aktivieren-Checkbox
  local enableCheckbox = CreateFrame("CheckButton", "AutoGZEnableCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
  enableCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
  enableCheckbox.Text:SetText("AutoGZ aktivieren")
  enableCheckbox:SetChecked(Enabled)
  enableCheckbox:SetScript("OnClick", function(self)
    Enabled = self:GetChecked()
    AutoGZDB.enabled = Enabled
    print("AutoGZ ist jetzt " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
  end)
  
  -- Cooldown-Einstellungen Header
  local cooldownHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  cooldownHeader:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -16)
  cooldownHeader:SetText("Cooldown-Einstellungen")
  
  -- Globaler Cooldown
  local globalCooldownLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  globalCooldownLabel:SetPoint("TOPLEFT", cooldownHeader, "BOTTOMLEFT", 0, -8)
  globalCooldownLabel:SetText("Globaler Cooldown (Sek.):")
  
  local globalCooldownSlider = CreateFrame("Slider", "AutoGZGlobalCooldownSlider", panel, "OptionsSliderTemplate")
  globalCooldownSlider:SetPoint("TOPLEFT", globalCooldownLabel, "BOTTOMLEFT", 0, -8)
  globalCooldownSlider:SetWidth(200)
  globalCooldownSlider:SetMinMaxValues(0, 60)
  globalCooldownSlider:SetValueStep(1)
  globalCooldownSlider:SetValue(globalCooldown)
  globalCooldownSlider.tooltipText = "Zeit in Sekunden zwischen zwei Glückwünschen im Gildenchat"
  getglobal(globalCooldownSlider:GetName() .. "Low"):SetText("0")
  getglobal(globalCooldownSlider:GetName() .. "High"):SetText("60")
  getglobal(globalCooldownSlider:GetName() .. "Text"):SetText(globalCooldown)
  
  globalCooldownSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    globalCooldown = value
    AutoGZDB.globalCooldown = value
    getglobal(self:GetName() .. "Text"):SetText(value)
  end)
  
  -- Spieler Cooldown
  local playerCooldownLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  playerCooldownLabel:SetPoint("TOPLEFT", globalCooldownSlider, "BOTTOMLEFT", 0, -16)
  playerCooldownLabel:SetText("Spieler-Cooldown (Sek.):")
  
  local playerCooldownSlider = CreateFrame("Slider", "AutoGZPlayerCooldownSlider", panel, "OptionsSliderTemplate")
  playerCooldownSlider:SetPoint("TOPLEFT", playerCooldownLabel, "BOTTOMLEFT", 0, -8)
  playerCooldownSlider:SetWidth(200)
  playerCooldownSlider:SetMinMaxValues(10, 300)
  playerCooldownSlider:SetValueStep(10)
  playerCooldownSlider:SetValue(playerCooldown)
  playerCooldownSlider.tooltipText = "Zeit in Sekunden, bevor ein Spieler wieder einen Glückwunsch erhalten kann"
  getglobal(playerCooldownSlider:GetName() .. "Low"):SetText("10")
  getglobal(playerCooldownSlider:GetName() .. "High"):SetText("300")
  getglobal(playerCooldownSlider:GetName() .. "Text"):SetText(playerCooldown)
  
  playerCooldownSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value / 10) * 10  -- Auf 10er-Schritte runden
    playerCooldown = value
    AutoGZDB.playerCooldown = value
    getglobal(self:GetName() .. "Text"):SetText(value)
  end)
  
  -- Nachrichten-Verwaltung Header
  local messagesHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  messagesHeader:SetPoint("TOPLEFT", playerCooldownSlider, "BOTTOMLEFT", 0, -16)
  messagesHeader:SetText("Nachrichtenverwaltung")
  
  -- Neue Nachricht hinzufügen
  local newMessageLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  newMessageLabel:SetPoint("TOPLEFT", messagesHeader, "BOTTOMLEFT", 0, -8)
  newMessageLabel:SetText("Neue Nachricht:")
  
  local newMessageEditBox = CreateFrame("EditBox", "AutoGZNewMessageEditBox", panel, "InputBoxTemplate")
  newMessageEditBox:SetPoint("TOPLEFT", newMessageLabel, "BOTTOMLEFT", 0, -8)
  newMessageEditBox:SetWidth(300)
  newMessageEditBox:SetHeight(20)
  newMessageEditBox:SetAutoFocus(false)
  
  local addMessageButton = CreateFrame("Button", "AutoGZAddMessageButton", panel, "UIPanelButtonTemplate")
  addMessageButton:SetPoint("LEFT", newMessageEditBox, "RIGHT", 10, 0)
  addMessageButton:SetWidth(100)
  addMessageButton:SetHeight(22)
  addMessageButton:SetText("Hinzufügen")
  addMessageButton:SetScript("OnClick", function()
    local text = newMessageEditBox:GetText()
    if text ~= "" then
      table.insert(messages, text)
      AutoGZDB.messages = messages
      print("Neuer Spruch (#" .. #messages .. "): " .. text)
      newMessageEditBox:SetText("")
      panel.messagesList:Update()
    end
  end)
  
  -- Nachrichten-Liste
  local messagesListLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  messagesListLabel:SetPoint("TOPLEFT", newMessageEditBox, "BOTTOMLEFT", 0, -16)
  messagesListLabel:SetText("Vorhandene Nachrichten:")
  
  -- ScrollFrame für die Nachrichten erstellen
  local listFrame = CreateFrame("Frame", "AutoGZMessagesListFrame", panel)
  listFrame:SetPoint("TOPLEFT", messagesListLabel, "BOTTOMLEFT", 0, -8)
  listFrame:SetWidth(400)
  listFrame:SetHeight(200)
  
  -- ScrollFrame Hintergrund
  local listBg = listFrame:CreateTexture(nil, "BACKGROUND")
  listBg:SetAllPoints()
  listBg:SetColorTexture(0, 0, 0, 0.2)
  
  -- FauxScrollFrame erstellen
  local scrollFrame = CreateFrame("ScrollFrame", "AutoGZMessagesScrollFrame", listFrame, "FauxScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 0, 0)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 0)
  
  -- Nachrichtenobjekte für die Liste
  local messageItems = {}
  for i = 1, 8 do -- 8 sichtbare Einträge
    local item = CreateFrame("Button", "AutoGZMessageItem" .. i, scrollFrame)
    item:SetHeight(25)
    item:SetWidth(370)
    
    if i == 1 then
      item:SetPoint("TOPLEFT", 5, 0)
    else
      item:SetPoint("TOPLEFT", messageItems[i-1], "BOTTOMLEFT", 0, 0)
    end
    
    -- Text der Nachricht
    item.text = item:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    item.text:SetPoint("LEFT", 5, 0)
    item.text:SetWidth(340)
    item.text:SetJustifyH("LEFT")
    
    -- Lösch-Button
    item.delete = CreateFrame("Button", "AutoGZDeleteButton" .. i, item)
    item.delete:SetPoint("RIGHT", 0, 0)
    item.delete:SetWidth(20)
    item.delete:SetHeight(20)
    item.delete:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
    item.delete:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    item.delete:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    item.delete.id = 0
    
    item.delete:SetScript("OnClick", function(self)
      local id = self.id
      if id and messages[id] then
        local old = messages[id]
        table.remove(messages, id)
        AutoGZDB.messages = messages
        print("Spruch #" .. id .. " entfernt: " .. old)
        panel.messagesList:Update()
      end
    end)
    
    messageItems[i] = item
  end
  
  -- Update-Funktion für die Liste
  panel.messagesList = {}
  panel.messagesList.Update = function()
    local numMessages = #messages
    FauxScrollFrame_Update(scrollFrame, numMessages, 8, 25)
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    
    for i = 1, 8 do
      local index = i + offset
      local item = messageItems[i]
      
      if index <= numMessages then
        item.text:SetText(index .. ". " .. messages[index])
        item.delete.id = index
        item:Show()
      else
        item:Hide()
      end
    end
  end
  
  scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, 25, panel.messagesList.Update)
  end)
  
  panel:SetScript("OnShow", function()
    panel.messagesList:Update()
  end)
  
  -- Testbutton
  local testButton = CreateFrame("Button", "AutoGZTestButton", panel, "UIPanelButtonTemplate")
  testButton:SetPoint("TOPLEFT", listFrame, "BOTTOMLEFT", 0, -16)
  testButton:SetWidth(100)
  testButton:SetHeight(22)
  testButton:SetText("Test")
  testButton:SetScript("OnClick", function()
    local name = UnitName("player")
    local text = string.format(messages[random(#messages)], name)
    SendChatMessage(text, "WHISPER", nil, UnitName("player"))
  end)
  
  return AutoGZOptionsFrame
end

-- Frame & Events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("GUILD_NEWS_UPDATE")

-- Minimap-Button für die Optionen
local MinimapButton = CreateFrame("Button", "AutoGZMinimapButton", Minimap)
MinimapButton:SetSize(31, 31) -- Wie TomeOfTeleportation
MinimapButton:SetFrameStrata("MEDIUM")
MinimapButton:SetMovable(true)
MinimapButton:EnableMouse(true)
MinimapButton:RegisterForDrag("LeftButton")
MinimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

-- Position auf der Minimap (Standardposition: 45 Grad)
MinimapButton.position = 45
-- Initiale Position wird durch UpdateMinimapButtonPosition() gesetzt

-- Textur und Aussehen
MinimapButton.icon = MinimapButton:CreateTexture(nil, "BACKGROUND")
MinimapButton.icon:SetSize(18, 18) -- Wie TomeOfTeleportation
MinimapButton.icon:SetPoint("CENTER", MinimapButton, "CENTER", 0, 0) -- Exakt zentriert
MinimapButton.icon:SetTexture(236669)
MinimapButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Standardrunde TexCoords

-- Rahmen und Highlight
MinimapButton.border = MinimapButton:CreateTexture(nil, "OVERLAY")
MinimapButton.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
MinimapButton.border:SetSize(50, 50) -- Wie TomeOfTeleportation
MinimapButton.border:SetPoint("TOPLEFT", MinimapButton, "TOPLEFT")

-- Button zum Leben erwecken
MinimapButton:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:AddLine("AutoGZ Optionen")
  GameTooltip:AddLine("Linksklick: Optionen öffnen", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Rechtsklick: AutoGZ " .. (Enabled and "deaktivieren" or "aktivieren"), 0.8, 0.8, 0.8)
  GameTooltip:Show()
end)

MinimapButton:SetScript("OnLeave", function(self)
  GameTooltip:Hide()
end)

-- Funktionalität bei Klick
MinimapButton:SetScript("OnClick", function(self, button)
  if button == "LeftButton" then
    -- Optionsmenü anzeigen
    local frame = CreateOptionsFrame()
    
    if frame:IsShown() then
      frame:Hide()
    else
      frame:Show()
      if UpdateMessagesList then
        UpdateMessagesList()
      end
    end
  elseif button == "RightButton" then
    -- AutoGZ ein-/ausschalten (ohne Slash-Befehl)
    Enabled = not Enabled
    AutoGZDB.enabled = Enabled
    print("AutoGZ ist jetzt " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
  end
end)

-- Bewegung an der Minimap
local function UpdateMinimapButtonPosition()
  -- Großer Radius wie bei LibDBIcon, damit der Button außen an der Minimap sitzt
  local radius = 110
  local angle = math.rad(MinimapButton.position or 45)
  local x = math.cos(angle) * radius
  local y = math.sin(angle) * radius
  
  -- Alte Anker entfernen und neue setzen
  MinimapButton:ClearAllPoints()
  MinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Anstatt den Button frei beweglich zu machen, folgen wir dem Mauszeiger auf einem Kreispfad um die Minimap
MinimapButton:SetScript("OnDragStart", function(self)
  self:RegisterForDrag("LeftButton")
  self.isMoving = true
end)

MinimapButton:SetScript("OnDragStop", function(self)
  self.isMoving = false
  
  -- Position speichern
  if AutoGZDB then
    AutoGZDB.minimapPos = MinimapButton.position
  end
end)

-- OnUpdate, um den Button dem Mauszeiger am Rand der Minimap folgen zu lassen
MinimapButton:SetScript("OnUpdate", function(self)
  if self.isMoving then
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    
    px, py = px / scale, py / scale
    
    -- Berechne den Winkel zwischen Minimap-Zentrum und Mauszeiger
    local dx, dy = px - mx, py - my
    local angle = math.deg(math.atan2(dy, dx))
    
    -- Aktualisiere die Position
    MinimapButton.position = angle
    UpdateMinimapButtonPosition()
  end
end)

-- Position aus den Einstellungen laden
local function InitializeMinimapButton()
  if AutoGZDB and AutoGZDB.minimapPos then
    MinimapButton.position = AutoGZDB.minimapPos
  end
  UpdateMinimapButtonPosition()
  MinimapButton:Show()
end

frame:SetScript("OnEvent", function(self, event, addon, ...)
  if event == "ADDON_LOADED" then
    if addon == "AutoGZ" and not Initialized then
      Initialized       = true
      AutoGZDB          = AutoGZDB or {}
      Enabled           = AutoGZDB.enabled        ~= false
      messages          = AutoGZDB.messages       or defaultMessages
      globalCooldown    = AutoGZDB.globalCooldown or 10
      playerCooldown    = AutoGZDB.playerCooldown or 120

  -- Guild-News-API entfernt, daher keine Initialisierung nötig
      
      -- Minimap-Button initialisieren
      InitializeMinimapButton()
      
      -- Laden-Nachricht ausgeben
      print("AutoGZ geladen – Status: " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r") .. " (Klicke auf den Minimap-Button für Optionen)")
    end
  -- GUILD_NEWS_UPDATE wird nicht mehr benötigt
  end
end)
