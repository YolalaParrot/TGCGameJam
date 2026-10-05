extends Node


var cutscenes: Dictionary = {
	"town1_intro": {
		"scene": "res://scenes/cutscenes/town1_intro.tscn",
		"on_finish": {"set": {"met_jim": true}}
	},

	"world_end_warning": {
		"scene": "res://scenes/cutscenes/town1_intro.tscn"
	},

	"all_friends_meeting": {
		"scene": "res://scenes/cutscenes/town1_intro.tscn"
	}
}


func has_cutscene(cutscene_id: String) -> bool:
	return cutscenes.has(cutscene_id)


func get_cutscene(cutscene_id: String) -> Dictionary:
	if not cutscenes.has(cutscene_id):
		return {}

	return cutscenes[cutscene_id]
