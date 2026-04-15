# Gamedevjs2026 — Project Guide

## Scene Folder Convention

Every scene lives in its own subfolder under `Scenes/`, named after the scene:

```
Scenes/
  Tree/
    Tree.tscn
    tree.gd          (if the scene has a script)
  Camera/
    Camera.tscn
    camera.gd
  BuildingManager/
    BuildingManager.tscn
    building_manager.gd
  Buildings/          ← all building scenes live here
    WoodcutterHut/
      WoodcutterHut.tscn
      woodcutter_hut.gd
    BuilderHut/
      BuilderHut.tscn
      builder_hut.gd
  ...
```

**Exception:** `Scenes/Main.tscn` and `Scenes/main.gd` live directly in `Scenes/` — Main is the level scene, not a reusable prefab.

**Buildings standard:** All building scenes live under `Scenes/Buildings/<BuildingName>/`. Building scripts use `class_name` so their constants (e.g. `SIZE_X`, `SIZE_Y`, `BUILDING_NAME`) are globally accessible without a preload.

---

## Tileset Reference

**File:** `Textures/tileset.tres` / `Textures/tileset.png`
**Tile size:** 32×32 px
**Grid:** 5 columns × 5 rows (25 tiles total, 8 empty)

Tiles are indexed left-to-right, top-to-bottom (0 = top-left, 4 = top-right, 5 = second row left, etc.).

| Index | Atlas (col:row) | Name | Connections / Notes |
|-------|-----------------|------|---------------------|
| 0  | 0:0 | Grass | Full grass tile (base layer) |
| 1  | 1:0 | Road | Full road tile |
| 2  | 2:0 | Road – 3-way junction | Opens: top, right, bottom |
| 3  | 3:0 | Road – 3-way junction | Opens: left, bottom, right |
| 4  | 4:0 | Road – 4-way junction | Opens: top, right, bottom, left |
| 5  | 0:1 | Road – Straight | Opens: left, right |
| 6  | 1:1 | Road – Straight | Opens: top, bottom |
| 7  | 2:1 | Road – 3-way junction | Opens: left, top, right |
| 8  | 3:1 | Road – 3-way junction | Opens: top, left, bottom |
| 9  | 4:1 | *(empty)* | — |
| 10 | 0:2 | Road – Curve | Opens: bottom, right |
| 11 | 1:2 | Road – Curve | Opens: left, bottom |
| 12 | 2:2 | Road – Dead end | Opens: top only |
| 13 | 3:2 | Road – Dead end | Opens: right only |
| 14 | 4:2 | *(empty)* | — |
| 15 | 0:3 | Road – Curve | Opens: top, right |
| 16 | 1:3 | Road – Curve | Opens: left, top |
| 17 | 2:3 | Road – Dead end | Opens: bottom only |
| 18 | 3:3 | Road – Dead end | Opens: left only |
| 19–24 | — | *(empty)* | — |

Road tiles (2–18) are overlay tiles — they are placed on the **Grass** TileMapLayer on top of other tiles such as the Road layer.
