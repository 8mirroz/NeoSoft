extends RefCounted
class_name GameplayNodeRefs

var level_session: Node
var board_visual: Node
var world_title: Label
var level_subtitle: Label
var progress_bar: ProgressBar
var mission_goals: HBoxContainer
var moves_panel: PanelContainer
var score_panel: PanelContainer
var moves_value: Label
var score_value: Label
var status_label: Label
var shuffle_button: Button
var hammer_button: Button
var undo_button: Button
var star_labels: Array[Label] = []

static func from_scene(root: Node) -> GameplayNodeRefs:
	var refs := GameplayNodeRefs.new()
	refs.level_session = root.get_node_or_null("LevelSession")
	refs.board_visual = root.get_node_or_null("BoardArea/BoardFrame/BoardPadding/BoardVisual")
	refs.world_title = root.get_node_or_null("HUD/TopBar/Layout/LevelPanel/Content/WorldTitle")
	refs.level_subtitle = root.get_node_or_null("HUD/TopBar/Layout/LevelPanel/Content/LevelSubtitle")
	refs.progress_bar = root.get_node_or_null("HUD/TopBar/Layout/LevelPanel/Content/ProgressBar")
	refs.mission_goals = root.get_node_or_null("HUD/TopBar/Layout/MissionPanel/Content/GoalItems")
	refs.moves_panel = root.get_node_or_null("HUD/TopBar/Layout/StatsColumn/MovesPanel")
	refs.score_panel = root.get_node_or_null("HUD/TopBar/Layout/StatsColumn/ScorePanel")
	refs.moves_value = root.get_node_or_null("HUD/TopBar/Layout/StatsColumn/MovesPanel/Content/Value")
	refs.score_value = root.get_node_or_null("HUD/TopBar/Layout/StatsColumn/ScorePanel/Content/Value")
	refs.status_label = root.get_node_or_null("HUD/StatusLabel")
	refs.shuffle_button = root.get_node_or_null("HUD/BoosterBar/Layout/ShuffleButton")
	refs.hammer_button = root.get_node_or_null("HUD/BoosterBar/Layout/HammerButton")
	refs.undo_button = root.get_node_or_null("HUD/BoosterBar/Layout/UndoButton")
	
	var stars_container: Node = root.get_node_or_null("HUD/TopBar/Layout/LevelPanel/Content/Stars")
	if stars_container != null:
		for i in range(1, 4):
			var star: Label = stars_container.get_node_or_null("Star%d" % i) as Label
			if star != null:
				refs.star_labels.append(star)
				
	return refs

func collect_missing() -> Array[String]:
	var missing: Array[String] = []
	if level_session == null: missing.append("LevelSession")
	if board_visual == null: missing.append("BoardArea/BoardFrame/BoardPadding/BoardVisual")
	if world_title == null: missing.append("HUD/TopBar/Layout/LevelPanel/Content/WorldTitle")
	if level_subtitle == null: missing.append("HUD/TopBar/Layout/LevelPanel/Content/LevelSubtitle")
	if progress_bar == null: missing.append("HUD/TopBar/Layout/LevelPanel/Content/ProgressBar")
	if mission_goals == null: missing.append("HUD/TopBar/Layout/MissionPanel/Content/GoalItems")
	if moves_panel == null: missing.append("HUD/TopBar/Layout/StatsColumn/MovesPanel")
	if score_panel == null: missing.append("HUD/TopBar/Layout/StatsColumn/ScorePanel")
	if moves_value == null: missing.append("HUD/TopBar/Layout/StatsColumn/MovesPanel/Content/Value")
	if score_value == null: missing.append("HUD/TopBar/Layout/StatsColumn/ScorePanel/Content/Value")
	if status_label == null: missing.append("HUD/StatusLabel")
	if shuffle_button == null: missing.append("HUD/BoosterBar/Layout/ShuffleButton")
	if hammer_button == null: missing.append("HUD/BoosterBar/Layout/HammerButton")
	if undo_button == null: missing.append("HUD/BoosterBar/Layout/UndoButton")
	if star_labels.size() < 3: missing.append("Star labels (at least 3 stars expected)")
	return missing
