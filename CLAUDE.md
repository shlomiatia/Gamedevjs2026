# Gamedevjs2026 — Project Guide

## Scene Folder Convention

Every scene lives in its own subfolder under `Scenes/`, named after the scene:

```
Scenes/
  Buildings/      ← building scenes
    Building/     ← base building scene (inherited by all buildings)
      Building.tscn
      building.gd
    WoodcutterHut/
      WoodcutterHut.tscn  ← inherits Building.tscn
      woodcutter_hut.gd
    BuilderHut/
      BuilderHut.tscn     ← inherits Building.tscn
      builder_hut.gd
  Workers/        ← worker/unit scenes
    Builder/
      Builder.tscn
  Resources/      ← resource item scenes
    Log/
      Log.tscn
      log.gd
    ResourcePile/
      ResourcePile.tscn
      resource_pile.gd
  Tree/
    Tree.tscn
  Camera/
    Camera.tscn
    camera.gd
  BuildingManager/
    BuildingManager.tscn
    building_manager.gd
  ...
```

**Exception:** `Scenes/Main.tscn` and `Scenes/main.gd` live directly in `Scenes/` — Main is the level scene, not a reusable prefab.

**Category subfolders:** Group related scenes under a category folder (`Buildings/`, `Workers/`, `Resources/`). Each scene still gets its own named subfolder within the category.

**Buildings standard:** All buildings inherit `Building.tscn`. Building scripts extend `Building` (class_name) and define constants (`SIZE_X`, `SIZE_Y`, `BUILDING_NAME`). Building-specific placement logic goes in `on_placed(spawn_parent, tile_size)` — override in the building's script.

**Building base scene layout:** Sprite2D at (0, -104), NameLabel at (-100, -225), InputPile (ResourcePile) at (-32, 16), OutputPile (ResourcePile) at (32, 16). The `building_name` export sets the label text.

**ResourcePile:** Node2D with y_sort disabled. Call `add_resource(scene)` to push a resource onto the pile; each successive resource is stacked `SPACE` (8) px above the previous.

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
