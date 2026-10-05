extends Node

# Every cutscene has the same shape as a dialogue entry:
#   "scene"      the scene to play
#   "npc"        optional NPC name: talking to that NPC plays it (before their dialogues)
#   "requires" / "forbids"   flag conditions, checked like dialogues (see GameState.conditions_met)
#   "on_finish"  run through GameState.execute when it finishes (same sections and guard as dialogues)
# A cutscene is marked seen (flag seen_<id>) when it finishes, and an NPC only plays it once.
# Triggers (cutscene_trigger.gd) check requires/forbids too, so a cutscene can replace a dialogue.
var cutscenes: Dictionary = {
	"town1_intro": {
		"scene": "res://scenes/cutscenes/town1_intro.tscn",
		"requires": {"start": true},
		"forbids": {},
		"on_finish": {}
	},

	"world_end_warning": {
		"scene": "res://scenes/cutscenes/town1_intro.tscn",
		"requires": {},
		"forbids": {},
		"on_finish": {}
	},

	"all_friends_meeting": {
		"scene": "res://scenes/cutscenes/town1_intro.tscn",
		"requires": {},
		"forbids": {},
		"on_finish": {}
	}
}


func has_cutscene(cutscene_id: String) -> bool:
	return cutscenes.has(cutscene_id)


func get_cutscene(cutscene_id: String) -> Dictionary:
	if not cutscenes.has(cutscene_id):
		return {}

	return cutscenes[cutscene_id]


# requires/forbids pass for the current flags.
func conditions_ok(cutscene_id: String) -> bool:
	return has_cutscene(cutscene_id) and GameState.conditions_met(cutscenes[cutscene_id])


# The first unseen cutscene this NPC plays right now, or "" if there is none.
func find_for_npc(npc_name: String) -> String:
	for cutscene_id in cutscenes:
		if cutscenes[cutscene_id].get("npc", "") != npc_name:
			continue
		if not GameState.cutscene_seen(cutscene_id) and conditions_ok(cutscene_id):
			return cutscene_id
	return ""
