# 🎉 AutoGZ – Automatische Erfolgsglückwünsche für World of Warcraft

AutoGZ ist ein leichtgewichtiges Addon für World of Warcraft, das deinen Mitspieler:innen automatisch zu Erfolgen gratuliert – mit zufälligen, charmanten Sprüchen. Ideal für ein aktives Gildenleben ohne ständiges Tippen von "gz".

---

## ✨ Features

- Erkennt automatisch Erfolge anderer Spieler
- Sendet zufällige Glückwunsch-Nachrichten im Gildenchat
- Ignoriert eigene Erfolge (kein Self-GZ)
- Globaler Cooldown & individueller Spieler-Cooldown
- Slash-Befehle zum Testen, Deaktivieren & Konfigurieren
- Einstellungen werden dauerhaft gespeichert
- Unterstützt Icon-Anzeige in der Addon-Liste

---

## 🧩 Installation

1. Repository herunterladen oder klonen:
   ```
   git clone https://github.com/JensRinne/AutoGZ.git
   ```

2. Den Ordner `AutoGZ` in das Verzeichnis kopieren:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```

3. Spiel neu starten oder `/reload` im Chat eingeben.

---

## ⚙️ Slash-Befehle

| Befehl                      | Funktion                                                   |
|-----------------------------|------------------------------------------------------------|
| `/gz` oder `/gz help`       | Zeigt Hilfe/Übersicht an                                   |
| `/gz test [Name]`           | Sendet Testnachricht per Whisper an [Name]                 |
| `/gz toggle`                | Aktiviert oder deaktiviert automatische Ausgabe            |
| `/gz cooldown`              | Zeigt aktuelle Cooldown-Werte                              |
| `/gz cooldown global [X]`   | Setzt globalen Cooldown auf X Sekunden                     |
| `/gz cooldown player [X]`   | Setzt Spieler-Cooldown auf X Sekunden                      |

---

## 🖼️ Icon

Falls du ein `.tga`-Icon verwenden willst:
- Speichere die Datei im Addon-Ordner als `icon.tga`
- Füge in der `.toc`-Datei hinzu:
  ```
  ## IconTexture: icon.tga
  ```

Alternativ kann eine Icon-ID aus WoW verwendet werden (z. B. `## IconTexture: 236697`).

---

## 📜 Lizenz

MIT License – frei verwendbar, änderbar, teilbar.

---

## 🙌 Mitwirken

Spruchideen, Verbesserungsvorschläge oder Pull Requests? Her damit!  
Gemeinsam machen wir Azeroth ein kleines bisschen netter.
