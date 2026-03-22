# AutoGZ

AutoGZ ist ein WoW-Addon, das bei Erfolgen automatisch eine Glueckwunsch-Nachricht im Gildenchat sendet.

## Funktionsweise

- Das Addon lauscht auf Achievement-Events im Chat.
- Es erkennt den Spielername aus der Meldung.
- Es prueft, ob der Spieler in deiner Gilde ist.
- Es ignoriert deinen eigenen Charakter.
- Es waehlt einen zufaelligen Spruch aus der Nachrichtenliste.
- Es sendet den Spruch in den Kanal `GUILD`.

## Schutz vor Spam

AutoGZ nutzt zwei Cooldowns:

- Globaler Cooldown: Mindestabstand zwischen zwei Nachrichten insgesamt.
- Spieler-Cooldown: Mindestabstand fuer denselben Spieler.

## Speicherverhalten

Gespeichert wird in `AutoGZDB`:

- Aktiv/Inaktiv-Status
- Globaler Cooldown
- Spieler-Cooldown
- Eigene Nachrichtenliste
- Minimap-Button-Position

## Bedienung

### Slash-Befehle

- `/gz`
  - Zeigt Hilfe an.
- `/gz test [Name]`
  - Schickt eine Testnachricht als Whisper an dich selbst.
- `/gz toggle`
  - Aktiviert oder deaktiviert AutoGZ.
- `/gz cooldown global <Sekunden>`
  - Setzt den globalen Cooldown.
- `/gz cooldown player <Sekunden>`
  - Setzt den Spieler-Cooldown.
- `/gz add <Text>`
  - Fuegt einen neuen Spruch hinzu.
- `/gz remove <Index>`
  - Entfernt einen Spruch ueber seine Nummer.
- `/gz list`
  - Listet alle Sprueche auf.
- `/gz options` oder `/gz config`
  - Oeffnet das Optionsfenster.

### Optionen im Spiel

- Checkbox zum Aktivieren/Deaktivieren
- Slider fuer beide Cooldowns
- Eingabe zum Hinzufuegen neuer Sprueche
- Liste vorhandener Sprueche mit Loesch-Button
- Test-Button
- Reset auf Standardsprueche
- Minimap-Button zum schnellen Oeffnen

## Kompatibilitaet

Die Datei `AutoGZ.toc` verwendet aktuell:

- `## Interface: 120001`

Wenn Blizzard die Interface-Version in einem spaeteren Patch aendert, muss dieser Wert ggf. angepasst werden.

## Patch-Update-Checkliste

Wenn ein neuer WoW-Patch kommt, gehe diese Punkte kurz durch:

1. Buildnummer im Spiel auslesen:
  - `/dump (select(4, GetBuildInfo()))`
2. Die Zahl in `AutoGZ.toc` bei `## Interface:` eintragen.
3. Spiel mit `/reload` neu laden (oder neu starten).
4. Addon in der Addon-Liste pruefen.
5. Funktionstest machen:
  - `/gz test`

Falls AutoGZ als veraltet markiert ist, kannst du testweise in der Addon-Liste
"Veraltete AddOns laden" aktivieren. Wenn danach alles funktioniert, reicht in
der Regel die Aktualisierung der Interface-Nummer.

## Troubleshooting in 60 Sekunden

Wenn AutoGZ zwar geladen ist, aber nicht sendet:

1. Addon aktiv?
  - `/gz toggle` pruefen und ggf. aktivieren.
2. Testausgabe funktioniert?
  - `/gz test`
3. Script-Fehler aktivieren:
  - `/console scriptErrors 1`
  - `/reload`
4. Achievement-Erkennung pruefen:
  - In der Gilde ein Erfolg abwarten und schauen, ob ein Lua-Fehler erscheint.
5. Cooldowns als Ursache ausschliessen:
  - Testweise niedrige Werte setzen:
  - `/gz cooldown global 0`
  - `/gz cooldown player 10`

Wenn weiterhin nichts passiert, den ersten roten Fehlertext (genaue Meldung)
notieren. Damit laesst sich die Ursache meist direkt beheben.

## Hinweise

- Das Addon ist fuer Retail gedacht.
- Die Erkennung der Systemmeldung ist sprachabhaengig und aktuell auf deutsche Formulierungen ausgelegt (z. B. "hat den Erfolg").
