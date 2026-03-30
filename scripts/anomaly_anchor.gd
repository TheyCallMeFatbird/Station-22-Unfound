extends Marker3D

@export var target_path: NodePath
@export_enum("missing", "moved", "scaled", "tinted") var anomaly_type := "missing"

func _enter_tree():
	add_to_group("anomaly_anchor")

func get_target() -> Node3D:
	if target_path.is_empty():
		return null
	return get_node_or_null(target_path) as Node3D
