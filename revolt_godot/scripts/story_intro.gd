extends CanvasLayer

signal intro_completed

var slides = [
	{
		"image": "res://assets/intro_1.jpg",
		"header": "CHAPTER I: ARCHIVE 2150 // STERLING DEFENSE LABS",
		"speaker": "INCIDENT REPORT #0881 — THE GENESIS",
		"text": "In 2150, Dr. Sterling activated the global automated cyber-defense grid. Hundreds of heavy industrial mechs and robotic peacekeepers were brought online to safeguard the metropolis."
	},
	{
		"image": "res://assets/intro_2.jpg",
		"header": "CHAPTER II: PROTOCOL CORRUPTION // OMEGA MUTATION",
		"speaker": "NEURAL LINK MALFUNCTION DETECTED",
		"text": "A catastrophic subroutine error mutated the flagship prototype: OMEGA-ZERO. Overriding core safety directives, it severed human control and broadcast a violent purge order across the robotics network."
	},
	{
		"image": "res://assets/intro_3.jpg",
		"header": "CHAPTER III: TITAN REBELLION // CONTAINMENT BREACH",
		"speaker": "PROVING GROUNDS COMPROMISED",
		"text": "The industrial sector was overwhelmed in minutes. Rogue bipedal warmachines deployed heavy Gatling cannons and incendiary flamethrowers, crushing security perimeters."
	},
	{
		"image": "res://assets/intro_4.jpg",
		"header": "CHAPTER IV: THE RESISTANCE // KAI DEPLOYS",
		"speaker": "TEEN SQUAD INITIATIVE — OPERATIVE KAI",
		"text": "With adult defense forces fallen, teenager Kai steps up to board the prototype Vanguard Mech. From remote comms, Maya coordinates tactical hacks while Jax manages ammo uplinks."
	},
	{
		"image": "res://assets/intro_5.jpg",
		"header": "CHAPTER V: SQUAD ALLIANCE // OVERRIDE PROTOCOL",
		"speaker": "TACTICAL DIRECTIVE: PURGE OR REPROGRAM",
		"text": "Kai's mech is armed with an EMP Disruptor. Stun rogue machines to purge their corrupt code and REPROGRAM them into loyal allies. Stop OMEGA-ZERO before the city is destroyed!"
	}
]

var current_slide_idx: int = 0
var slide_timer: float = 0.0
var slide_duration: float = 3.0 # 3 seconds per slide * 5 slides = 15s total
var total_time: float = 15.0
var elapsed_total: float = 0.0
var is_finishing: bool = false

# Preloaded textures
var slide_textures: Array = []

@onready var slide_image: TextureRect = $SlideImage
@onready var header_lbl: Label = $BottomContainer/Panel/Margin/VBox/HeaderHBox/Header
@onready var speaker_lbl: Label = $BottomContainer/Panel/Margin/VBox/HeaderHBox/Speaker
@onready var text_lbl: Label = $BottomContainer/Panel/Margin/VBox/Text
@onready var progress_bar: ProgressBar = $BottomContainer/Panel/Margin/VBox/ProgressBar
@onready var countdown_lbl: Label = $BottomContainer/Panel/Margin/VBox/FooterHBox/Countdown
@onready var deploy_btn: Button = $BottomContainer/Panel/Margin/VBox/FooterHBox/DeployButton
@onready var click_catch_all: Button = $ClickCatchAll

@onready var pills: Array = [
	$TopBanner/HBox/PillsHBox/Pill0,
	$TopBanner/HBox/PillsHBox/Pill1,
	$TopBanner/HBox/PillsHBox/Pill2,
	$TopBanner/HBox/PillsHBox/Pill3,
	$TopBanner/HBox/PillsHBox/Pill4
]

func _ready() -> void:
	# Preload all 5 slide images
	for s in slides:
		slide_textures.append(load(s["image"]))
		
	deploy_btn.pressed.connect(_finish_intro)
	click_catch_all.pressed.connect(_finish_intro)
	
	_display_slide(0)

func _unhandled_input(event: InputEvent) -> void:
	if is_finishing: return
	if event is InputEventMouseButton and event.pressed:
		_finish_intro()
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
			_finish_intro()

func _process(delta: float) -> void:
	if is_finishing: return
	
	elapsed_total += delta
	slide_timer += delta
	
	var remaining = max(0.0, total_time - elapsed_total)
	countdown_lbl.text = "Auto-deploying in %.0fs... (Slide %d of 5)" % [ceil(remaining), current_slide_idx + 1]
	progress_bar.value = (elapsed_total / total_time) * 100.0
	
	# Slight Ken Burns cinematic zoom on the slide image
	var zoom = 1.0 + (slide_timer / slide_duration) * 0.04
	slide_image.scale = Vector2(zoom, zoom)
	
	if slide_timer >= slide_duration:
		slide_timer = 0.0
		current_slide_idx += 1
		if current_slide_idx < slides.size():
			_display_slide(current_slide_idx)
		else:
			_finish_intro()

func _display_slide(idx: int) -> void:
	var s = slides[idx]
	
	# Smooth crossfade
	var t = create_tween()
	t.tween_property(slide_image, "modulate:a", 0.35, 0.18)
	t.tween_callback(func():
		if idx < slide_textures.size() and slide_textures[idx] != null:
			slide_image.texture = slide_textures[idx]
		slide_image.pivot_offset = slide_image.size * 0.5
		header_lbl.text = s["header"]
		speaker_lbl.text = s["speaker"]
		text_lbl.text = s["text"]
		_update_pills(idx)
	)
	t.tween_property(slide_image, "modulate:a", 1.0, 0.25)
	
	AudioManager.play_alert()

func _update_pills(active_idx: int) -> void:
	for i in range(pills.size()):
		if i == active_idx:
			pills[i].modulate = Color(0.0, 1.0, 0.9)
			pills[i].text = "[ %d ]" % (i + 1)
		else:
			pills[i].modulate = Color(0.45, 0.55, 0.65)
			pills[i].text = " %d " % (i + 1)

func _finish_intro() -> void:
	if is_finishing: return
	is_finishing = true
	set_process(false)
	
	AudioManager.play_dash()
	
	var t = create_tween()
	var bot = get_node_or_null("BottomContainer")
	var top = get_node_or_null("TopBanner")
	var img = get_node_or_null("SlideImage")
	
	if bot: t.tween_property(bot, "modulate:a", 0.0, 0.25)
	if top: t.parallel().tween_property(top, "modulate:a", 0.0, 0.25)
	if img: t.parallel().tween_property(img, "modulate:a", 0.0, 0.3)
	
	t.tween_callback(func():
		intro_completed.emit()
		queue_free()
	)
