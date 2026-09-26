extends CanvasLayer

# RoboCop / Cyberpunk Holographic Mech HUD
# Telemetry, crosshairs, shields, vitality, heat gauge, active weapons, and squad alliance.

@onready var shield_bar: ProgressBar = $BottomLeft/Panel/HBox/VBox/ShieldBar
@onready var shield_val: Label = $BottomLeft/Panel/HBox/VBox/ShieldHBox/ShieldVal
@onready var health_bar: ProgressBar = $BottomLeft/Panel/HBox/VBox/HealthBar
@onready var health_val: Label = $BottomLeft/Panel/HBox/VBox/HeaderHBox/HealthVal
@onready var sub_info: Label = $BottomLeft/Panel/HBox/VBox/SubInfo
@onready var weapon_tag: Label = $BottomRight/Panel/VBox/WeaponTag
@onready var heat_bar: ProgressBar = $BottomRight/Panel/VBox/HeatBar
@onready var heat_val: Label = $BottomRight/Panel/VBox/HBox/HeatVal
@onready var emp_status_lbl: Label = $BottomRight/Panel/VBox/EMPStatus
@onready var overclock_status: Label = $BottomRight/Panel/VBox/OverclockStatus
@onready var wave_title: Label = $TopCenter/Panel/VBox/WaveTitle
@onready var wave_subtitle: Label = $TopCenter/Panel/VBox/WaveSubtitle
@onready var ally_count_lbl: Label = $TopRight/Panel/VBox/AllyCount
@onready var score_lbl: Label = $TopRight/Panel/VBox/HBox/ScoreVal
@onready var comms_speaker: Label = $TopLeft/Panel/VBox/Speaker
@onready var comms_message: Label = $TopLeft/Panel/VBox/Message
@onready var comms_panel: Control = $TopLeft
@onready var hack_bar: ProgressBar = $CenterReticle/HackBar
@onready var hack_label: Label = $CenterReticle/HackLabel

var comms_timer: float = 0.0

func _ready() -> void:
	hack_bar.visible = false
	hack_label.visible = false
	show_comms("MAYA // TACTICAL OVERRIDE", "Kai! A massive Goliath Enforcer is inbound. Switch weapons with [1/2/3], use your Shield, and trigger Overclock with [F]!", 7.5)

func _process(delta: float) -> void:
	if comms_timer > 0.0:
		comms_timer -= delta
		if comms_timer <= 0.0:
			comms_panel.modulate.a = lerp(comms_panel.modulate.a, 0.0, 5.0 * delta)
	else:
		comms_panel.modulate.a = lerp(comms_panel.modulate.a, 0.0, 5.0 * delta)

func update_shield(current: float, max_val: float) -> void:
	if not is_instance_valid(shield_bar): return
	var pct = clamp((current / max_val) * 100.0, 0.0, 100.0)
	shield_bar.value = pct
	shield_val.text = "%d / %d" % [int(current), int(max_val)]
	if pct <= 0.0:
		shield_bar.modulate = Color(1.0, 0.2, 0.2)
	else:
		shield_bar.modulate = Color(0.0, 0.85, 1.0)

func update_health(current: float, max_val: float) -> void:
	if not is_instance_valid(health_bar): return
	var pct = clamp((current / max_val) * 100.0, 0.0, 100.0)
	health_bar.value = pct
	health_val.text = "%d / %d" % [int(current), int(max_val)]
	if pct < 30.0:
		health_bar.modulate = Color(1.0, 0.2, 0.2)
	else:
		health_bar.modulate = Color(0.0, 1.0, 0.55)

func update_stims(count: int) -> void:
	if not is_instance_valid(sub_info): return
	sub_info.text = "SUIT: CYBER-VEST // STIMS [C]: %d READY" % count

func update_weapon(weapon_name: String) -> void:
	if not is_instance_valid(weapon_tag): return
	weapon_tag.text = "WEAPON: " + weapon_name

func update_heat(current: float, max_val: float) -> void:
	if not is_instance_valid(heat_bar): return
	var pct = clamp((current / max_val) * 100.0, 0.0, 100.0)
	heat_bar.value = pct
	heat_val.text = "%d%%" % int(pct)
	if pct >= 95.0:
		heat_bar.modulate = Color(1.0, 0.1, 0.1)
		heat_val.text = "OVERHEAT!"
	elif pct > 65.0:
		heat_bar.modulate = Color(1.0, 0.65, 0.0)
	else:
		heat_bar.modulate = Color(0.0, 1.0, 0.55)

func update_emp(current_cooldown: float, _max_cooldown: float) -> void:
	if not is_instance_valid(emp_status_lbl): return
	if current_cooldown <= 0.0:
		emp_status_lbl.text = "EMP DISRUPTOR: READY [Q / RMB]"
		emp_status_lbl.modulate = Color(0.0, 1.0, 0.6)
	else:
		emp_status_lbl.text = "EMP RECHARGING: %.1fs" % current_cooldown
		emp_status_lbl.modulate = Color(0.5, 0.8, 1.0)

func update_overclock(is_ready: bool, remaining_cd: float) -> void:
	if not is_instance_valid(overclock_status): return
	if is_ready:
		overclock_status.text = "OVERCLOCK [F]: READY (BULLET TIME)"
		overclock_status.modulate = Color(0.2, 0.9, 1.0)
	else:
		overclock_status.text = "OVERCLOCK COOLDOWN: %.1fs" % remaining_cd
		overclock_status.modulate = Color(0.5, 0.6, 0.7)

func update_reprogram_progress(prog: float) -> void:
	if not is_instance_valid(hack_bar): return
	if prog > 0.0:
		hack_bar.visible = true
		hack_label.visible = true
		hack_bar.value = prog * 100.0
	else:
		hack_bar.visible = false
		hack_label.visible = false

func update_allies(count: int, max_allies: int) -> void:
	if is_instance_valid(ally_count_lbl):
		ally_count_lbl.text = "%d / %d ACTIVE" % [count, max_allies]

func update_score(score: int) -> void:
	if is_instance_valid(score_lbl):
		score_lbl.text = "%05d" % score

func set_wave(wave_num: int, title: String, subtitle: String) -> void:
	if is_instance_valid(wave_title):
		wave_title.text = "SECTOR ALERT // WAVE %d" % wave_num
		wave_subtitle.text = subtitle
	AudioManager.play_alert()

func show_comms(speaker: String, text: String, duration: float = 6.0) -> void:
	if not is_instance_valid(comms_speaker): return
	comms_speaker.text = speaker
	comms_message.text = text
	comms_panel.modulate.a = 1.0
	comms_timer = duration
	AudioManager.play_alert()
