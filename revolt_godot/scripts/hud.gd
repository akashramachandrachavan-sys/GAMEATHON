extends CanvasLayer

# RoboCop / Cyberpunk Holographic Mech HUD
# Direct homage to user reference images with telemetry, crosshairs, wireframe mech,
# heat gauges, EMP cooldown, comms chatter, and alliance squad counters.

@onready var health_bar: ProgressBar = $BottomLeft/VBox/HealthBar
@onready var health_val: Label = $BottomLeft/VBox/HBox/HealthVal
@onready var heat_bar: ProgressBar = $BottomRight/VBox/HeatBar
@onready var heat_val: Label = $BottomRight/VBox/HBox/HeatVal
@onready var emp_bar: ProgressBar = $BottomRight/VBox/EMPBar
@onready var emp_status_lbl: Label = $BottomRight/VBox/EMPStatus
@onready var wave_title: Label = $TopCenter/Panel/WaveTitle
@onready var wave_subtitle: Label = $TopCenter/Panel/WaveSubtitle
@onready var ally_count_lbl: Label = $TopRight/Panel/AllyCount
@onready var score_lbl: Label = $TopRight/Panel/ScoreVal
@onready var comms_speaker: Label = $TopLeft/Panel/Speaker
@onready var comms_message: Label = $TopLeft/Panel/Message
@onready var comms_panel: Control = $TopLeft
@onready var hack_bar: ProgressBar = $CenterReticle/HackBar
@onready var hack_label: Label = $CenterReticle/HackLabel

var comms_timer: float = 0.0

func _ready() -> void:
	hack_bar.visible = false
	hack_label.visible = false
	show_comms("MAYA // TACTICAL OVERRIDE", "Kai! Rogue robots have broken containment. Use EMP [Q] to stun them and [E] to reprogram!", 7.0)

func _process(delta: float) -> void:
	if comms_timer > 0.0:
		comms_timer -= delta
		if comms_timer <= 0.0:
			comms_panel.modulate.a = lerp(comms_panel.modulate.a, 0.0, 5.0 * delta)
	else:
		comms_panel.modulate.a = lerp(comms_panel.modulate.a, 0.0, 5.0 * delta)

func update_health(current: float, max_val: float) -> void:
	var pct = clamp((current / max_val) * 100.0, 0.0, 100.0)
	health_bar.value = pct
	health_val.text = "%d%%" % int(pct)
	if pct < 30.0:
		health_bar.modulate = Color(1.0, 0.2, 0.2)
	else:
		health_bar.modulate = Color(0.0, 1.0, 0.7)

func update_heat(current: float, max_val: float) -> void:
	var pct = clamp((current / max_val) * 100.0, 0.0, 100.0)
	heat_bar.value = pct
	heat_val.text = "%d%%" % int(pct)
	if pct >= 95.0:
		heat_bar.modulate = Color(1.0, 0.1, 0.1)
		heat_val.text = "OVERHEAT!"
	elif pct > 65.0:
		heat_bar.modulate = Color(1.0, 0.65, 0.0)
	else:
		heat_bar.modulate = Color(0.0, 0.9, 1.0)

func update_emp(current_cooldown: float, max_cooldown: float) -> void:
	if current_cooldown <= 0.0:
		emp_bar.value = 100.0
		emp_bar.modulate = Color(0.0, 1.0, 0.6)
		emp_status_lbl.text = "EMP SHOCK: READY [Q / RMB]"
		emp_status_lbl.modulate = Color(0.0, 1.0, 0.6)
	else:
		var pct = (1.0 - current_cooldown / max_cooldown) * 100.0
		emp_bar.value = pct
		emp_bar.modulate = Color(0.3, 0.7, 1.0)
		emp_status_lbl.text = "EMP RECHARGING: %.1fs" % current_cooldown
		emp_status_lbl.modulate = Color(0.5, 0.8, 1.0)

func update_reprogram_progress(prog: float) -> void:
	if prog > 0.0:
		hack_bar.visible = true
		hack_label.visible = true
		hack_bar.value = prog * 100.0
	else:
		hack_bar.visible = false
		hack_label.visible = false

func update_allies(count: int, max_allies: int) -> void:
	ally_count_lbl.text = "%d / %d ACTIVE" % [count, max_allies]

func update_score(score: int) -> void:
	score_lbl.text = "%05d" % score

func set_wave(wave_num: int, title: String, subtitle: String) -> void:
	wave_title.text = "SECTOR ALERT // WAVE %d" % wave_num
	wave_subtitle.text = subtitle
	AudioManager.play_alert()

func show_comms(speaker: String, text: String, duration: float = 6.0) -> void:
	comms_speaker.text = speaker
	comms_message.text = text
	comms_panel.modulate.a = 1.0
	comms_timer = duration
	AudioManager.play_alert()
