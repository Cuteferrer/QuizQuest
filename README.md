# QuizQuest

**2D-RPG-Lernspiel zur Prüfungsvorbereitung (AP Teil 2, Fachinformatiker Anwendungsentwicklung)**

> Projektsimulation an der Berufsschule zur Vorbereitung auf das IHK-Abschlussprojekt.
> Das Team tritt als fiktive Firma **Mr.Bit GmbH** auf, die Berufsschule als Auftraggeber.

## Worum geht's?

QuizQuest ist ein Top-down-RPG im Retro-Stil. Die Spielwelt ist ein Schulgebäude, Mitschüler sind Gegner, Lehrer die Bosse. Gekämpft wird mit Wissen: Jede richtige Antwort kostet den Gegner 1 HP, jede falsche den Spieler ein Herz.

- **4 Level**, je ein Themengebiet: Projektmanagement, Entwicklung, UML, WiSo
- **25 Fragen pro Level** (Single- und Multiple-Choice), verteilt auf 4 Mitschüler und 1 Lehrer à 5 Fragen
- **3 Herzen pro Level**, Bosskampf mit 100-Sekunden-Timer
- Lösung und Erklärung erst nach der richtigen Antwort
- Automatischer Checkpoint nach jedem geschafften Level
- Tutorial im ersten Raum von Level 1

## Technik

| Komponente | Verwendet |
|---|---|
| Engine | [Solarus](https://www.solarus-games.org/) 2.1 |
| Editor | Solarus Quest Editor |
| Sprache | Lua (LuaJIT) |
| Grafik | LibreSprite (Pixel-Art) |
| Fragen | JSON-Dateien in `data/questions/` |
| Plattform | Windows, Linux · offline · nur Tastatur |

## Starten

1. [Solarus Launcher / Quest Editor](https://www.solarus-games.org/en/development/download) installieren
2. Repository klonen:
   ```bash
   git clone https://github.com/Cuteferrer/QuizQuest.git
   ```
3. Im Quest Editor den Ordner `QuizQuest` öffnen und das Spiel starten (oder im Solarus Launcher den Ordner hinzufügen)

## Steuerung

| Taste | Funktion |
|---|---|
| Pfeiltasten | Bewegen / Antwort auswählen |
| Aktionstaste | NPC ansprechen, Kampf starten |
| Leertaste | Antwort markieren |
| Enter | Antwort bestätigen |
| Escape | Pausemenü / Kampf abbrechen |

## Projektstruktur

```
data/
├── maps/        Klassenzimmer, Flure, Lehrerräume
├── questions/   Fragenkataloge (JSON) je Themengebiet
├── scripts/     Spiellogik (game_manager, quiz_menu, json, HUD, Menüs)
├── sprites/     Figuren und Objekte
├── tilesets/    Kachelgrafiken
└── main.lua     Einstiegspunkt
```
|

## Lizenz

Projektcode: siehe [LICENSE](LICENSE). Die Solarus-Engine steht unter der GPL v3.
QuizQuest ist ein Schulprojekt und nur für den Einsatz an der BSZ 3 Regensburg vorgesehen.
