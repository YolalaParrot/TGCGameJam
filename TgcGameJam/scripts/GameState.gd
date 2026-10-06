extends Node


@export var flags := {
	"start":true,
	"met_jim":false,
	"met_ken":false,
	"met_willy":false,
	"dance_battle":"not_started",
	"got_wood":false,
	"wood_delivered":false,
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

var trial_stage := "bob"
const trial_stages := {
	"got_wood": {
		"flags": {"met_jim":true, "seen_town1_intro":true, "met_ken":true, "met_willy":true,
			"dance_battle":"won", "got_wood":true},
		"items": [wood],
	},
	"light_minigame": {
		"flags": {"met_jim":true, "seen_town1_intro":true, "met_ken":true, "met_willy":true,
			"dance_battle":"won", "got_wood":true,"wood_delivered":true},
	},
	"bob": {
		"flags": {"met_jim":true, "seen_town1_intro":true, "met_ken":true, "met_willy":true,
			"dance_battle":"won", "got_wood":true, "wood_delivered":true,
			"parts_game":"won", "parts_delivered":true},
	},
	"final": {
		"flags": {"met_jim":true, "seen_town1_intro":true, "met_ken":true, "met_willy":true,
			"dance_battle":"won", "got_wood":true, "wood_delivered":true,
			"parts_game":"won", "parts_delivered":true,"met_bob":true,"rps_game":"won"},"items": [fuel]
	},
}

const high_score_file := "user://high_scores.cfg"
var high_scores := {}

func load_high_scores() -> void:
	var config := ConfigFile.new()
	if config.load(high_score_file) == OK:
		for game in config.get_section_keys("high_scores"):
			high_scores[game] = config.get_value("high_scores", game, 0)


func get_high_score(game: String) -> int:
	return high_scores.get(game, 0)


func submit_score(game: String, score: int) -> bool:
	if score <= get_high_score(game):
		return false
	high_scores[game] = score
	var config := ConfigFile.new()
	for key in high_scores:
		config.set_value("high_scores", key, high_scores[key])
	config.save(high_score_file)
	return true


func _ready() -> void:
	load_high_scores()
	if trial_stage != "":
		start_trial(trial_stage)
	apply_world_rules.call_deferred()
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

const wood := {"name":"Wood","image":"res://assets-temp/wood.png"}
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
	"jim": {"loc": "town_one", "pos": null},
	"willy": {"loc": "town_two", "pos": null},
}

const achievements := {
	"buffet_into_space": {"name": "Buffet Into Space", "description": "Convince Uncle Willy to come along to space"},
}

# Checked after every change to the game state: each runs once, as soon as its requires/forbids pass.
const world_rules := [
	# Jim runs off to the hill after meeting the player
	{
		"requires": {"met_jim": true},
		"forbids": {"jim_on_hill": true},
		"on_finish": {"set": {"jim_on_hill": true}, "move": [{"npc": "jim", "location": "hillside"}]},
	},
	# Uncle Willy joins the boys once he is convinced and Bob's fuel is in (whichever happens last)
	{
		"requires": {"willy_convinced": true, "rps_game": "won"},
		"forbids": {"willy_on_hill": true},
		"on_finish": {"set": {"willy_on_hill": true}, "move": [{"npc": "willy", "location": "hillside"}]},
	},
]

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
			# Hill: the fuel is in
			{
				"requires":{"rps_game":"won"},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Jim":"Engines done? Oh boy. Kens gonna be unbearable."}
					]
				]
			},
			# Hill: 6 hours left
			{
				"requires":{"parts_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Jim":"Six hours... Joe, are we really doing this?"},
						{"Player":"We are. Together."}
					]
				]
			},
			# Hill: 11 hours left
			{
				"requires":{"wood_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Jim":"Finns got that look again. The I-read-it-in-a-book look."}
					]
				]
			},
			# Hill: 16 hours left
			{
				"requires":{"met_ken":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Jim":"Told ya the boys had a plan. ...Kinda."}
					]
				]
			},
			# Hill: waiting for the player (after he ran off from town one)
			{
				"requires":{"met_jim":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Jim":"Kens waiting for you. Whatever he says, dont kneel."}
					]
				]
			},
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
			# On the hill with the boys (after the buffet, waiting for the rocket)
			{
				"requires":{"willy_on_hill":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Willy":"Brought what was left of the buffet. Cant fly to space on an empty stomach!"},
						{"Willy":"Martha wouldve loved this view, kid."}
					],
					[
						{"Willy":"Window seat. You promised."}
					]
				]
			},
			# Convinced: waiting for the rocket
			{
				"requires":{"willy_convinced":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Willy":"Buffets still going, kid! Grab a plate before Bob eats it all."}
					],
					[
						{"Willy":"Dont you dare leave without me, Joe."}
					]
				]
			},
			# Side quest: Buffet Into Space (any time after the wood reaches Finn)
			{
				"requires":{"wood_delivered":true},
				"forbids":{"willy_convinced":true},
				"on_finish":{"set":{"willy_convinced":true},"achievement":"buffet_into_space"},
				"lines":[
					[
						{"Willy":"You again? I told ya, the woods all yours. What now?"},
						{"Player":"Nothing. Just... wanted to check on you, Uncle Willy."},
						{"Willy":"Check on me? Hah! Im fine. Im always fine."},
						{"Willy":"..."},
						{"Willy":"Martha used to say that. Always fine, Willy. Right up till she wasnt."},
						{"Willy":"Tried calling my daughter today. Every line in the country is busy."},
						{"Willy":"Six years we didnt talk, kid. Over a fence. A stupid fence."},
						{"Willy":"And my boy... built this shop for him. He moved to the city. Never came back."},
						{"Player":"Uncle Willy..."},
						{"Willy":"*sniff* Bah! Look at me, getting all misty over nothing."},
						{"Willy":"*wipes his eyes* You know what? If the worlds ending, its ending on a full stomach!"},
						{"Willy":"Im throwing a buffet! The whole town is invited. Even that grump Bob."},
						{"Player":"Willy... no matter what happens, Im making sure youre on that rocket with us."},
						{"Willy":"Me? On a rocket? Kid, I can barely get up the stairs."},
						{"Player":"Youre coming to space, Uncle Willy. Thats final."},
						{"Willy":"..."},
						{"Willy":"Alright, kid. Save me a window seat. And Im bringing the leftovers."}
					]
				]
			},
			# Wood handed over: a reminder (16 hours left)
			{
				"requires":{"got_wood":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Willy":"Go on, get that wood to your friends before I change my mind!"}
					]
				]
			},
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
					],
					[
						{"Willy":"You call that dancing? My hip moves better, and its made of metal!"}
					]
				]
			},
			# Challenge accepted: a reminder
			{
				"requires":{"met_willy":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Willy":"Well? The dance floor is in the shop, kid. Show me what you got!"}
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
			# Small talk before the story reaches Willy
			{
				"requires":{"start":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Willy":"Ya hear about that space rock, kid? Whole town is running around like headless chickens."},
						{"Player":"Space rock? What space rock?"},
						{"Willy":"Bah! Kids these days never read the news. Go find your friends, they wont shut up about it."}
					],
					[
						{"Willy":"Shop is closed today. Not that it matters much anymore..."}
					]
				]
			},
		]
	},
	"finn":{"dialogues":[
			# Fuel is in: send the player to Ken
			{
				"requires":{"rps_game":"won"},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Finn":"Ken wants to see the engine. Go talk to him. Its... uh... ready. I think."}
					]
				]
			},
			# Parts delivered: a reminder (6 hours left)
			{
				"requires":{"parts_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Finn":"The engine is gonna take time. Go get the fuel from Mr Bob!"}
					]
				]
			},
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
			# Wood delivered: a reminder (11 hours left)
			{
				"requires":{"wood_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Finn":"Did you find the parts in the farm maze yet? I cant build an engine out of wood!"}
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
						{"Finn":"I know what im doing! Just get to work Joe. The old maze on the farm should have this stuff."},
						{"Ken":"Just get what he says Joe! Humanity depends on this!"},
						{"Player":"Alright! Alright!"}
					]
				]
			},
			# Small talk on the hill before the wood
			{
				"requires":{"met_jim":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Finn":"I read everything about rockets in that book from the big city!"},
						{"Finn":"Wood for the body, an engine, and fuel. How hard can it be?"}
					],
					[
						{"Finn":"Ken says he is the king of the hill now... please just go along with it."}
					]
				]
			},
		]
	},
	"gary":{"dialogues":[
			# 30 mins left
			{
				"requires":{"rps_game":"won"},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Gary":"Thirty minutes. I wrote it on the sign. Nobody reads the sign."},
						{"Gary":"If you see my mom... tell her I fed the cat."}
					]
				]
			},
			# 6 hours left
			{
				"requires":{"parts_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Gary":"Six hours! SIX! I can hear it humming up there. Cant you hear it?"},
						{"Player":"...Thats a bee, Gary."}
					],
					[
						{"Gary":"I updated the sign. It now says THE END IS NEARER."}
					]
				]
			},
			# After Willy's buffet invitation
			{
				"requires":{"willy_convinced":true},
				"forbids":{"parts_delivered":true},
				"on_finish":{},
				"lines":[
					[
						{"Gary":"Uncle Willys throwing a buffet! I brought my sign. People keep putting plates on it."}
					],
					[
						{"Gary":"For the first time today... I dont feel scared. Is that weird?"}
					]
				]
			},
			# 11 hours left
			{
				"requires":{"wood_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Gary":"Eleven hours... Ive been counting since sunrise. Counting helps."},
						{"Gary":"One... two... please dont leave me alone out here."}
					],
					[
						{"Gary":"Is it true youre building a rocket? Is there... room for one more?"},
						{"Player":"Ill ask Ken."},
						{"Gary":"Ken scares me more than the comet."}
					]
				]
			},
			# 16 hours left
			{
				"requires":{"met_ken":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Gary":"Sixteen hours. The radio said sixteen hours. So I made a sign."},
						{"Player":"Nice sign."},
						{"Gary":"THANK you. Nobody ever says that."}
					]
				]
			},
			# Before anyone knows
			{
				"requires":{"start":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Gary":"THE END IS NEAR! ...Sorry. Im practicing."}
					],
					[
						{"Gary":"Do you think it hurts? Getting hit by a space rock?"}
					]
				]
			},
		]
	},
	"mabel":{"dialogues":[
			# 30 mins left
			{
				"requires":{"rps_game":"won"},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Mabel":"Thirty minutes. Ive made tea. You always make tea at the end of things, dear."}
					]
				]
			},
			# 6 hours left
			{
				"requires":{"parts_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Mabel":"Six hours. I finally finished the scarf I started in 1972."},
						{"Mabel":"Its very long, dear. Its very, very long."}
					]
				]
			},
			# After Willy's buffet invitation
			{
				"requires":{"willy_convinced":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Mabel":"Willy throwing a party! I havent seen him smile since Martha passed."},
						{"Mabel":"Whatever you said to him, dear... thank you."}
					]
				]
			},
			# 11 hours left
			{
				"requires":{"wood_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Mabel":"Eleven hours, the radio says. I should water the roses anyway. They dont know."}
					]
				]
			},
			# 16 hours left
			{
				"requires":{"met_ken":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Mabel":"Sixteen hours! At my age, dear, thats practically a lifetime."}
					],
					[
						{"Mabel":"That Ken boy came by and called himself king. I gave him a biscuit. He bowed."}
					]
				]
			},
			# Before anyone knows
			{
				"requires":{"start":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Mabel":"Oh, Joe! Everyones running around like headless chickens today."},
						{"Mabel":"In my day, the end of the world came with a proper announcement."}
					]
				]
			},
		]
	},
	"bob":{"dialogues":[
			# WIN: Bob handed over the fuel (30 mins left)
			{
				"requires":{"rps_game":"won"},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Bob":"Beaten by a kid.. Go on, take the fuel and get out of here."}
					],
					[
						{"Bob":"Thirty minutes and you kids are still running around. ...Good luck, kid."}
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
					],
					[
						{"Bob":"I can read you like the morning paper, kid. Again!"}
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
			# After Willy's buffet invitation
			{
				"requires":{"willy_convinced":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Bob":"Willy invited me to his buffet. Says the world's ending, so we're square."},
						{"Bob":"...Best potato salad I ever had. Dont tell him I said that."}
					],
					[
						{"Bob":"Thirty years I fought with that man over a fence line. Feels silly now."}
					]
				]
			},
			# 11 hours left
			{
				"requires":{"wood_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Bob":"Radio says eleven hours. Still not giving anything away for free."}
					],
					[
						{"Bob":"My dog hid under the porch this morning. Smart dog. Smarter than this town."}
					]
				]
			},
			# 16 hours left
			{
				"requires":{"met_ken":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Bob":"Sixteen hours, they say. Plenty of time to mind my own business."}
					],
					[
						{"Bob":"Rocket? You? Hah! You couldnt build a birdhouse, kid."}
					]
				]
			},
			# Small talk before the story reaches Bob
			{
				"requires":{"start":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Bob":"What do you want kid? Cant you see im busy?"},
						{"Player":"Busy doing what?"},
						{"Bob":"Busy minding my own business. You should try it."}
					],
					[
						{"Bob":"If that rock hits us, at least I wont have to deal with you kids anymore."}
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
			# 6 hours left
			{
				"requires":{"parts_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Ken":"Six hours, subject! The royal engine needs its royal fuel. Go!"}
					]
				]
			},
			# 11 hours left
			{
				"requires":{"wood_delivered":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Ken":"Eleven hours! Faster, subject! Your king grows impatient."}
					]
				]
			},
			# After the rocket plan: a reminder (16 hours left)
			{
				"requires":{"met_ken":true},
				"forbids":{},
				"on_finish":{},
				"lines":[
					[
						{"Ken":"What are you waiting for subject? Go get Finn what he needs!"}
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
			"task":{"name":"Talk with Jim (click H for Controls)","location":"town_one","target":"jim"}
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
	],
	# Side quests: shown in the inventory once requires/forbids pass, and marked done by done_flag.
	# The target NPC shows "..." while the quest is open.
	"side":[
		# Uncle Willy opens up once the wood is delivered
		{
			"requires":{"wood_delivered":true},
			"forbids":{},
			"done_flag":"willy_convinced",
			"task":{"name":"Buffet Into Space","hint":"Uncle Willy seems down. Go see how he is","location":"town_two","target":"willy"}
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
	var comet_before := comet_time()
	var received: Array = []
	var achievement := ""
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
					move_npc(move.npc, move.location, move.get("position"))
			"give":
				received.append_array(on_finish["give"])
			"take":
				for item_name in on_finish["take"]:
					remove_item(item_name)
			"minigame":
				var game: Dictionary = on_finish["minigame"]
				MinigameManager.play.call_deferred(game.scene, game.result_flag,
					game.get("on_won", {}), game.get("on_lost", {}))
			"achievement":
				achievement = on_finish["achievement"]
			"credits":
				get_tree().change_scene_to_file.call_deferred("res://scenes/Credits.tscn")
			"flag", "not_equal", "next", "flash":
				pass
			_:
				push_warning("Unknown on_finish section: " + str(section))
	var task_moved: bool = get_current_tasks().get("name", "") != task_before
	if comet_time() != comet_before:
		task_moved = true
	if not received.is_empty():
		receive_items(received, task_moved)
	elif task_moved:
		announce_task()
	if achievement != "":
		show_achievement(achievement)
	apply_world_rules()


func receive_items(new_items: Array, announce_after: bool) -> void:
	for item in new_items:
		add_item(item.name, item.image)
		display_task("Collected " + item.name, item_show_time)
		await ItemPopup.show_item(load(item.image), item_show_time)
	if not gameState.inventory_open:
		Inventory.toggle()
	if announce_after:
		announce_task()


func move_npc(npc_name: String, location: String, position = null) -> void:
	var old_map := npc_map(npc_name)
	npc_state[npc_name] = {"loc": location, "pos": position}
	var scene := get_tree().current_scene
	var npc := scene.find_child(npc_name, true, false) as Node2D if scene else null
	if npc == null:
		return
	if location == old_map:
		if position != null:
			npc.position = position
	elif not npc.get("leaving"):
		npc.queue_free()


func apply_world_rules() -> void:
	for rule in world_rules:
		if conditions_met(rule):
			execute(rule.on_finish)


func show_achievement(id: String) -> void:
	var achievement: Dictionary = achievements[id]
	flags["achievement_" + id] = true
	CutsceneManager.flash(Color(1.0, 0.82, 0.25, 0.3), 0.8)
	display_task("Achievement: %s - %s" % [achievement.name, achievement.description], 3.5)


func side_quest_for(npc_name: String) -> Dictionary:
	for quest in Tasks.side:
		if quest.task.target == npc_name and conditions_met(quest) and not flags.get(quest.done_flag, false):
			return quest.task
	return {}


func side_quest_lines() -> Array:
	var lines := []
	for quest in Tasks.side:
		if flags.get(quest.done_flag, false):
			lines.append("- %s (done)" % quest.task.name)
		elif conditions_met(quest):
			lines.append("- %s: %s" % [quest.task.name, quest.task.hint])
	return lines


func cutscene_seen(cutscene_id: String) -> bool:
	return flags.get("seen_" + cutscene_id, false)


func mark_cutscene_seen(cutscene_id: String) -> void:
	flags["seen_" + cutscene_id] = true

func announce_task() -> void:
	task_changed.emit()
	var task := get_current_tasks()
	if not task.is_empty():
		display_task(task.name, task_show_time, comet_text())


func display_task(text: String, show_time := task_show_time, comet := "") -> void:
	var panel: Control = TaskOverlay.get_node("Panel")
	var label: Label = panel.get_node("Row/Label")
	label.text = text
	var comet_label: Label = panel.get_node("Row/Comet")
	comet_label.text = comet
	comet_label.visible = comet != ""
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
	panel.get_node("Row/Label").text = ""
	panel.get_node("Row/Comet").text = ""
	panel.visible = false


func comet_time() -> String:
	if flags.get("rps_game") == "won":
		return "30 mins"
	if flags.get("parts_delivered", false):
		return "6 hours"
	if flags.get("wood_delivered", false):
		return "11 hours"
	if flags.get("met_ken", false):
		return "16 hours"
	return ""


func comet_text() -> String:
	var time := comet_time()
	return "" if time == "" else "%s till the Comet Impact" % time


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
