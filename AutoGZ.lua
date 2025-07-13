-- AutoGZ v3 – Kombinierte Erkennung über Chat-Filter und Guild-News

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
  "Alle mal klatschen für %s! 👏",
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

-- Guild-News-Feed-Prüfung
local function CheckGuildAchievements()
  local total = C_GuildInfo.GetNumGuildNews()
  for i = lastNewsIndex + 1, total do
    local news = C_GuildInfo.GetGuildNewsInfo(i)
    if news.newsType == Enum.GuildNewsType.Achievement then
      local who = news.playerName:match("([^%%-]+)")
      if InGuild(who) then
        Congratulate(who)
      end
    end
  end
  lastNewsIndex = total
end

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

  else
    -- Hilfe
    print("|cff00ff00AutoGZ Befehle:|r")
    print("/gz test [Name]      – Testausgabe per Whisper")
    print("/gz toggle          – An/Aus")
    print("/gz cooldown [..]   – Cooldowns setzen")
    print("/gz add <Text>      – Neuen Spruch hinzufügen")
    print("/gz remove <Index>  – Spruch löschen")
    print("/gz list            – Alle Sprüche auflisten")
    return
  end
end

-- Frame & Events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("GUILD_NEWS_UPDATE")

frame:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" and not Initialized then
    Initialized       = true
    AutoGZDB          = AutoGZDB or {}
    Enabled           = AutoGZDB.enabled        ~= false
    messages          = AutoGZDB.messages       or defaultMessages
    globalCooldown    = AutoGZDB.globalCooldown or 10
    playerCooldown    = AutoGZDB.playerCooldown or 120

    -- Guild-News anfordern und Index setzen
    C_GuildInfo.RequestGuildNews()
    lastNewsIndex = C_GuildInfo.GetNumGuildNews()

    print("AutoGZ geladen – Status: " .. (Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
  elseif event == "GUILD_NEWS_UPDATE" then
    CheckGuildAchievements()
  end
end)
