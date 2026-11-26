# Fragendaten

Jede Datei in diesem Ordner enthält ein JSON-Array mit Fragen. Die Prüfregeln V1–V9 stehen im Pflichtenheft (Anhang D der Projektdokumentation); hier steht nur die Regel für Fragenbilder, weil sie direkt mit dem Ordner `data/images/` zusammenhängt.

## Regel für Fragenbilder (Teil der Validierung V1–V9)

- `media` ist entweder `null` oder ein Objekt mit genau zwei Feldern:
  `"type": "image"` und `"alt"` mit einer Beschreibung des Bildes.
- Ein Feld `src` gibt es nicht. Das Bild wird allein über die Fragen-ID gefunden:
  Zu jeder Frage mit `media` muss `data/images/<id>.png` existieren, in derselben
  Schreibweise wie die ID (z. B. `AE2_UML_Q002.png`). `quiz_menu.lua` lädt das Bild genau so.
- Neue Bilder deshalb immer nach der Fragen-ID benennen und ohne Unterordner in `data/images/` ablegen.

Bei einem Verstoß:

| Fall | Verhalten |
|---|---|
| Bilddatei fehlt oder `type` ist nicht `"image"` | Frage wird übersprungen und in der Konsole gemeldet |
| `media` enthält noch ein Feld `src` | Nur Warnung in der Konsole, Frage bleibt im Spiel (das Feld wird nicht ausgewertet) |

Beispiel:

```json
"media": {
  "type": "image",
  "alt": "UML Klassendiagramm mit Basisklasse und abgeleiteten Klassen"
}
```
