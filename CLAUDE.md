# Gamedevjs2026 — Project Guide

## Development Workflow

**After every code change, run the game and verify it starts without parser errors or crashes before reporting the task as done.** Use the `mcp__godot__run_project` tool, wait ~5 seconds, then call `mcp__godot__get_debug_output` and check for errors. Stop the project with `mcp__godot__stop_project` when done. Fix any errors found before finishing.

---

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

**Buildings standard:** Each building is a standalone Node2D scene containing a `Building` component node (instanced from `Building.tscn`). Building scripts extend `Node2D`, define constants (`SIZE_X`, `SIZE_Y`, `BUILDING_NAME`), and delegate visual/construction logic to `$Building` (`BuildingComponent`). Placement logic goes in `on_placed(spawn_parent, map, coordination_manager, forest)`.

**Building component layout:** `BuildingComponent` (`Building.tscn`) contains: Sprite2D (house) at (0, -104), NameLabel at (-100, -225), OutputPile (ResourcePile) at (0, 16), and a Mill node (hidden unless `has_mill = true`). No InputPile. The `building_name` and `has_mill` exports are set per-instance in each building's `.tscn`.

**ResourcePile:** Node2D with y_sort disabled. Call `add_resource(scene)` to push a resource onto the pile; each successive resource is stacked `SPACE` (8) px above the previous.

---

## Tileset Reference

**File:** `Textures/tileset.tres` / `Textures/tileset.png`
**Tile size:** 32×32 px

Tiles are referenced by atlas coordinates (col:row), zero-based.

### Dirt tiles (overlay layer)

| Atlas (col:row) | Name | Connections / Notes |
|-----------------|------|---------------------|
| 0:0 | Grass | Full grass tile (base layer) |
| 1:0 | Dirt | Full dirt tile |
| 2:0 | Dirt – 3-way junction | Opens: top, right, bottom |
| 3:0 | Dirt – 3-way junction | Opens: left, bottom, right |
| 4:0 | Dirt – 4-way junction | Opens: top, right, bottom, left |
| 0:1 | Dirt – Straight | Opens: left, right |
| 1:1 | Dirt – Straight | Opens: top, bottom |
| 2:1 | Dirt – 3-way junction | Opens: left, top, right |
| 3:1 | Dirt – 3-way junction | Opens: top, left, bottom |
| 0:2 | Dirt – Curve | Opens: bottom, right |
| 1:2 | Dirt – Curve | Opens: left, bottom |
| 2:2 | Dirt – Dead end | Opens: top only |
| 3:2 | Dirt – Dead end | Opens: right only |
| 0:3 | Dirt – Curve | Opens: top, right |
| 1:3 | Dirt – Curve | Opens: left, top |
| 2:3 | Dirt – Dead end | Opens: bottom only |
| 3:3 | Dirt – Dead end | Opens: left only |

Dirt tiles are overlay tiles — placed on the **Grass** TileMapLayer on top of other tiles.

### Grass overlay tiles (placed over other terrain)

These tiles are partially grass and partially transparent, designed to blend grass edges over a different terrain underneath.

| Atlas (col:row) | Grass coverage |
|-----------------|----------------|
| 5:0 | Frame — grass on all four edges, empty (transparent) in the middle |
| 5:3 | Edge — top edge only (variant; used when right, bottom, and left are dirt) |
| 4:1 | Corner — bottom-right corner only |
| 5:1 | Edge — bottom edge only |
| 6:1 | Corner — bottom-left corner only |
| 4:2 | Edge — right edge only |
| 5:2 | Full grass tile |
| 6:2 | Edge — left edge only |
| 4:3 | Corner — top-right corner only |
| 4:4 | Edge — top edge only |
| 4:5 | Corner — top-left corner only |
| 0:4 | Two edges — top and left |
| 1:4 | Two edges — top and right |
| 0:5 | Two edges — left and bottom |
| 1:5 | Two edges — bottom and right |
