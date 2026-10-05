extends Node

# Every cutscene has the same shape as a dialogue entry:
#   "scene"      the scene to play
#   "npc"        optional NPC name: talking to that NPC plays it first, their dialogues only
#                play once it is seen or its requires/forbids no longer pass
#   "requires" / "forbids"   flag conditions, checked like dialogues (see GameState.conditions_met)
#   "on_finish"  run through GameState.execute when it finishes (same sections and guard as dialogues)
#                plus "next": the id of a cutscene to play straight after, still faded to black
# A cutscene is marked seen (flag seen_<id>) when it finishes, and an NPC only plays it once.
# Triggers (cutscene_trigger.gd) check requires/forbids too, so a cutscene can replace a dialogue.
var cutscenes: Dictionary = {
	"town1_intro": {
		"scene": "res://scenes/cutscenes/town1_intro.tscn",
		"npc": "jim",
		"requires": {"start": true},
		"forbids": {"met_jim": true},
		"on_finish": GameState.MEET_JIM  # same effects as Jim's first dialogue
	},

	# Hill: Ken's rocket plan (replaces his first dialogue)
	"scene_2": {
		"scene": "res://scenes/cutscenes/scene_2.tscn",
		"npc": "ken",
		"requires": {"met_jim": true},
		"forbids": {"met_ken": true},
		"on_finish": {"set": {"met_ken": true}}
	},

	# Hill: Finn gets the wood
	"scene_3": {
		"scene": "res://scenes/cutscenes/scene_3.tscn",
		"npc": "finn",
		"requires": {"got_wood": true},
		"forbids": {"wood_delivered": true},
		"on_finish": {"set": {"wood_delivered": true}, "take": ["Wood"]}
	},

	# Hill: Finn gets the engine parts
	"scene_4": {
		"scene": "res://scenes/cutscenes/scene_4.tscn",
		"npc": "finn",
		"requires": {"wood_delivered": true, "parts_game": "won"},
		"forbids": {"parts_delivered": true},
		"on_finish": {"set": {"parts_delivered": true}, "take": ["Engine Parts"]}
	},

	# The ending, played back to back from Ken once Bob's fuel is in: the engine fails,
	# Hailey's comet, "it didn't kill us", the last painting, then the credits.
	"scene_5": {
		"scene": "res://scenes/cutscenes/scene_5.tscn",
		"npc": "ken",
		"requires": {"rps_game": "won"},
		"forbids": {"engine_failed": true},
		"on_finish": {"set": {"engine_failed": true}, "take": ["Fuel"], "next": "scene_hailey"}
	},

	"scene_hailey": {
		"scene": "res://scenes/cutscenes/scene_Hailey.tscn",
		"requires": {"engine_failed": true},
		"forbids": {},
		"on_finish": {"set": {"comet_seen": true}, "next": "scene_5_5"}
	},

	"scene_5_5": {
		"scene": "res://scenes/cutscenes/scene_5_5.tscn",
		"requires": {"comet_seen": true},
		"forbids": {},
		"on_finish": {"next": "scene_6"}
	},

	"scene_6": {
		"scene": "res://scenes/cutscenes/scene_6.tscn",
		"requires": {"comet_seen": true},
		"forbids": {},
		"on_finish": {"set": {"game_complete": true}, "credits": true}
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
