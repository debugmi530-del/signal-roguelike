class_name StationTheme
extends Resource

## One of the "frequency" themes a station can spawn as. Each theme bundles a
## palette plus the enemy pool that appears more often there, so new themes
## can be added later without touching the room generator.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var background_color: Color = Color(0.05, 0.06, 0.1)
@export var wall_color: Color = Color(0.16, 0.18, 0.26)
@export var accent_color: Color = Color(0.2, 0.9, 1.0)
## Enemy ids (matching EnemyData.id) more likely to appear on this theme.
@export var favored_enemy_ids: Array[String] = []
