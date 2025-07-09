-- Default-Konfiguration
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
  "Ehre wem Ehre gebührt - stark gemacht, %s!",
  "Boom! %s schlägt wieder zu!",
  "GG %s - epischer Erfolg!",
  "%s, du hast den Titel 'Legende' verdient!",
  "Alle mal klatschen für %s! 👏",
  "%s hat's geschafft! Und wir feiern mit!",
}

-- Lokale Variablen (werden später aus DB geladen)
local messages = defaultMessages
local globalCooldown = 10
local playerCooldown = 120
local lastGlobalMessage = 0
local playerCooldowns = {}
local AutoGZ_Enabled = true
local AutoGZ_Initialized = false -- 🛡️ Schutz gegen doppelte Initialisierung

-- Hauptfunktion
local function congratulatePlayer(playerName)
  if not AutoGZ_Enabled then return end
  local now = GetTime()
  if playerName == UnitName("player") then return end

  if now - lastGlobalMessage < globalCooldown then return end
  local lastPlayerMessage = playerCooldowns[playerName] or 0
  if now - lastPlayerMessage < playerCooldown then return end

  local msg = string.format(messages[random(#messages)], playerName)
  SendChatMessage(msg, "GUILD")

  lastGlobalMessage = now
  playerCooldowns[playerName] = now
end

-- Event-Handling
local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("ACHIEVEMENT_EARNED")

frame:SetScript("OnEvent", function(self, event, arg1, arg2)
  if event == "ADDON_LOADED" and not AutoGZ_Initialized then
    AutoGZ_Initialized = true

    AutoGZDB = AutoGZDB or {}
    AutoGZDB.enabled = AutoGZDB.enabled ~= false
    AutoGZDB.messages = AutoGZDB.messages or defaultMessages
    AutoGZDB.globalCooldown = AutoGZDB.globalCooldown or 10
    AutoGZDB.playerCooldown = AutoGZDB.playerCooldown or 120

    messages = AutoGZDB.messages
    AutoGZ_Enabled = AutoGZDB.enabled
    globalCooldown = AutoGZDB.globalCooldown
    playerCooldown = AutoGZDB.playerCooldown

    -- EINHEITLICHER SLASH-BEFEHL
    SLASH_GZ1 = "/gz"
    SlashCmdList["GZ"] = function(msg)
      local args = {}
      for word in string.gmatch(msg, "%S+") do
        table.insert(args, word)
      end

      local command = string.lower(args[1] or "")

      if command == "test" then
        local name = args[2] or "Testspieler"
        congratulatePlayer(name)

      elseif command == "toggle" then
        AutoGZ_Enabled = not AutoGZ_Enabled
        AutoGZDB.enabled = AutoGZ_Enabled
        local status = AutoGZ_Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"
        print("AutoGZ ist jetzt " .. status .. ".")

      elseif command == "cooldown" then
        local sub = string.lower(args[2] or "")
        local value = tonumber(args[3])

        if sub == "global" and value then
          globalCooldown = value
          AutoGZDB.globalCooldown = value
          print("Globaler Cooldown auf " .. value .. " Sekunden gesetzt.")

        elseif sub == "player" and value then
          playerCooldown = value
          AutoGZDB.playerCooldown = value
          print("Spieler-Cooldown auf " .. value .. " Sekunden gesetzt.")

        else
          print("Aktuelle Cooldowns:")
          print("- Global: " .. globalCooldown .. " Sekunden")
          print("- Spieler: " .. playerCooldown .. " Sekunden")
          print("Verwendung: /gz cooldown [global|player] [Sekunden]")
        end

      else
        print("|cff00ff00AutoGZ – Befehlsübersicht:|r")
        print("/gz test [Name] – Testet die Ausgabe mit optionalem Namen.")
        print("/gz toggle – Aktiviert/Deaktiviert die automatische Ausgabe.")
        print("/gz cooldown – Zeigt aktuelle Cooldowns.")
        print("/gz cooldown global [Sek] – Setzt globalen Cooldown.")
        print("/gz cooldown player [Sek] – Setzt Spieler-Cooldown.")
        print("/gz help – Zeigt diese Hilfe an (oder einfach nur /gz).")
      end
    end

    print("AutoGZ geladen – Status: " .. (AutoGZ_Enabled and "|cff00ff00aktiviert|r" or "|cffff0000deaktiviert|r"))
  end

  if event == "ACHIEVEMENT_EARNED" then
    if not AutoGZ_Enabled then return end
    local info = arg2 and C_PlayerInfo.GetPlayerInfoByGUID(arg2)
    if not info then return end
    congratulatePlayer(info.name)
  end
end)
