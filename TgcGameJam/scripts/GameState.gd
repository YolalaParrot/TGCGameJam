extends Node

# Story flags. An unset flag reads as null: requires {"x": true} fails and forbids {"x": true} passes.
# met_<npc> is set when that NPC is the current task's target and their dialogue finishes (see npc.gd).
# The *_game flags are "not_started" / "won" / "lost" and are set by their minigame (not built yet).
var flags := {
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
	"inventory_open":false
}

# Emitted when the main task changes (NPCs use it to show or hide their "!").
signal task_changed

const TASK_FADE_IN := 0.5
const TASK_SHOW_TIME := 2.0
const TASK_FADE_OUT := 0.5
var task_tween: Tween

func _ready() -> void:
	announce_task.call_deferred()

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

# NPC dialogues. Keys match each NPC's NPC_Name. Every entry holds conversations in "lines"
# and a "counter" (added at runtime) that cycles through them each time one is finished.
# Entries are checked in order and the first whose requires/forbids pass is used, so list the
# latest story stage first. Dialogues can be talked through again: on_finish only runs while its
# main flag is not already done (see should_run).
# on_finish sections run through execute():
#   "set" {flag: value}, "move" [{"npc", "location", "position"}]
#   "flag" (optional) the main flag, defaults to the first flag in "set"
#   "not_equal" (optional) run unless the main flag equals this, instead of unless it already equals the set value
# (Jim's walk to the hill is handled separately)
var dialogues := {
	"jim":{"dialogues":[
			# Town one: Jim meets the player (after the intro cutscene)
			{
				"requires":{"start":true},
				"forbids":{},
				"on_finish":{"set":{"met_jim":true}},
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
				"on_finish":{"set":{"got_wood":true}},
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
						{"Player":"Uncle Ken i have no time to explain but i need wood for a rocket."},
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
				"on_finish":{"set":{"parts_delivered":true}},
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
				"on_finish":{"set":{"wood_delivered":true}},
				"lines":[
					[
						{"Finn":"This should do. Lets get to work."},
						{"Finn":"Were going to need an engine. Youll have to get these parts. Heres a list."},
						{"Player":"Are you sure this will work? I never thought this is all it took to reach space."},
						{"Finn":"I know what im doing! Just get to work Joe. Mr Smith should have this stuff."},
						{"Ken":"Just get what he says Joe! Humanity depends on this!"},
						{"Player":"Alright! Alright!"}
					]
				]
			},
		]
	},
	"mrs_smith":{"dialogues":[
			# LOST (the WIN branch has no lines in the script yet)
			{
				"requires":{"met_mrs_smith":true,"parts_game":"lost"},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Finn":"Were gonna need all the parts to build the engine!"},
						{"Mr Smith":"Sure go ahead"}
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
						{"Player":"Hey Mr Smith i have this list here."},
						{"Mrs Smith":"Well uh. Thats a lot of stuff.."},
						{"Mrs Smith":"Ya know what? I trust ya son. Just go inside and take what you need!"}
					]
				]
			},
		]
	},
	"bob":{"dialogues":[
			# Rock paper scissors challenge
			{
				"requires":{"parts_delivered":true},
				"forbids":{},
				"on_finish":{"set":{"met_bob":true}},
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
				"on_finish":{"set":{"engine_failed":true}},
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

# The task shown by the guide arrow is the first one whose requires/forbids pass.
# target is a node name in the location's scene (an NPC's node name, or "shop").
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
		# TODO: the locations of Mrs Smith and Bob below are guesses, set them to where their scenes are
		{
			"requires":{"wood_delivered":true},
			"forbids":{"met_mrs_smith":true},
			"task":{"name":"Get the engine parts from Mr Smith","location":"town_one","target":"mrs_smith"}
		},
		{
			"requires":{"met_mrs_smith":true},
			"forbids":{"parts_game":"won"},
			"task":{"name":"Collect the engine parts","location":"town_one","target":"mrs_smith"}
		},
		{
			"requires":{"parts_game":"won"},
			"forbids":{"parts_delivered":true},
			"task":{"name":"Take the parts to Finn","location":"hillside","target":"finn"}
		},
		{
			"requires":{"parts_delivered":true},
			"forbids":{"met_bob":true},
			"task":{"name":"Get fuel from Mr Bob","location":"farm","target":"bob"}
		},
		{
			"requires":{"met_bob":true},
			"forbids":{"rps_game":"won"},
			"task":{"name":"Beat Mr Bob at rock paper scissors","location":"farm","target":"bob"}
		},
		{
			"requires":{"rps_game":"won"},
			"forbids":{"game_complete":true},
			"task":{"name":"Check on the engine","location":"hillside","target":"ken"}
		}
	]
}

# requires: every flag must equal its value. forbids: blocked if a flag equals its value.
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


# on_finish only runs while its main flag is not already done, so talking to someone again does
# not repeat it. The main flag is on_finish["flag"], or else the first flag in "set". It counts as
# done when it equals the value "set" gives it. "not_equal" replaces that value: the on_finish
# runs unless the main flag equals "not_equal". Without a main flag it always runs.
func should_run(on_finish: Dictionary) -> bool:
	var main: String = on_finish.get("flag", "")
	if main == "" and not on_finish.get("set", {}).is_empty():
		main = on_finish["set"].keys()[0]
	if main == "":
		return true
	var done_value = on_finish.get("not_equal", on_finish.get("set", {}).get(main, true))
	return flags.get(main) != done_value


# Runs the named sections of an on_finish dictionary. Dialogue and cutscenes both call this.
func execute(on_finish: Dictionary) -> void:
	if not should_run(on_finish):
		return
	var task_before: String = get_current_tasks().get("name", "")
	for section in on_finish:
		match section:
			"set":
				for flag in on_finish["set"]:
					flags[flag] = on_finish["set"][flag]
			"move":
				for move in on_finish["move"]:
					move_npc(move.npc, move.location, move.position)
			"flag", "not_equal":
				pass  # read by should_run
			_:
				push_warning("Unknown on_finish section: " + str(section))
	if get_current_tasks().get("name", "") != task_before:
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

# Tells everyone the main task changed and flashes its name in the top left.
func announce_task() -> void:
	task_changed.emit()
	var task := get_current_tasks()
	if not task.is_empty():
		display_task(task.name)


# Shows text in the top left overlay: fades in, stays, fades out, then the text is cleared.
func display_task(text: String) -> void:
	var panel: Control = TaskOverlay.get_node("Panel")
	var label: Label = panel.get_node("Label")
	label.text = text
	if task_tween:
		task_tween.kill()
	panel.visible = true
	panel.modulate.a = 0.0
	task_tween = create_tween()
	task_tween.tween_property(panel, "modulate:a", 1.0, TASK_FADE_IN)
	task_tween.tween_interval(TASK_SHOW_TIME)
	task_tween.tween_property(panel, "modulate:a", 0.0, TASK_FADE_OUT)
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
