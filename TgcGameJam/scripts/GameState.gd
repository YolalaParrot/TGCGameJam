extends Node

var flags := {
	"start":true,
	"met_friend":false
}

var gameState := {
	"in_dialogue":false
}

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

var positions := {
	"jim":{"start":{"loc":"town_one","pos":Vector2(80,50)}}
}

#Initial Dialogues(We will be changing these)
var dialogues := {
	"npc1":{"counter":0,"dialogues":[
			{
				"requires":["start"],
				"forbids":[],
				"lines":[[
					{"Jim":"Bro , Did you hear the news, the world is about to end!!!!!!!!"},
					{"Jim":"In 16hrsss!!!!"},
					{"Player":"Whaaaaat"}
				],
				[{"Jim":"Quickly , Come out , We have to go to the hill"}]]
			},
			{
				"requires":[],
				"forbids":[],
				"lines":[[{"Jim":"Hello"}]],
			},
		]
	}
}

var currentTasks := {
	"main":{"name":"Talk to Jim","location":"hillside","target":"npc1"}
}


func conditions_met(entry: Dictionary):
	for cond in entry.requires:
		if not flags.has(cond) or not flags[cond]:
			return false
	for cond in entry.forbids:
		if flags.get(cond, false):
			return false
	print("Conditions Met")
	return true


func get_dialogue(npc: String)->Array:
	var dialogue_sets = dialogues[npc].dialogues
	for dialogue_set in dialogue_sets:
		if conditions_met(dialogue_set):
			return dialogue_set.lines
	return []
