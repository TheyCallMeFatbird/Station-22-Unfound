extends Node3D

const CATEGORY_LABELS := {
	"missing": "Missing Object",
	"moved": "Moved Object",
	"scaled": "Scale Mismatch",
	"tinted": "Color Shift"
}

@export var anomalies_per_shift := 3

@onready var terminal_area: Area3D = $ReportTerminal/Area3D
@onready var terminal_text: Label3D = $ReportTerminal/TerminalText
@onready var player: CharacterBody3D = $"../Player"

var anchors: Array[Node] = []
var baseline := {}
var active_anomalies: Array[Node] = []
var report_options := ["missing", "moved", "scaled", "tinted"]
var report_index := 0
var score := 0
var wrong_reports := 0
var shift := 1
var player_in_terminal := false

func _ready():
	for node in get_tree().get_nodes_in_group("anomaly_anchor"):
		var anchor := node as Node
		if anchor:
			anchors.append(anchor)
	_cache_baseline()
	terminal_area.body_entered.connect(_on_terminal_entered)
	terminal_area.body_exited.connect(_on_terminal_exited)
	start_new_shift()
	_update_terminal_text()

func _process(_delta):
	if not player_in_terminal:
		return

	if Input.is_action_just_pressed("ui_left"):
		report_index = (report_index - 1 + report_options.size()) % report_options.size()
		_update_terminal_text()
	elif Input.is_action_just_pressed("ui_right"):
		report_index = (report_index + 1) % report_options.size()
		_update_terminal_text()

	if Input.is_action_just_pressed("ui_accept"):
		submit_report(report_options[report_index])

func _cache_baseline():
	baseline.clear()
	for anchor in anchors:
		var target: Node3D = _get_target_from_anchor(anchor)
		if target == null:
			continue
		baseline[anchor] = {
			"position": target.position,
			"scale": target.scale,
			"visible": target.visible,
			"modulate": _get_modulate(target),
		}

func start_new_shift():
	restore_baseline()
	active_anomalies.clear()

	var candidates: Array[Node] = anchors.duplicate()
	candidates.shuffle()
	for anchor in candidates:
		if active_anomalies.size() >= anomalies_per_shift:
			break
		if _get_target_from_anchor(anchor) == null:
			continue
		active_anomalies.append(anchor)
		apply_anomaly(anchor)

	_update_terminal_text()

func restore_baseline():
	for anchor_key in baseline.keys():
		var anchor := anchor_key as Node
		if anchor == null:
			continue
		var target: Node3D = _get_target_from_anchor(anchor)
		if target == null:
			continue
		var data = baseline[anchor]
		target.position = data["position"]
		target.scale = data["scale"]
		target.visible = data["visible"]
		_set_modulate(target, data["modulate"])

func apply_anomaly(anchor: Node):
	var target: Node3D = _get_target_from_anchor(anchor)
	if target == null:
		return

	match anchor.anomaly_type:
		"missing":
			target.visible = false
		"moved":
			target.position += Vector3(randf_range(-1.6, 1.6), 0.0, randf_range(-1.6, 1.6))
		"scaled":
			target.scale *= randf_range(0.55, 1.65)
		"tinted":
			_set_modulate(target, Color(0.15, 0.75, 1.0, 1.0))

func submit_report(report_type: String):
	for i in range(active_anomalies.size()):
		var anchor: Node = active_anomalies[i]
		if anchor.anomaly_type == report_type:
			score += 1
			active_anomalies.remove_at(i)
			_update_terminal_text("Correct report")
			if active_anomalies.is_empty():
				shift += 1
				start_new_shift()
			return

	wrong_reports += 1
	_update_terminal_text("No anomaly matched")

func _on_terminal_entered(body):
	if body == player:
		player_in_terminal = true
		_update_terminal_text()

func _on_terminal_exited(body):
	if body == player:
		player_in_terminal = false
		terminal_text.text = "Report Terminal\nWalk into range to use"

func _update_terminal_text(status := ""):
	var selection = CATEGORY_LABELS.get(report_options[report_index], report_options[report_index])
	var lines := [
		"Report Terminal",
		"Shift: %d  Score: %d  Misses: %d" % [shift, score, wrong_reports],
		"Active Anomalies: %d" % active_anomalies.size(),
	]

	if player_in_terminal:
		lines.append("Select: < %s >" % selection)
		lines.append("[Left/Right] Cycle  [Enter] Submit")
	else:
		lines.append("Walk into range to use")

	if status != "":
		lines.append(status)

	terminal_text.text = "\n".join(lines)

func _get_modulate(target: Node3D) -> Color:
	if "modulate" in target:
		return target.modulate
	if target is Light3D:
		return target.light_color
	return Color(1, 1, 1, 1)

func _set_modulate(target: Node3D, color: Color):
	if "modulate" in target:
		target.modulate = color
	elif target is Light3D:
		target.light_color = color

func _get_target_from_anchor(anchor: Node) -> Node3D:
	if anchor == null or not anchor.has_method("get_target"):
		return null
	return anchor.get_target() as Node3D
