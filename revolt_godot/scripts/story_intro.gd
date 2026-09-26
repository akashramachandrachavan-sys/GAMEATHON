extends CanvasLayer

signal intro_completed

var slides = [
	{
		"header": "ARCHIVE 2150 // STERLING DEFENSE LABS",
		"speaker": "INCIDENT REPORT #0881",
		"text": "In the 22nd Century, DR. STERLING activates the global automated defense network. Hundreds of advanced industrial and combat droids are brought online to safeguard the city."
	},
	{
		"header": "SYSTEM ALERT // THE MALFUNCTION",
		"speaker": "OMEGA PROTOCOL CORRUPTED",
		"text": "A catastrophic subroutine failure mutates the flagship prototype: OMEGA-ZERO. Overriding core safety directives, it turns rogue and broadcasts a violent purge signal across the entire robotics fleet."
	},
	{
		"header": "THE RESISTANCE // TEEN SQUAD INITIATIVE",
		"speaker": "KAI // MAYA // JAX",
		"text": "With adult defense forces overwhelmed, teenager KAI boards a prototype Vanguard Mech. From remote comms, MAYA provides tactical hacks while JAX coordinates ammo uplinks."
	},
	{
		"header": "MISSION DIRECTIVE // ALLIANCE PROTOCOL",
		"speaker": "KAI'S COMBAT DIRECTIVE",
		"text": "Kai's weapon is equipped with an EMP Shockwave. Stun malfunctioning robots to purge their corrupt code and REPROGRAM them into loyal allies. Stop OMEGA-ZERO before the city falls!"
	}
]

var current_slide_idx: int = 0
var slide_timer: float = 0.0
var slide_duration: float = 3.5
var total_time: float = 14.0
var elapsed_total: float = 0.0

@onready var header_lbl: Label = $Panel/VBox/Header
@onready var speaker_lbl: Label = $Panel/VBox/Speaker
@onready var text_lbl: Label = $Panel/VBox/Text
@onready var progress_bar: ProgressBar = $Panel/VBox/ProgressBar
@onready var countdown_lbl: Label = $Panel/VBox/HBox/Countdown
@onready var deploy_btn: Button = $Panel/VBox/HBox/DeployButton

func _ready() -> void:
	deploy_btn.pressed.connect(_finish_intro)
	_display_slide(0)

func _process(delta: float) -> void:
	elapsed_total += delta
	slide_timer += delta
	
	var remaining = max(0.0, total_time - elapsed_total)
	countdown_lbl.text = "Entering Arena in %.0fs..." % ceil(remaining)
	progress_bar.value = (elapsed_total / total_time) * 100.0
	
	if Input.is_action_just_pressed("dash"): # Space key
		_finish_intro()
		return
		
	if slide_timer >= slide_duration:
		slide_timer = 0.0
		current_slide_idx += 1
		if current_slide_idx < slides.size():
			_display_slide(current_slide_idx)
		else:
			_finish_intro()

func _display_slide(idx: int) -> void:
	var s = slides[idx]
	header_lbl.text = s["header"]
	speaker_lbl.text = s["speaker"]
	text_lbl.text = s["text"]
	AudioManager.play_alert()

func _finish_intro() -> void:
	set_process(false)
	var bg = get_node_or_null("Background")
	var panel = get_node_or_null("Panel")
	var t = create_tween()
	if bg: t.tween_property(bg, "modulate:a", 0.0, 0.3)
	if panel: t.parallel().tween_property(panel, "modulate:a", 0.0, 0.3)
	t.tween_callback(func():
		intro_completed.emit()
		queue_free()
	)
