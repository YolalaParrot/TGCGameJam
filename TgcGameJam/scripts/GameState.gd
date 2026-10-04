extends Node

var flags := {
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

#Initial Dialogues(We will be changing these)
var dialogues := {
	"npc1":{"counter":0,"dialogues":{0:["Bro , Did you hear the news, the world is about to end!!!!!!!!
","In 16hrsss!!!!"],1:["Quickly , Come out , We have to go to the hill"],
}}
}

var currentTasks := {
	"main":{"name":"Talk to Jim","location":"hillside","target":"npc1"}
}
