extends Node

signal journal_updated

var entries: Array = []

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("observe"):
		get_tree().get_root().get_node("Node3D/HUD").open_note_prompt()

func add_entry(note_text: String, timestamp: String):
	entries.append({
		"note": note_text,
		"time": timestamp,
		"screenshot": null,  # slot for later
		"submitted": false    # slot for terminal reporting later
	})
	emit_signal("journal_updated")
