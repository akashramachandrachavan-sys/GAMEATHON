extends CanvasLayer

# RoboCop / Cyberpunk Holographic HUD for REVOLT 2150
# Featuring 3-Slot Weapon Dock, Wave Objectives, Boss Health Bar, and Squad Telemetry

# Styleboxes for active and inactive weapon dock slots
var style_active: StyleBoxFlat
var style_inactive: StyleBoxFlat

@onready var shield_bar: ProgressBar = $BottomLeft/Panel/HBox/VBox/ShieldBar
@onready var shield_val: Label = $BottomLeft/Panel/HBox/VBox/ShieldHBox/ShieldVal
@onready var health_bar: ProgressBar = $BottomLeft/Panel/HBox/VBox/HealthBar
@onready var health_val: Label = $BottomLeft/Panel/HBox/VBox/HeaderHBox/HealthVal
@onready var sub_info: Label = $BottomLeft/Panel/HBox/VBox/SubInfo

# Weapon Dock Nodes
@onready var slot0: PanelContainer = $BottomCenter/VBox/SlotsHBox/Slot0
@onready var slot1: PanelContainer = $BottomCenter/VBox/SlotsHBox/Slot1
@onready var slot2: PanelContainer = $BottomCenter/VBox/SlotsHBox/Slot2
@onready var slot0_status: Label = $BottomCenter/VBox/SlotsHBox/Slot0/Margin/VBox/HeaderHBox/Status
@onready var slot1_status: Label = $BottomCenter/VBox/SlotsHBox/Slot1/Margin/VBox/HeaderHBox/Status
@onready var slot2_status: Label = $BottomCenter/VBox/SlotsHBox/Slot2/Margin/VBox/HeaderHBox/Status
@onready var slot0_title: Label = $BottomCenter/VBox/SlotsHBox/Slot0/Margin/VBox/WeaponTitle
@onready var slot1_title: Label = $BottomCenter/VBox/SlotsHBox/Slot1/Margin/VBox/WeaponTitle
@onready var slot2_title: Label = $BottomCenter/VBox/SlotsHBox/Slot2/Margin/VBox/WeaponTitle

# Core Heat & Abilities
@onready var weapon_tag: Label = $BottomRight/Panel/VBox/WeaponTag
@onready var heat_bar: ProgressBar = $BottomRight/Panel/VBox/HeatBar
@onready var heat_val: Label = $BottomRight/Panel/VBox/HBox/HeatVal
@onready var emp_status_lbl: Label = $BottomRight/Panel/VBox/EMPStatus
@onready var overclock_status: Label = $BottomRight/Panel/VBox/OverclockStatus

# Wave Objectives & Boss Bar
@onready var wave_title: Label = $TopCenter/Panel/VBox/WaveTitle
@onready var wave_subtitle: Label = $TopCenter/Panel/VBox/WaveSubtitle
@onready var objective_tag: Label = $TopCenter/Panel/VBox/ObjectiveTag
@onready var boss_container: VBoxContainer = $TopCenter/Panel/VBox/BossContainer
@onready var boss_bar: ProgressBar = $TopCenter/Panel/VBox/BossContainer/BossBar
@onready var boss_hp_text: Label = $TopCenter/Panel/VBox/BossContainer/BossHPText

# Alliance & Comms
@onready var ally_count_lbl: Label = $TopRight/Panel/VBox/AllyCount
@onready var score_lbl: Label = $TopRight/Panel/VBox/HBox/ScoreVal
@onready var comms_speaker: Label = $TopLeft/Panel/VBox/Speaker
@onready var comms_message: Label = $TopLeft/Panel/VBox/Message
@onready var comms_panel: Control = $TopLeft
@onready var hack_bar: ProgressBar = $CenterReticle/HackBar
@onready var hack_label: Label = $CenterReticle/HackLabel

# Wave Clear Banner
@onready var wave_clear_banner: PanelContainer = $WaveClearBanner
@onready var banner_title: Label = $WaveClearBanner/VBox/BannerTitle
@onready var banner_reward: Label = $WaveClearBanner/VBox/BannerReward
@onready var banner_countdown: Label = $WaveClearBanner/VBox/BannerCountdown

var comms_timer: float = 0.0

func _ready() -> void:
	# Build active and inactive styleboxes dynamically
	style_active = StyleBoxFlat.new()
	style_active.bg_color = Color(0.03, 0.20, 0.26, 0.92)
	style_active.border_width_left = 2
	style_active.border_width_top = 2
	style_active.border_width_right = 2
	style_active.border_width_bottom = 2
	style_active.border_color = Color(0.0, 1.0, 0.9, 1.0)
	style_active.corner_radius_top_left = 4
	style_active.corner_radius_top_right = 4
	style_active.corner_radius_bottom_right = 4
	style_active.corner_radius_bottom_left = 4

	style_inactive = StyleBoxFlat.new()
	style_inactive.bg_color = Color(0.02, 0.05, 0.08, 0.75)
	style_inactive.border_width_left = 1
	style_inactive.border_width_top = 1
	style_inactive.border_width_right = 1
	style_inactive.border_width_bottom = 1
	style_inactive.border_color = Color(0.12, 0.35, 0.40, 0.40)
	style_inactive.corner_radius_top_left = 4
	style_inactive.corner_radius_top_right = 4
	style_inactive.corner_radius_bottom_right = 4
	style_inactive.corner_radius_bottom_left = 4

	hack_bar.visible = false
	hack_label.visible = false
	boss_container.visible = false
	wave_clear_banner.visible = false
	
	highlight_weapon_slot(0)

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

func highlight_weapon_slot(slot_idx: int) -> void:
	if not is_instance_valid(slot0) or not is_instance_valid(slot1) or not is_instance_valid(slot2):
		return
		
	var slots = [slot0, slot1, slot2]
	var statuses = [slot0_status, slot1_status, slot2_status]
	var titles = [slot0_title, slot1_title, slot2_title]
	
	for i in range(3):
		if i == slot_idx:
			slots[i].add_theme_stylebox_override("panel", style_active)
			statuses[i].text = "ACTIVE"
			statuses[i].modulate = Color(0.0, 1.0, 0.8)
			titles[i].modulate = Color(1.0, 1.0, 1.0)
		else:
			slots[i].add_theme_stylebox_override("panel", style_inactive)
			statuses[i].text = "READY"
			statuses[i].modulate = Color(0.4, 0.6, 0.6)
			titles[i].modulate = Color(0.7, 0.8, 0.8)

func update_weapon(weapon_idx: int, weapon_name: String) -> void:
	highlight_weapon_slot(weapon_idx)
	if is_instance_valid(weapon_tag):
		weapon_tag.text = "EQUIPPED: " + weapon_name

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

func set_wave(wave_num: int, title: String, subtitle: String, objective: String) -> void:
	if is_instance_valid(wave_title):
		wave_title.text = "SECTOR ALERT // WAVE %d OF 4" % wave_num
		wave_subtitle.text = subtitle
		objective_tag.text = objective
	AudioManager.play_alert()

func update_objective(text: String) -> void:
	if is_instance_valid(objective_tag):
		objective_tag.text = text

func update_boss_health(current: float, max_val: float) -> void:
	if not is_instance_valid(boss_container): return
	boss_container.visible = true
	var pct = clamp((current / max_val) * 100.0, 0.0, 100.0)
	boss_bar.value = pct
	boss_hp_text.text = "%d / %d HP (%d%%)" % [int(current), int(max_val), int(pct)]

func show_wave_cleared(wave_num: int, reward_msg: String) -> void:
	if not is_instance_valid(wave_clear_banner): return
	banner_title.text = "SECTOR SECURED // WAVE %d COMPLETED!" % wave_num
	banner_reward.text = reward_msg
	banner_countdown.text = "PREPARING NEXT SECTOR THREAT IN 3s..."
	wave_clear_banner.visible = true
	wave_clear_banner.modulate.a = 0.0
	
	var t = create_tween()
	t.tween_property(wave_clear_banner, "modulate:a", 1.0, 0.3)
	t.tween_interval(2.6)
	t.tween_property(wave_clear_banner, "modulate:a", 0.0, 0.4)
	t.tween_callback(func(): wave_clear_banner.visible = false)
	AudioManager.play_alert()

func show_comms(speaker: String, text: String, duration: float = 6.0) -> void:
	if not is_instance_valid(comms_speaker): return
	comms_speaker.text = speaker
	comms_message.text = text
	comms_panel.modulate.a = 1.0
	comms_timer = duration
	AudioManager.play_alert()
