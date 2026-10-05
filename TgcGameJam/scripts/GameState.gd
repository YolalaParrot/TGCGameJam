extends Node

var flags := {
	"start":true,
	"met_jim":false
}

var gameState := {
	"in_dialogue":false,
	"inventory_open":false
}

var items: Array = [{"name":"Icon","image":"res://icon.svg"}]

func add_item(item_name: String, image: String) -> void:
	items.append({"name": item_name, "image": image})
	Inventory.refresh()

const Map := {
	"farm": [
		{"to": "town_one", "exit": "town_one_transition"},
	],
	"hillside": [
		{"to": "town_two", "exit": "town_two_transition"},
	],
	"town_one": [
		{"to": "town_two", "exit": "town_two_transition"},
		{"to": "farm", "exit": "farm_transition"},
	],
	"town_two": [
		{"to": "town_one", "exit": "town_one_transition"},
		{"to": "hillside", "exit": "hillside_transition"},
	],
}

# Where each NPC currently is: loc is the map name, pos the position inside that map (like in the editor)
var npc_state := {
	"jim": {"loc": "town_one", "pos": Vector2(80, 50)},
}

func npc_map(npc_name: String) -> String:
	if not npc_state.has(npc_name):
		return ""
	return npc_state[npc_name].loc

func npc_pos(npc_name: String):
	if not npc_state.has(npc_name):
		return null
	return npc_state[npc_name].pos

#Initial Dialogues(We will be changing these)
var dialogues := {
	"jim":{"counter":0,"dialogues":[
			{
				"requires":{"start":true},
				"forbids":{},
				# sections run by execute(): "set" {flag: value}, "move" [{"npc", "location", "position"}]
				# (Jim's walk to the hill is handled separately)
				"on_finish":{"set":{"met_jim":true}},
				"lines":[
					[
						{"Jim":"Bro , Did you hear the news, the world is about to end!!!!!!!!"},
						{"Jim":"In 16hrsss!!!!"},
						{"Player":"Whaaaaat"}
					],
					[
						{"Jim":"Quickly , Come out , We have to go to the hill"}
					]
				]
			},
			{
				"requires":{"met_jim":true},
				"forbids":{},
				"on_finish":{},
				"lines":[[{"Jim":"Hello"}]],
			},
		]
	}
}

const Tasks := {
	"main":[
		{
			"requires":{"start":true},
			"forbids":{"met_jim":true},
			"task":{"name":"Talk to Jim","location":"hillside","target":"jim"}
		}
	]
}

# requires: every flag must equal its value. forbids: blocked if a flag equals its value.
func conditions_met(entry: Dictionary):
	for flag in entry.requires:
		if flags.get(flag) != entry.requires[flag]:
			return false
	for flag in entry.forbids:
		if flags.has(flag) and flags[flag] == entry.forbids[flag]:
			return false
	return true


# Runs the named sections of an on_finish dictionary. Dialogue and cutscenes both call this.
func execute(on_finish: Dictionary) -> void:
	for section in on_finish:
		match section:
			"set":
				for flag in on_finish["set"]:
					flags[flag] = on_finish["set"][flag]
			"move":
				for move in on_finish["move"]:
					move_npc(move.npc, move.location, move.position)
			_:
				push_warning("Unknown on_finish section: " + str(section))


func move_npc(npc_name: String, location: String, position: Vector2) -> void:
	var old_map := npc_map(npc_name)
	npc_state[npc_name] = {"loc": location, "pos": position}
	var npc := get_tree().current_scene.find_child(npc_name, true, false) as Node2D
	if npc == null:
		return
	if location == old_map:
		npc.position = position
	else:
		npc.queue_free()


func cutscene_seen(cutscene_id: String) -> bool:
	return flags.get("seen_" + cutscene_id, false)


func mark_cutscene_seen(cutscene_id: String) -> void:
	flags["seen_" + cutscene_id] = true

func get_current_tasks()->Dictionary:
	var mainTasks = Tasks.main
	for task in mainTasks:
		if conditions_met(task):
			return task.task
	return {}


func get_dialogue_set(npc: String)->Dictionary:
	var dialogue_sets = dialogues[npc].dialogues
	for dialogue_set in dialogue_sets:
		if conditions_met(dialogue_set):
			return dialogue_set
	return {}

func get_dialogue(npc: String)->Array:
	return get_dialogue_set(npc).get("lines", [])
