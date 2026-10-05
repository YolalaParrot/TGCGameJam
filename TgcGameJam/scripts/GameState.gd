extends Node


@export var flags := {
	"start":true,
	"met_jim":false,
	"met_ken":false,
	"met_willy":false,
	"dance_battle":"not_started",
	"got_wood":false,
	"wood_delivered":false,
	"met_mrs_smith":false,
	"parts_game":"not_started",
	"parts_delivered":false,
	"met_bob":false,
	"rps_game":"not_started",
	"engine_failed":false,
	"comet_seen":false,
	"game_complete":false
}

var gameState := {
	"in_dialogue":false,
	"inventory_open":false,
	"in_minigame":false
}

signal task_changed
signal flag_changed(flag: String, value)
const task_fade_in := 0.5
const task_show_time := 2.0
const task_fade_out := 0.5
const item_show_time := 1.25
var task_tween: Tween

var trial_stage := "final"
const trial_stages := {
	"got_wood": {
		"flags": {"met_jim":true, "seen_town1_intro":true, "met_ken":true, "met_willy":true,
			"dance_battle":"won", "got_wood":true},
		"items": [wood],
	},
	"light_minigame": {
		"flags": {"met_jim":true, "seen_town1_intro":true, "met_ken":true, "met_willy":true,
			"dance_battle":"won", "got_wood":true,"wood_delivered":true,"met_mrs_smith":true},
	},
	"bob": {
		"flags": {"met_jim":true, "seen_town1_intro":true, "met_ken":true, "met_willy":true,
			"dance_battle":"won", "got_wood":true, "wood_delivered":true, "met_mrs_smith":true,
			"parts_game":"won", "parts_delivered":true},
	},
	"final": {
		"flags": {"met_jim":true, "seen_town1_intro":true, "met_ken":true, "met_willy":true,
			"dance_battle":"won", "got_wood":true, "wood_delivered":true, "met_mrs_smith":true,
			"parts_game":"won", "parts_delivered":true,"met_bob":true,"rps_game":"won",
	"engine_failed":true,
	"comet_seen":true,
	"game_complete":true},
	},
}

func _ready() -> void:
	if trial_stage != "":
		start_trial(trial_stage)
	announce_task.call_deferred()


func start_trial(stage: String) -> void:
	var trial: Dictionary = trial_stages[stage]
	flags.merge(trial.get("flags", {}), true)
	items.append_array(trial.get("items", []))
	print("TRIAL RUN from stage: ", stage)

var items: Array = []

func add_item(item_name: String, image: String) -> void:
	items.append({"name": item_name, "image": image})
	Inventory.refresh()

func remove_item(item_name: String) -> void:
	for i in items.size():
		if items[i].name == item_name:
			items.remove_at(i)
			break
	Inventory.refresh()

const wood := {"name":"Wood","image":"res://assets-temp/wood_planks.jpg"}
const engine_parts := {"name":"Engine Parts","image":"res://assets-temp/engine_parts.png"}
const fuel := {"name":"Fuel","image":"res://assets-temp/fuel.png"}

const rps_game := {
	"scene": "res://scenes/rock_paper_scissors.tscn",
	"result_flag": "rps_game",
	"on_won": {"give": [fuel]},
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
		{"to": "player_house", "exit": "player_house_transition"},
	],
	"town_two": [
		{"to": "town_one", "exit": "town_one_transition"},
		{"to": "hillside", "exit": "hillside_transition"},
	],
	"player_house": [
		{"to": "town_one", "exit": "town_one_transition"},
	],
}

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

const meet_jim := {
	"set": {"met_jim": true},
}

var dialogues := {
	"jim":{"dialogues":[
			# Town one: Jim meets the player (after the intro cutscene)
			{
				"requires":{"start":true},
				"forbids":{},
				"on_finish":meet_jim,
				"lines":[
					[
						{"Player":"Woahh."},
						{"Player":"Hey Jim! How are ya!? Long time no see"},
						{"Jim":"No time for talk Joe. You gotta come with me!!"},
						{"Player":"Wait what happened?"},
						{"Player":"You guys doing something?"},
						{"Jim":"Just follow me. The boys are waiting for us on the hill. They'll tell you there"},
						{"Player":"Alright come lets go!"}
					]
				]
			},
		]
	},
	"willy":{"dialogues":[
			# Dance challenge: WIN
			{
				"requires":{"dance_battle":"won"},
				"forbids":{},
				"on_finish":{"set":{"got_wood":true},"give":[wood]},
				"lines":[
					[
						{"Willy":"Alright you beat me kid fair and square! Take what you need i dont care about it anyways..."},
						{"Willy":"Itll all be over soon"},
						{"Player":"Well you can come with us! We are gonna escape in the rocket."},
						{"Willy":"We'll see"}
					]
				]
			},
			# Dance challenge: LOST
			{
				"requires":{"met_willy":true,"dance_battle":"lost"},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Willy":"Hah! Guess i really had a young soul all along!! Beat it kid you aint getting anything from this store."},
						{"Ken":"Get back and bring us the stuff!!!!!!"}
					]
				]
			},
			# Before the dance challenge
			{
				"requires":{"met_ken":true},
				"forbids":{},
				"on_finish":{"set":{"met_willy":true}},
				"lines":[
					[
						{"Willy":"Well son, ya hear the news huh? Its all over now."},
						{"Player":"Uncle Willy i have no time to explain but i need wood for a rocket."},
						{"Willy":"Goddamnit you kids always upto something..always doing something....FUN"},
						{"Willy":"Well guess what?! If im gonna go ill go out in style."},
						{"Willy":"Youre gonna have to keep up with me in dance to get your stuff."},
						{"Player":"Sigh alright whatever you say. But youre not gonna beat me old man!"},
						{"Willy":"We'll see!"}
					]
				]
			},
		]
	},
	"finn":{"dialogues":[
			# Hill: parts delivered, fuel needed
			{
				"requires":{"wood_delivered":true,"parts_game":"won"},
				"forbids":{},
				"on_finish":{"set":{"parts_delivered":true},"take":["Engine Parts"]},
				"lines":[
					[
						{"Finn":"Alright good. These parts should be enough."},
						{"Finn":"This engine is gonna take time. Meanwhile you go and get some fuel."},
						{"Player":"Alright! Only Mr Bob should have it."}
					]
				]
			},
			# Hill: wood delivered, engine parts needed
			{
				"requires":{"got_wood":true},
				"forbids":{},
				"on_finish":{"set":{"wood_delivered":true},"take":["Wood"]},
				"lines":[
					[
						{"Finn":"This should do. Lets get to work."},
						{"Finn":"Were going to need an engine. Youll have to get these parts. Heres a list."},
						{"Player":"Are you sure this will work? I never thought this is all it took to reach space."},
						{"Finn":"I know what im doing! Just get to work Joe. Mrs Smith should have this stuff."},
						{"Ken":"Just get what he says Joe! Humanity depends on this!"},
						{"Player":"Alright! Alright!"}
					]
				]
			},
		]
	},
	"mrs_smith":{"dialogues":[
			# WIN: the parts were found in the maze
			{
				"requires":{"parts_game":"won"},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Mrs Smith":"Found everything on that list? Good luck with whatever you're building, Joe!"}
					]
				]
			},
			# LOST: not every part was found in time
			{
				"requires":{"met_mrs_smith":true,"parts_game":"lost"},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Player":"Finn said we're gonna need all the parts to build the engine!"},
						{"Mrs Smith":"Sure go ahead, have another look inside."}
					]
				]
			},
			# Before the parts
			{
				"requires":{"wood_delivered":true},
				"forbids":{},
				"on_finish":{"set":{"met_mrs_smith":true}},
				"lines":[
					[
						{"Mrs Smith":"Oh he's inside doing god knows what!"},
						{"Mrs Smith":"Hey Joe what ya need?"},
						{"Player":"Hey Mrs Smith i have this list here."},
						{"Mrs Smith":"Well uh. Thats a lot of stuff.."},
						{"Mrs Smith":"Ya know what? I trust ya son. Just go inside and take what you need!"}
					]
				]
			},
		]
	},
	"bob":{"dialogues":[
			# WIN: Bob handed over the fuel
			{
				"requires":{"rps_game":"won"},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Bob":"Beaten by a kid.. Go on, take the fuel and get out of here."}
					]
				]
			},
			# Rematch, after a loss (or if the first match never started)
			{
				"requires":{"met_bob":true},
				"forbids":{"rps_game":"won"},
				"on_finish":{"flag":"rps_game","not_equal":"won","minigame":rps_game},
				"lines":[
					[
						{"Bob":"Back for more? Alright, one more round!"}
					]
				]
			},
			# Rock paper scissors challenge
			{
				"requires":{"parts_delivered":true},
				"forbids":{},
				"on_finish":{"set":{"met_bob":true},"minigame":rps_game},
				"lines":[
					[
						{"Player":"Mr Bob!"},
						{"Bob":"What could you possibly need now?"},
						{"Player":"I just need some fuel!"},
						{"Bob":"Hmm.."},
						{"Bob":"I have some extra but i aint giving it away just like that."},
						{"Bob":"Ya know what? Lets have a challenge! Beat me in rock paper scissors!"}
					]
				]
			},
		]
	},
	"ken":{"dialogues":[
			# Hill: the comet passes (the end frame and credits belong after this)
			{
				"requires":{"comet_seen":true},
				"forbids":{},
				"on_finish":{"set":{"game_complete":true}},
				"lines":[
					[
						{"Player":"Wait it didn't kill us.."},
						{"Jim":"What?."}
					]
				]
			},
			# Hill: it happens (the comet cutscene belongs after this)
			{
				"requires":{"engine_failed":true},
				"forbids":{},
				"on_finish":{"set":{"comet_seen":true}},
				"lines":[
					[
						{"Jim":"Lord its happening!"},
						{"Finn":"Oh nooo!!!"},
						{"Ken":"Finn this is all your fault!!!"},
						{"Finn":"Ken ive always wanted to say this.. You have bad teeth!!"}
					]
				]
			},
			# Hill: the engine fails (the flash bang cutscene belongs after this)
			{
				"requires":{"rps_game":"won"},
				"forbids":{},
				"on_finish":{"set":{"engine_failed":true},"take":["Fuel"]},
				"lines":[
					[
						{"Ken":"Is the engine in shape? This doesn't look anything like one.."},
						{"Finn":"Wait but this was supposed to work."},
						{"Ken":"FINN..DO YOU REALLY KNOW WHAT YOURE DOING?!"},
						{"Finn":"It should've worked.."},
						{"Ken":"Finn you useless little...!!"}
					]
				]
			},
			# Hill: the rocket plan (Ken, Finn and Jim all speak here)
			{
				"requires":{"met_jim":true},
				"forbids":{},
				"on_finish":{"set":{"met_ken":true}},
				"lines":[
					[
						{"Ken":"Hey Joe you're finally here huh!"},
						{"Player":"Yeah what are you guys up to?"},
						{"Player":"The town seemed awfully chaotic today? Is something happening?"},
						{"Ken":"Youre damn right it is!"},
						{"Finn":"THE WORLD IS ABOUT TO END!!!!"},
						{"Player":"What? Where'd you hear that?"},
						{"Finn":"Did you no-"},
						{"Ken":"DID YOU NOT READ THE DAMN NEWS? THOSE SCIENTISTS FROM THE CITY SAID A SPACE ROCK IS GONNA HIT US!! WE'RE ALL DOOMED!"},
						{"Finn":"Well but.. thats what i was about t-"},
						{"Ken":"Shush!! Dont talk when the king speaks subject!!"},
						{"Finn":"Sorry.."},
						{"Player":"Just stop this for lord's sake!"},
						{"Player":"So what do we do now?"},
						{"Ken":"\"What do we do?\""},
						{"Ken":"I guess we could sit and cry and ..wait for impending doom."},
						{"Ken":"OR we can all act grown ups and do something about it!"},
						{"Player":"Like what?"},
						{"Finn":"I read somewhere that we can bui-"},
						{"Finn":"Sorry... m-my lord..."},
						{"Ken":"We shall build a rocket!! A vessel that will take us to space!"},
						{"Ken":"You shall speak now subject."},
						{"Finn":"So i read in a book from the big city that we can build a rocket that can take us outside this world!"},
						{"Player":"Whaa--"},
						{"Finn":"Its like those planes but it can take you much higher?"},
						{"Player":"Huh? I suppose we could.."},
						{"Jim":"So we will need you to bring us materials for this rocket."},
						{"Jim":"Ya know the shopkeepers banned us. So youll have to do this."},
						{"Ken":"I suppose they cant handle all our royalty! They're jealous!"},
						{"Jim":"Finn says we will need wood first. Lots of it. Go to Uncle Willy!"},
						{"Player":"Alright i understand! Ill get to work!"},
						{"Player":"But i still cant believe our whole world is about to end."}
					]
				]
			},
		]
	}
}

const Tasks := {
	"main":[
		{
			"requires":{"start":true},
			"forbids":{"met_jim":true},
			"task":{"name":"Talk to Jim","location":"town_one","target":"jim"}
		},
		{
			"requires":{"met_jim":true},
			"forbids":{"met_ken":true},
			"task":{"name":"Go to Hill","location":"hillside","target":"ken"}
		},
		{
			"requires":{"met_ken":true},
			"forbids":{"met_willy":true},
			"task":{"name":"Ask Uncle Willy for wood","location":"town_two","target":"willy"}
		},
		{
			"requires":{"met_willy":true},
			"forbids":{"dance_battle":"won"},
			"task":{"name":"Win the Dance Battle","location":"town_two","target":"shop"}
		},
		{
			"requires":{"dance_battle":"won"},
			"forbids":{"got_wood":true},
			"task":{"name":"Collect the wood from Uncle Willy","location":"town_two","target":"willy"}
		},
		{
			"requires":{"got_wood":true},
			"forbids":{"wood_delivered":true},
			"task":{"name":"Take the wood to Finn","location":"hillside","target":"finn"}
		},
		{
			"requires":{"wood_delivered":true},
			"forbids":{"met_mrs_smith":true},
			"task":{"name":"Get the engine parts from Mrs Smith","location":"farm","target":"mrs_smith"}
		},
		{
			"requires":{"met_mrs_smith":true},
			"forbids":{"parts_game":"won"},
			"task":{"name":"Find the engine parts in the maze","location":"farm","target":"maze"}
		},
		{
			"requires":{"parts_game":"won"},
			"forbids":{"parts_delivered":true},
			"task":{"name":"Take the parts to Finn","location":"hillside","target":"finn"}
		},
		{
			"requires":{"parts_delivered":true},
			"forbids":{"met_bob":true},
			"task":{"name":"Get fuel from Mr Bob","location":"town_one","target":"bob"}
		},
		{
			"requires":{"met_bob":true},
			"forbids":{"rps_game":"won"},
			"task":{"name":"Beat Mr Bob at rock paper scissors","location":"town_one","target":"bob"}
		},
		{
			"requires":{"rps_game":"won"},
			"forbids":{"game_complete":true},
			"task":{"name":"Check on the engine","location":"hillside","target":"ken"}
		}
	]
}

func conditions_met(entry: Dictionary):
	var requires: Dictionary = entry.get("requires", {})
	for flag in requires:
		if flags.get(flag) != requires[flag]:
			return false
	var forbids: Dictionary = entry.get("forbids", {})
	for flag in forbids:
		if flags.has(flag) and flags[flag] == forbids[flag]:
			return false
	return true


func should_run(on_finish: Dictionary) -> bool:
	var main: String = on_finish.get("flag", "")
	if main == "" and not on_finish.get("set", {}).is_empty():
		main = on_finish["set"].keys()[0]
	if main == "":
		return true
	var done_value = on_finish.get("not_equal", on_finish.get("set", {}).get(main, true))
	return flags.get(main) != done_value


func execute(on_finish: Dictionary) -> void:
	if not should_run(on_finish):
		return
	var task_before: String = get_current_tasks().get("name", "")
	var received: Array = []
	for section in on_finish:
		match section:
			"set":
				for flag in on_finish["set"]:
					var value = on_finish["set"][flag]
					var changed: bool = flags.get(flag) != value
					flags[flag] = value
					if changed:
						flag_changed.emit(flag, value)
			"move":
				for move in on_finish["move"]:
					move_npc(move.npc, move.location, move.position)
			"give":
				received.append_array(on_finish["give"])
			"take":
				for item_name in on_finish["take"]:
					remove_item(item_name)
			"minigame":
				var game: Dictionary = on_finish["minigame"]
				MinigameManager.play.call_deferred(game.scene, game.result_flag,
					game.get("on_won", {}), game.get("on_lost", {}))
			"credits":
				get_tree().change_scene_to_file.call_deferred("res://scenes/Credits.tscn")
			"flag", "not_equal", "next":
				pass
			_:
				push_warning("Unknown on_finish section: " + str(section))
	var task_moved: bool = get_current_tasks().get("name", "") != task_before
	if not received.is_empty():
		receive_items(received, task_moved)
	elif task_moved:
		announce_task()


func receive_items(new_items: Array, announce_after: bool) -> void:
	for item in new_items:
		add_item(item.name, item.image)
		display_task("Collected " + item.name, item_show_time)
		await ItemPopup.show_item(load(item.image), item_show_time)
	if not gameState.inventory_open:
		Inventory.toggle()
	if announce_after:
		announce_task()


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

func announce_task() -> void:
	task_changed.emit()
	var task := get_current_tasks()
	if not task.is_empty():
		display_task(task.name)


func display_task(text: String, show_time := task_show_time) -> void:
	var panel: Control = TaskOverlay.get_node("Panel")
	var label: Label = panel.get_node("Label")
	label.text = text
	if task_tween:
		task_tween.kill()
	panel.visible = true
	panel.modulate.a = 0.0
	task_tween = create_tween()
	task_tween.tween_property(panel, "modulate:a", 1.0, task_fade_in)
	task_tween.tween_interval(show_time)
	task_tween.tween_property(panel, "modulate:a", 0.0, task_fade_out)
	task_tween.tween_callback(clear_task_display)


func clear_task_display() -> void:
	var panel: Control = TaskOverlay.get_node("Panel")
	panel.get_node("Label").text = ""
	panel.visible = false


func get_current_tasks()->Dictionary:
	var mainTasks = Tasks.main
	for task in mainTasks:
		if conditions_met(task):
			return task.task
	return {}


func get_dialogue_set(npc: String)->Dictionary:
	if not dialogues.has(npc):
		return {}
	var dialogue_sets = dialogues[npc].dialogues
	for dialogue_set in dialogue_sets:
		if conditions_met(dialogue_set):
			return dialogue_set
	return {}

func get_dialogue(npc: String)->Array:
	return get_dialogue_set(npc).get("lines", [])
