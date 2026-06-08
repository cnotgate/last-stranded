extends Node

signal dialogue_started
signal dialogue_advanced(speaker_name: String, text: String, color: Color)
signal dialogue_finished
signal objective_updated(text: String)

var is_dialogue_playing: bool = false
var current_dialogue_queue: Array = []

var current_act: int = 0
var current_objective: String = ""
var current_objective_node: Node2D = null

# Story Dialogue Database
var dialogues = {
	"tutorial_movement": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Easy there. Use [W][A][S][D] to move."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Out here, momentum is usually more dangerous than equipment failure."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "First things first. We need to extend the network."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Stand near the station relay and press [E] to connect your umbilical cable, then drag it to the offline relay ahead."}
	],
	"tutorial_flashlight": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "It can get pretty dark in the shadow of the station."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Your suit is equipped with a shoulder light. Press [T] to toggle it."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "It drains your battery, so use it only when necessary."}
	],
	"tutorial_oxygen": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Your suit carries emergency oxygen. A couple of minutes at most."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "As long as you stay connected to the network, oxygen keeps flowing."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Don't wander too far without a tether. Press [X] twice if you ever need to manually disconnect."}
	],
	"tutorial_umbilical": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Good. You've reached the offline relay."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Press [E] to connect your tether to it. That will power it up and extend your safe zone."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Keep an eye on your HUD. Connecting relays consumes Tether Material based on the distance!"}
	],
	"tutorial_disconnect": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Your umbilical can only stretch up to 50 meters, or until you run out of Tether Material."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "To explore further, you must disconnect. Press [X] to manually release your tether and proceed."}
	],
	"tutorial_inventory": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "If your inventory gets full, you can drop the selected item back into space by pressing [Q]."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Also, you can consume raw materials directly! Select a Battery Mat in your hotbar and press [E] to recharge your suit's battery."}
	],
	"tutorial_sprint": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "See that golden capsule? That's a high-density Sprint Battery."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Pick it up to temporarily overcharge your suit, giving you a massive speed boost for 60 seconds."}
	],
	"tutorial_scanning": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "A good engineer doesn't wait until they're desperate to start looking for supplies."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Press [F] to activate your scanner. The bright yellow arrow on your compass will guide you to your next objective."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Your minimap radar will also reveal any raw materials scattered within a 4-kilometer radius."}
	],
	"tutorial_crafting": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "The farther you go, the more infrastructure you'll need."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Pick up those Hybrid Mats on the floor by standing near them and pressing [E]."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Once you have 5 mats, press [C] to open the Fabricator menu and craft an Oxygen Relay."}
	],
	"tutorial_deployment": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Perfect. Now let's deploy it."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Select the Oxygen Relay in your hotbar using keys [1] to [6] or the scroll wheel."},
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Press [E] to initiate placement, then press [E] once more to confirm and build it!"}
	],
	"tutorial_disaster_alert": [
		{"speaker": "ADLER", "color": Color(1.0, 0.2, 0.2), "text": "Faith! I'm reading a massive energy spike from Horizon!"},
		{"speaker": "ADLER", "color": Color(1.0, 0.2, 0.2), "text": "Debris incoming! Get back inside NOW!"}
	],
	"reminder_disconnect": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "You can't bring that tether through here. Press [X] to disconnect."}
	],
	"reminder_umbilical": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Faith, press [E] near the relay to connect your umbilical cord before proceeding."}
	],
	"reminder_scanning": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "Press [F] to use your scanner. Follow the yellow arrow to find what we need."}
	],
	"reminder_crafting": [
		{"speaker": "ADLER", "color": Color(1.0, 0.8, 0.2), "text": "You won't survive out there without a relay. Press [C] to open the Fabricator and craft one."}
	],
	"act1_adler_log": [
		{"speaker": "ADLER", "color": Color(0.7, 0.7, 0.7), "text": "Faith... If you're hearing this, I haven't returned."},
		{"speaker": "ADLER", "color": Color(0.7, 0.7, 0.7), "text": "The relay network is down. I'm going to investigate what happened."},
		{"speaker": "ADLER", "color": Color(0.7, 0.7, 0.7), "text": "If you're able, restore the network."},
		{"speaker": "ADLER", "color": Color(0.7, 0.7, 0.7), "text": "And find the truth."}
	],
	"act1_celes_intro": [
		{"speaker": "CELES", "color": Color(0.4, 0.8, 1.0), "text": "This is Celes. Thank goodness. I thought everyone was gone."},
		{"speaker": "CELES", "color": Color(0.4, 0.8, 1.0), "text": "The Martian settlements have lost contact with Earth."},
		{"speaker": "CELES", "color": Color(0.4, 0.8, 1.0), "text": "They need this relay. Please help me restore it."}
	]
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func get_current_objective_node(player_pos: Vector2) -> Node2D:
	var objectives = get_tree().get_nodes_in_group("tutorial_objectives")
	if objectives.is_empty():
		return null
		
	var closest = null
	var min_dist = INF
	for obj in objectives:
		# Only consider objectives to the right of the player (with a small leeway)
		if obj.global_position.x > player_pos.x - 50.0:
			var dist = player_pos.distance_to(obj.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = obj
				
	return closest

func set_objective(text: String):
	current_objective = text
	emit_signal("objective_updated", text)

func trigger_event(event_id: String):
	if dialogues.has(event_id):
		if is_dialogue_playing:
			# Append to queue if already playing
			current_dialogue_queue.append_array(dialogues[event_id])
		else:
			current_dialogue_queue = dialogues[event_id].duplicate(true)
			start_dialogue()
	else:
		print("StoryManager: Event ID not found - ", event_id)

func start_dialogue():
	if current_dialogue_queue.size() > 0:
		is_dialogue_playing = true
		emit_signal("dialogue_started")
		advance_dialogue()

func advance_dialogue():
	if current_dialogue_queue.size() > 0:
		var line = current_dialogue_queue.pop_front()
		var color = line.get("color", Color.WHITE)
		emit_signal("dialogue_advanced", line.speaker, line.text, color)
	else:
		finish_dialogue()

func finish_dialogue():
	is_dialogue_playing = false
	current_dialogue_queue.clear()
	emit_signal("dialogue_finished")

# We can intercept input globally for advancing dialogue if we want,
# but usually it's better to let HUD handle the input to avoid conflicts.
