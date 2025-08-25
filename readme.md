
# 🎉 AutoGZ – Automatische Erfolgsglückwünsche für World of Warcraft

AutoGZ ist ein leichtgewichtiges Addon für World of Warcraft, das deinen Mitspieler:innen automatisch zu Erfolgen gratuliert – mit zufälligen, charmanten Sprüchen. Ideal für ein aktives Gildenleben ohne ständiges Tippen von „gz“.
Ab Version 2 bietet AutoGZ eine komfortable grafische Oberfläche (GUI) für alle Einstellungen und die Verwaltung der Glückwunsch-Sprüche direkt im Spiel.

---


## ✨ Features

- Erkennt automatisch Erfolge anderer Spieler (Retail über Guild-News-Feed & Chat-Filter)
- Sendet zufällige Glückwunsch-Nachrichten im Gildenchat
- Ignoriert eigene Erfolge
- Globaler und individueller Spieler-Cooldown
- **Komfortable grafische Oberfläche (GUI) für Einstellungen und Sprüche-Verwaltung**
- Sprüche können direkt im Spiel hinzugefügt, entfernt und gelistet werden
- Einstellungen und benutzerdefinierte Sprüche werden dauerhaft gespeichert
- Slash-Befehle weiterhin verfügbar (siehe unten)
- Unterstützt Icon-Anzeige in der Addon-Liste

---

## 🧩 Installation

1. Repository klonen:  
   ```bash
   git clone https://github.com/JensRinne/AutoGZ.git
   ```
2. Ordner `AutoGZ` nach  
   `World of Warcraft/_retail_/Interface/AddOns/` verschieben.  
3. Spiel neu starten oder `/reload` eingeben.  

---


## 🖥️ Bedienung & Einstellungen

### Grafische Oberfläche (empfohlen)

Öffne das Einstellungsmenü im Spiel mit `/gz options` oder `/gz config` **oder** über das Interface-Menü. Dort kannst du:

- AutoGZ aktivieren/deaktivieren
- Globalen und Spieler-Cooldown einstellen (Schieberegler)
- Sprüche komfortabel hinzufügen, entfernen und durchsehen
- Alle Sprüche auf Standard zurücksetzen
- Testnachricht an dich selbst schicken

### Slash-Befehle (optional)

| Befehl                      | Beschreibung                                                        |
|-----------------------------|---------------------------------------------------------------------|
| `/gz` oder `/gz help`       | Hilfe anzeigen                                                      |
| `/gz options`               | Öffnet die grafische Oberfläche                                     |
| `/gz test [Name]`           | Testnachricht per Whisper an dich selbst                            |
| `/gz toggle`                | AutoGZ aktivieren/deaktivieren                                      |
| `/gz cooldown`              | Aktuelle Cooldowns anzeigen                                         |
| `/gz cooldown global [X]`   | Globalen Cooldown auf X Sekunden setzen                             |
| `/gz cooldown player [X]`   | Spieler-Cooldown auf X Sekunden setzen                              |
| `/gz add <Text>`            | Neuen Spruch hinzufügen                                             |
| `/gz remove <Index>`        | Spruch mit Index löschen                                            |
| `/gz list`                  | Alle Sprüche mit Index auflisten                                    |

---


## 🛠️ Sprüche verwalten

Die Verwaltung der Sprüche ist jetzt besonders einfach über die grafische Oberfläche möglich (siehe oben). Dort kannst du Sprüche hinzufügen, löschen, durchsehen und auf Standard zurücksetzen.

Alternativ sind weiterhin folgende Befehle möglich:

- **Hinzufügen:** `/gz add Herzlichen Glückwunsch, %s – weiter so!`
- **Auflisten:** `/gz list`
- **Entfernen:** `/gz remove 3`

---

## 🖼️ Icon

1. Lege `icon.tga` in den Addon-Ordner.  
2. In der `.toc` einfügen:  
   ```
   ## IconTexture: icon.tga
   ```  
Oder mit Icon-ID:
```
## IconTexture: 236697
```

---

## 📜 Lizenz

MIT License – frei verwendbar, änderbar, teilbar.

---

## 🙌 Mitwirken

Spruchideen, Verbesserungsvorschläge oder Pull Requests willkommen!


### Lua-Fehler anzeigen (Debugging):
```
/console scriptErrors 1   # Fehleranzeige AN
/console scriptErrors 0   # Fehleranzeige AUS
```