extends CharacterBody3D

# Teen Resistance Hero: KAI (Full Cyberpunk Operative 3D Model & AAA Combat Controller)
# Features: 3 Switchable Weapons (Pulse Rifle, Plasma Shotgun, Ion Railgun), Overclock Bullet-Time,
# Tactical Energy Shield with Auto-Recharge, Nano-Stim Injectors, Double Jump & Jet Slide.

signal health_changed(current_hp, max_hp)
signal shield_changed(current_shield, max_shield)
signal stim_changed(count)
signal weapon_changed(weapon_idx, weapon_name)
signal heat_updated(current_heat, max_heat)
signal emp_cooldown_updated(current, max_time)
signal overclock_updated(is_ready, remaining_cd)
signal alliance_count_updated(current_count, max_count)
signal reprogram_progress_updated(progress)

# Movement Constants
const SPEED = 9.0
const SPRINT_SPEED = 15.0
const JUMP_VELOCITY = 11.5
const AIR_BOOST_VELOCITY = 9.0
const ACCEL = 20.0
const ROT_SPEED = 14.0
const MOUSE_SENSITIVITY = 0.0025

# Health & Tactical Shield System (High Survivability)
var max_health: float = 300.0
var health: float = 300.0
var max_shield: float = 200.0
var shield: float = 200.0
var shield_regen_delay: float = 2.8
var shield_regen_timer: float = 0.0
var shield_regen_rate: float = 60.0
var invuln_timer: float = 0.0
var stim_packs: int = 2
var team: String = "player"

# Weapons Arsenal (Switchable via [1], [2], [3] or Mouse Wheel)
# 0: Vanguard Pulse Rifle, 1: Plasma Shotgun, 2: Ion Railgun
var current_weapon: int = 0
var weapon_names = [
	"[1] VANGUARD PULSE RIFLE",
	"[2] SCATTER PLASMA SHOTGUN",
	"[3] HYPER ION RAILGUN"
]

# Weapon Stats
var fire_timers = [0.0, 0.0, 0.0]
var fire_rates = [0.10, 0.58, 1.05]
var max_heat: float = 100.0
var current_heat: float = 0.0
var is_overheated: bool = false
var is_scoped: bool = false

# Overclock Cyber Drive (Bullet Time)
var overclock_max_cooldown: float = 16.0
var overclock_cooldown: float = 0.0
var is_overclocked: bool = false
var overclock_timer: float = 0.0
var overclock_duration: float = 4.2

# EMP Disruptor
var emp_max_cooldown: float = 6.0
var emp_cooldown: float = 0.0
var emp_radius: float = 22.0

# Tactical Slide & Jet Jump
var dash_cooldown: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var can_air_boost: bool = true

# Procedural Locomotion & Weapon Sway
var run_cycle: float = 0.0
var step_interval: float = 0.28
var step_timer: float = 0.0
var sway_offset: Vector2 = Vector2.ZERO

# Camera
var camera_pitch: float = 2.0
var camera_yaw: float = 0.0
var camera_shake: float = 0.0
var target_fov: float = 74.0

# Node References
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var body_root: Node3D
var torso: Node3D
var head: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_shin: Node3D
var right_shin: Node3D
var left_arm: Node3D
var right_arm: Node3D
var rifle_mount: Node3D
var gun_mesh_rifle: Node3D
var gun_mesh_shotgun: Node3D
var gun_mesh_railgun: Node3D
var muzzle_marker: Marker3D
var muzzle_light: OmniLight3D
var dash_particles: CPUParticles3D
var overclock_particles: CPUParticles3D
var shield_shimmer: MeshInstance3D
var backpack_reactor_mat: StandardMaterial3D

# Reprogram target
var nearby_stunned_enemy: Node3D = null
var reprogram_timer: float = 0.0
var reprogram_duration: float = 1.0

func _ready() -> void:
	_build_detailed_human_kai()
	_setup_camera()
	_setup_collision()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	health_changed.emit(health, max_health)
	shield_changed.emit(shield, max_shield)
	stim_changed.emit(stim_packs)
	emp_cooldown_updated.emit(0.0, emp_max_cooldown)
	overclock_updated.emit(true, 0.0)
	heat_updated.emit(current_heat, max_heat)
	_switch_weapon(0, true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
		camera_pitch -= event.relative.y * MOUSE_SENSITIVITY * 40.0
		camera_pitch = clamp(camera_pitch, -45.0, 55.0)
		
		# Procedural weapon sway
		sway_offset.x = clamp(sway_offset.x - event.relative.x * 0.0015, -0.08, 0.08)
		sway_offset.y = clamp(sway_offset.y + event.relative.y * 0.0015, -0.06, 0.06)
		
	# Mouse Wheel Weapon Switching
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_switch_weapon((current_weapon + 1) % 3)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_switch_weapon((current_weapon + 2) % 3)
			
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Shield Auto-Recharge System
	if invuln_timer > 0.0:
		invuln_timer = max(0.0, invuln_timer - delta)
		if shield_shimmer: shield_shimmer.visible = true
	elif shield_shimmer:
		shield_shimmer.visible = false
		
	if shield_regen_timer > 0.0:
		shield_regen_timer = max(0.0, shield_regen_timer - delta)
	elif shield < max_shield:
		shield = min(max_shield, shield + shield_regen_rate * delta)
		shield_changed.emit(shield, max_shield)
		
	# Overclock Bullet Time Update
	if is_overclocked:
		overclock_timer -= delta / Engine.time_scale
		if overclock_timer <= 0.0:
			_deactivate_overclock()
	elif overclock_cooldown > 0.0:
		overclock_cooldown = max(0.0, overclock_cooldown - delta)
		overclock_updated.emit(overclock_cooldown <= 0.0, overclock_cooldown)

	# EMP & Dash Cooldowns
	if emp_cooldown > 0.0:
		emp_cooldown = max(0.0, emp_cooldown - delta)
		emp_cooldown_updated.emit(emp_cooldown, emp_max_cooldown)
		
	if dash_cooldown > 0.0:
		dash_cooldown = max(0.0, dash_cooldown - delta)
		
	# Weapon Heat Dissipation
	if current_heat > 0.0:
		var cooling_speed = 55.0 if is_overheated else 80.0
		current_heat = max(0.0, current_heat - cooling_speed * delta)
		if is_overheated and current_heat <= 10.0:
			is_overheated = false
		heat_updated.emit(current_heat, max_heat)

	# Backpack reactor visual pulsation
	if backpack_reactor_mat:
		var pulse = (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5
		backpack_reactor_mat.emission_energy_multiplier = 3.0 if emp_cooldown <= 0.0 else (0.8 + pulse * 0.6)

	# 100% Robust Hardware Scan-Code WASD + Arrow Key Polling
	var input_dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("move_forward"):
		input_dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("move_backward"):
		input_dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()
	
	# Weapon Switch Hotkeys [1], [2], [3]
	if Input.is_physical_key_pressed(KEY_1) or Input.is_key_pressed(KEY_1):
		_switch_weapon(0)
	elif Input.is_physical_key_pressed(KEY_2) or Input.is_key_pressed(KEY_2):
		_switch_weapon(1)
	elif Input.is_physical_key_pressed(KEY_3) or Input.is_key_pressed(KEY_3):
		_switch_weapon(2)

	# Nano-Stim Pack Injector [C]
	if (Input.is_physical_key_pressed(KEY_C) or Input.is_key_pressed(KEY_C)) and stim_packs > 0 and health < max_health:
		_use_stim_pack()

	# Overclock Cyber Drive [F] or [X]
	if (Input.is_physical_key_pressed(KEY_F) or Input.is_key_pressed(KEY_F) or Input.is_physical_key_pressed(KEY_X)) and overclock_cooldown <= 0.0 and not is_overclocked:
		_activate_overclock()

	# Jump & Cyber Air Boost [Spacebar]
	if is_on_floor():
		can_air_boost = true
		if Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("dash"):
			velocity.y = JUMP_VELOCITY
			AudioManager.play_dash()
	else:
		velocity.y -= 26.0 * delta
		if can_air_boost and (Input.is_physical_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("dash")):
			can_air_boost = false
			velocity.y = AIR_BOOST_VELOCITY
			if input_dir != Vector2.ZERO:
				var cam_f = Vector3(-sin(camera_yaw), 0, -cos(camera_yaw)).normalized()
				var cam_r = Vector3(cos(camera_yaw), 0, -sin(camera_yaw)).normalized()
				var boost_dir = (cam_f * input_dir.y + cam_r * input_dir.x).normalized()
				velocity.x = boost_dir.x * SPRINT_SPEED
				velocity.z = boost_dir.z * SPRINT_SPEED
			AudioManager.play_dash()
			camera_shake = 0.3
			if dash_particles: dash_particles.restart()

	# Tactical Jet Slide (Shift or Alt or fast dash)
	var shift_pressed = Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_SHIFT)
	var sprint_mod = 1.0
	if is_dashing:
		sprint_mod = 1.6
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			if dash_particles: dash_particles.emitting = false
	elif shift_pressed and is_on_floor() and input_dir != Vector2.ZERO and dash_cooldown <= 0.0:
		is_dashing = true
		dash_timer = 0.38
		dash_cooldown = 1.2
		AudioManager.play_dash()
		camera_shake = 0.35
		if dash_particles: dash_particles.emitting = true

	# Calculate World Movement
	var cam_forward = Vector3(-sin(camera_yaw), 0, -cos(camera_yaw)).normalized()
	var cam_right = Vector3(cos(camera_yaw), 0, -sin(camera_yaw)).normalized()
	var move_vec = (cam_forward * input_dir.y + cam_right * input_dir.x).normalized()
	
	var cur_speed = SPEED * sprint_mod
	if is_overclocked: cur_speed *= 1.4 # Boosted during bullet time
	
	var target_vel = move_vec * cur_speed
	velocity.x = lerp(velocity.x, target_vel.x, ACCEL * delta)
	velocity.z = lerp(velocity.z, target_vel.z, ACCEL * delta)
	move_and_slide()
	
	# Smoothly face aiming crosshair
	rotation.y = lerp_angle(rotation.y, camera_yaw, ROT_SPEED * delta)
	
	# Procedural Locomotion Animations
	if move_vec.length() > 0.1 and is_on_floor():
		run_cycle += delta * (16.0 if not is_dashing else 26.0)
		var leg_angle = sin(run_cycle) * (34.0 if not is_dashing else 48.0)
		left_leg.rotation_degrees.x = leg_angle
		right_leg.rotation_degrees.x = -leg_angle
		
		if left_shin: left_shin.rotation_degrees.x = max(0.0, -leg_angle * 0.8)
		if right_shin: right_shin.rotation_degrees.x = max(0.0, leg_angle * 0.8)
		
		# Torso dynamic bounce, tilt, and banking
		torso.position.y = 0.95 + abs(sin(run_cycle * 2.0)) * 0.06
		torso.rotation_degrees.z = -input_dir.x * 6.0
		torso.rotation_degrees.x = -4.0 if not is_dashing else -16.0
		left_arm.rotation_degrees.x = -sin(run_cycle) * 18.0
		
		step_timer += delta
		if step_timer >= step_interval:
			step_timer = 0.0
			AudioManager.play_step()
	else:
		left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 14.0 * delta)
		right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 14.0 * delta)
		if left_shin: left_shin.rotation_degrees.x = lerp(left_shin.rotation_degrees.x, 0.0, 14.0 * delta)
		if right_shin: right_shin.rotation_degrees.x = lerp(right_shin.rotation_degrees.x, 0.0, 14.0 * delta)
		left_arm.rotation_degrees.x = lerp(left_arm.rotation_degrees.x, 0.0, 10.0 * delta)
		torso.position.y = lerp(torso.position.y, 0.95, 10.0 * delta)
		torso.rotation_degrees.z = lerp(torso.rotation_degrees.z, 0.0, 10.0 * delta)
		torso.rotation_degrees.x = lerp(torso.rotation_degrees.x, 0.0, 10.0 * delta)
	
	# Sniper Zoom (Hold RMB while Railgun is selected)
	if current_weapon == 2 and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		is_scoped = true
		target_fov = 36.0
	else:
		is_scoped = false
		target_fov = 74.0
	camera.fov = lerp(camera.fov, target_fov, 14.0 * delta)
	
	# Procedural Weapon Sway interpolation
	sway_offset = lerp(sway_offset, Vector2.ZERO, 8.0 * delta)
	if rifle_mount:
		rifle_mount.position.x = 0.34 + sway_offset.x
		rifle_mount.position.y = -0.04 + sway_offset.y
		rifle_mount.rotation_degrees.z = sway_offset.x * 40.0
	
	# Combat Actions
	fire_timers[current_weapon] -= delta
	var fire_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("fire")
	if fire_pressed and fire_timers[current_weapon] <= 0.0 and not is_overheated:
		_execute_attack()
		var rate = fire_rates[current_weapon]
		if is_overclocked: rate *= 0.55
		fire_timers[current_weapon] = rate
		
	# EMP Blast (Q key)
	var emp_pressed = Input.is_physical_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_Q) or (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and current_weapon != 2)
	if emp_pressed and emp_cooldown <= 0.0:
		_trigger_emp()
		
	# Reprogramming Hacking (Hold E)
	_process_reprogram(delta)
	
	# Camera update
	_update_camera(delta)

func _switch_weapon(new_idx: int, force: bool = false) -> void:
	if current_weapon == new_idx and not force:
		return
	current_weapon = new_idx
	if not force:
		AudioManager.play_weapon_switch()
	weapon_changed.emit(current_weapon, weapon_names[current_weapon])
	
	if gun_mesh_rifle: gun_mesh_rifle.visible = (current_weapon == 0)
	if gun_mesh_shotgun: gun_mesh_shotgun.visible = (current_weapon == 1)
	if gun_mesh_railgun: gun_mesh_railgun.visible = (current_weapon == 2)

func reward_wave_completion() -> void:
	shield = max_shield
	health = min(max_health, health + 100.0)
	stim_packs = min(4, stim_packs + 1)
	health_changed.emit(health, max_health)
	shield_changed.emit(shield, max_shield)
	stim_changed.emit(stim_packs)

func _use_stim_pack() -> void:
	stim_packs -= 1
	health = min(max_health, health + 120.0)
	health_changed.emit(health, max_health)
	stim_changed.emit(stim_packs)
	AudioManager.play_stim()
	camera_shake = 0.2
	
	# Green heal flash
	var heal_flash = OmniLight3D.new()
	heal_flash.light_color = Color(0.1, 1.0, 0.4)
	heal_flash.light_energy = 5.0
	heal_flash.omni_range = 6.0
	add_child(heal_flash)
	heal_flash.position = Vector3(0, 1.0, 0)
	var t = create_tween()
	t.tween_property(heal_flash, "light_energy", 0.0, 0.35)
	t.tween_callback(heal_flash.queue_free)

func _activate_overclock() -> void:
	is_overclocked = true
	overclock_timer = overclock_duration
	overclock_cooldown = overclock_max_cooldown
	Engine.time_scale = 0.42 # Bullet-Time matrix slow-motion
	AudioManager.play_overclock()
	overclock_updated.emit(false, overclock_max_cooldown)
	if overclock_particles: overclock_particles.emitting = true
	camera_shake = 0.4

func _deactivate_overclock() -> void:
	is_overclocked = false
	Engine.time_scale = 1.0
	if overclock_particles: overclock_particles.emitting = false

func _execute_attack() -> void:
	var heat_cost = 9.0
	if is_overclocked: heat_cost = 0.0 # Free fire in overclock
	
	current_heat = min(max_heat, current_heat + heat_cost)
	if current_heat >= max_heat:
		is_overheated = true
		AudioManager.play_alert()
	heat_updated.emit(current_heat, max_heat)
	
	match current_weapon:
		0: _shoot_pulse_rifle()
		1: _shoot_plasma_shotgun()
		2: _shoot_ion_railgun()

func _shoot_pulse_rifle() -> void:
	AudioManager.play_shoot(1.15)
	camera_shake = max(camera_shake, 0.14)
	_apply_weapon_recoil(-0.20, -5.0)
	_spawn_bullet("pulse_rifle", 32.0, Vector3.ZERO)

func _shoot_plasma_shotgun() -> void:
	AudioManager.play_shotgun()
	camera_shake = max(camera_shake, 0.35)
	_apply_weapon_recoil(-0.14, -14.0)
	# 8-pellet spread
	for i in range(8):
		var spread = Vector3(
			randf_range(-0.08, 0.08),
			randf_range(-0.06, 0.06),
			randf_range(-0.08, 0.08)
		)
		_spawn_bullet("shotgun", 24.0, spread)

func _shoot_ion_railgun() -> void:
	AudioManager.play_railgun()
	camera_shake = max(camera_shake, 0.5)
	_apply_weapon_recoil(-0.10, -18.0)
	_spawn_bullet("railgun", 185.0, Vector3.ZERO)

func _apply_weapon_recoil(kick_z: float, kick_rot: float) -> void:
	rifle_mount.position.z = kick_z
	rifle_mount.rotation_degrees.x = kick_rot
	var tween = create_tween()
	tween.tween_property(rifle_mount, "position:z", -0.26, 0.08)
	tween.parallel().tween_property(rifle_mount, "rotation_degrees:x", 0.0, 0.10)
	
	if muzzle_light:
		muzzle_light.light_energy = 8.0
		var lt = create_tween()
		lt.tween_property(muzzle_light, "light_energy", 0.0, 0.08)

func _spawn_bullet(w_type: String, dmg: float, spread: Vector3) -> void:
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.team = "player"
	bullet.weapon_type = w_type
	bullet.damage = dmg
	
	var aim_target = _get_aim_target()
	var spawn_pos = muzzle_marker.global_position
	var aim_dir = (aim_target - spawn_pos).normalized() + spread
	aim_dir = aim_dir.normalized()
	
	bullet.direction = aim_dir
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos

func _get_aim_target() -> Vector3:
	var ray_length = 220.0
	var from = camera.global_position
	var forward = -camera.global_transform.basis.z
	var to = from + forward * ray_length
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.position
	return to

func _trigger_emp() -> void:
	emp_cooldown = emp_max_cooldown
	emp_cooldown_updated.emit(emp_cooldown, emp_max_cooldown)
	AudioManager.play_emp()
	camera_shake = 0.55
	
	var blast_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.6
	blast_mesh.mesh = torus
	blast_mesh.rotation_degrees.x = 90
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.95, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.95, 1.0)
	mat.emission_energy_multiplier = 4.0
	blast_mesh.material_override = mat
	
	get_parent().add_child(blast_mesh)
	blast_mesh.global_position = global_position + Vector3(0, 0.4, 0)
	
	var tween = create_tween()
	tween.tween_property(blast_mesh, "scale", Vector3(emp_radius, 1.0, emp_radius), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.45)
	tween.tween_callback(blast_mesh.queue_free)
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("apply_emp_stun"):
			var d = global_position.distance_to(enemy.global_position)
			if d <= emp_radius:
				enemy.apply_emp_stun(7.5)

func _process_reprogram(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_stunned: Node3D = null
	var min_dist = 9.0
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.get("is_stunned") == true:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_stunned = enemy
				
	nearby_stunned_enemy = closest_stunned
	
	var reprogram_active = Input.is_physical_key_pressed(KEY_E) or Input.is_key_pressed(KEY_E) or Input.is_action_pressed("reprogram")
	if nearby_stunned_enemy and reprogram_active:
		reprogram_timer += delta
		var prog = clamp(reprogram_timer / reprogram_duration, 0.0, 1.0)
		reprogram_progress_updated.emit(prog)
		
		if reprogram_timer >= reprogram_duration:
			reprogram_timer = 0.0
			reprogram_progress_updated.emit(0.0)
			_convert_enemy_to_ally(nearby_stunned_enemy)
	else:
		if reprogram_timer > 0.0:
			reprogram_timer = 0.0
			reprogram_progress_updated.emit(0.0)

func _convert_enemy_to_ally(enemy: Node3D) -> void:
	AudioManager.play_reprogram()
	var spawn_pos = enemy.global_position
	var b_type = enemy.get("bot_type")
	enemy.queue_free()
	
	var ally_scene = load("res://scripts/ally_mech.gd")
	var ally = CharacterBody3D.new()
	ally.set_script(ally_scene)
	if b_type != null:
		ally.set("ally_type", b_type)
	get_parent().add_child(ally)
	ally.global_position = spawn_pos
	
	var main_node = get_parent()
	if main_node.has_method("on_bot_reprogrammed"):
		main_node.on_bot_reprogrammed()

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO) -> void:
	if invuln_timer > 0.0: return # Invulnerability frames protect against multi-bullet melt
	
	invuln_timer = 0.35
	shield_regen_timer = shield_regen_delay
	camera_shake = max(camera_shake, 0.35)
	
	# Shield absorbs damage first
	if shield > 0.0:
		if shield >= amount:
			shield -= amount
			amount = 0.0
		else:
			amount -= shield
			shield = 0.0
			AudioManager.play_shield_break()
		shield_changed.emit(shield, max_shield)
		
	if amount > 0.0:
		health = max(0.0, health - amount)
		health_changed.emit(health, max_health)
		AudioManager.play_hit()
		
	if health <= 0.0:
		AudioManager.play_explosion()
		if is_overclocked: _deactivate_overclock()
		var main_node = get_parent()
		if main_node.has_method("game_over"):
			main_node.game_over(false)

func _update_camera(delta: float) -> void:
	camera_pivot.global_position = global_position + Vector3(0, 1.5, 0)
	camera_pivot.rotation.y = camera_yaw
	spring_arm.rotation_degrees.x = camera_pitch
	
	if camera_shake > 0.0:
		camera_shake = max(0.0, camera_shake - delta * 2.2)
		var shake_offset = Vector3(
			randf_range(-camera_shake, camera_shake) * 0.16,
			randf_range(-camera_shake, camera_shake) * 0.16,
			0
		)
		camera.position = shake_offset
	else:
		camera.position = Vector3.ZERO

func _setup_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.top_level = true
	add_child(camera_pivot)
	
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 3.8
	spring_arm.margin = 0.2
	camera_pivot.add_child(spring_arm)
	
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 74.0
	camera.far = 600.0
	spring_arm.add_child(camera)
	
	# Over Kai's right shoulder for classic OTS shooter perspective
	spring_arm.position = Vector3(0.85, 0.35, 0)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)

func _build_detailed_human_kai() -> void:
	body_root = Node3D.new()
	add_child(body_root)
	
	# PBR Materials
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.92, 0.76, 0.64)
	skin_mat.roughness = 0.65
	
	var hair_mat = StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.12, 0.14, 0.18)
	hair_mat.roughness = 0.5
	
	var jacket_mat = StandardMaterial3D.new()
	jacket_mat.albedo_color = Color(0.18, 0.22, 0.28)
	jacket_mat.metallic = 0.7
	jacket_mat.roughness = 0.35
	
	var armor_mat = StandardMaterial3D.new()
	armor_mat.albedo_color = Color(0.24, 0.28, 0.36)
	armor_mat.metallic = 0.92
	armor_mat.roughness = 0.25
	
	var cyber_chrome_mat = StandardMaterial3D.new()
	cyber_chrome_mat.albedo_color = Color(0.75, 0.8, 0.85)
	cyber_chrome_mat.metallic = 0.98
	cyber_chrome_mat.roughness = 0.15
	
	var cyan_neon_mat = StandardMaterial3D.new()
	var neon_col = Color(0.0, 0.95, 1.0)
	cyan_neon_mat.albedo_color = neon_col
	cyan_neon_mat.emission_enabled = true
	cyan_neon_mat.emission = neon_col
	cyan_neon_mat.emission_energy_multiplier = 2.2
	
	var magenta_mat = StandardMaterial3D.new()
	var mag_col = Color(0.85, 0.15, 1.0)
	magenta_mat.albedo_color = mag_col
	magenta_mat.emission_enabled = true
	magenta_mat.emission = mag_col
	magenta_mat.emission_energy_multiplier = 2.2
	
	backpack_reactor_mat = StandardMaterial3D.new()
	backpack_reactor_mat.albedo_color = neon_col
	backpack_reactor_mat.emission_enabled = true
	backpack_reactor_mat.emission = neon_col
	backpack_reactor_mat.emission_energy_multiplier = 2.5
	
	var pants_mat = StandardMaterial3D.new()
	pants_mat.albedo_color = Color(0.14, 0.16, 0.20)
	pants_mat.roughness = 0.65
	
	var boots_mat = StandardMaterial3D.new()
	boots_mat.albedo_color = Color(0.06, 0.08, 0.10)
	boots_mat.metallic = 0.85
	boots_mat.roughness = 0.25
	
	var weapon_steel_mat = StandardMaterial3D.new()
	weapon_steel_mat.albedo_color = Color(0.18, 0.20, 0.24)
	weapon_steel_mat.metallic = 0.96
	weapon_steel_mat.roughness = 0.20

	# 1. Torso & Tactical Armor Vest
	torso = Node3D.new()
	torso.position.y = 0.95
	body_root.add_child(torso)
	
	# Compression jacket
	var chest = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.48, 0.52, 0.28)
	chest.mesh = c_box
	chest.material_override = jacket_mat
	torso.add_child(chest)
	
	# Raised Jacket Collar
	var collar = MeshInstance3D.new()
	var col_box = BoxMesh.new()
	col_box.size = Vector3(0.36, 0.14, 0.24)
	collar.mesh = col_box
	collar.position = Vector3(0, 0.28, 0.02)
	collar.material_override = jacket_mat
	torso.add_child(collar)
	
	# Front Segmented Ballistic Chest Plates
	var plate_u = MeshInstance3D.new()
	var pu_box = BoxMesh.new()
	pu_box.size = Vector3(0.42, 0.22, 0.08)
	plate_u.mesh = pu_box
	plate_u.position = Vector3(0, 0.12, -0.15)
	plate_u.material_override = armor_mat
	torso.add_child(plate_u)
	
	var plate_l = MeshInstance3D.new()
	var pl_box = BoxMesh.new()
	pl_box.size = Vector3(0.38, 0.18, 0.07)
	plate_l.mesh = pl_box
	plate_l.position = Vector3(0, -0.1, -0.15)
	plate_l.material_override = armor_mat
	torso.add_child(plate_l)
	
	# Glowing Cyan Tactical Power Line on chest
	var led_strip = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(0.32, 0.03, 0.02)
	led_strip.mesh = l_box
	led_strip.position = Vector3(0, 0.14, -0.19)
	led_strip.material_override = cyan_neon_mat
	torso.add_child(led_strip)
	
	# Shoulder Pauldrons
	for side in [-1, 1]:
		var pad = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.16, 0.18, 0.24)
		pad.mesh = p_box
		pad.position = Vector3(side * 0.28, 0.22, 0)
		pad.material_override = armor_mat
		torso.add_child(pad)
		
	# Back (+Z): High-Tech EMP Reactor Backpack
	var pack = MeshInstance3D.new()
	var pack_box = BoxMesh.new()
	pack_box.size = Vector3(0.34, 0.42, 0.14)
	pack.mesh = pack_box
	pack.position = Vector3(0, 0.06, 0.18)
	pack.material_override = armor_mat
	torso.add_child(pack)
	
	# Glowing EMP Reactor Core Cylinder
	var reactor_core = MeshInstance3D.new()
	var rc_cyl = CylinderMesh.new()
	rc_cyl.top_radius = 0.07
	rc_cyl.bottom_radius = 0.07
	rc_cyl.height = 0.28
	reactor_core.mesh = rc_cyl
	reactor_core.rotation_degrees.z = 90
	reactor_core.position = Vector3(0, 0.06, 0.26)
	reactor_core.material_override = backpack_reactor_mat
	torso.add_child(reactor_core)
	
	# Cooling fins
	for y_off in [-0.08, 0.0, 0.08]:
		var fin = MeshInstance3D.new()
		var f_box = BoxMesh.new()
		f_box.size = Vector3(0.26, 0.02, 0.06)
		fin.mesh = f_box
		fin.position = Vector3(0, y_off, 0.25)
		fin.material_override = weapon_steel_mat
		torso.add_child(fin)

	# 2. Head, Cyber Visor & Layered Hair
	head = Node3D.new()
	head.position = Vector3(0, 0.42, 0)
	torso.add_child(head)
	
	var face = MeshInstance3D.new()
	var f_sph = SphereMesh.new()
	f_sph.radius = 0.14
	f_sph.height = 0.30
	face.mesh = f_sph
	face.position = Vector3(0, 0, -0.02)
	face.material_override = skin_mat
	head.add_child(face)
	
	# Hair: Covering crown and back (+Z) of head
	var hair_back = MeshInstance3D.new()
	var hb_box = BoxMesh.new()
	hb_box.size = Vector3(0.34, 0.26, 0.22)
	hair_back.mesh = hb_box
	hair_back.position = Vector3(0, 0.04, 0.08)
	hair_back.material_override = hair_mat
	head.add_child(hair_back)
	
	var hair_top = MeshInstance3D.new()
	var ht_box = BoxMesh.new()
	ht_box.size = Vector3(0.32, 0.14, 0.32)
	hair_top.mesh = ht_box
	hair_top.position = Vector3(0, 0.15, -0.01)
	hair_top.material_override = hair_mat
	head.add_child(hair_top)
	
	# Styled bangs fringe at forehead (-Z)
	var hair_fringe = MeshInstance3D.new()
	var hf_box = BoxMesh.new()
	hf_box.size = Vector3(0.30, 0.12, 0.14)
	hair_fringe.mesh = hf_box
	hair_fringe.position = Vector3(0, 0.12, -0.14)
	hair_fringe.rotation_degrees.x = 22
	hair_fringe.material_override = hair_mat
	head.add_child(hair_fringe)
	
	# Glowing Tactical Cyber Visor
	var visor = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.28, 0.06, 0.14)
	visor.mesh = v_box
	visor.position = Vector3(0, 0.02, -0.14)
	visor.material_override = cyan_neon_mat
	head.add_child(visor)
	
	# Comms Headset with Boom Mic
	var headset = MeshInstance3D.new()
	var hs_box = BoxMesh.new()
	hs_box.size = Vector3(0.06, 0.10, 0.10)
	headset.mesh = hs_box
	headset.position = Vector3(-0.16, 0.02, -0.02)
	headset.material_override = boots_mat
	head.add_child(headset)

	# 3. Arms & Dynamic Weapon Grip
	# Left Arm: Chrome Cybernetic Prosthetic Hacking Arm
	left_arm = Node3D.new()
	left_arm.position = Vector3(-0.24, 0.12, 0)
	torso.add_child(left_arm)
	
	var l_upper = MeshInstance3D.new()
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.065
	l_cyl.bottom_radius = 0.06
	l_cyl.height = 0.36
	l_upper.mesh = l_cyl
	l_upper.rotation_degrees.z = -30
	l_upper.rotation_degrees.x = 40
	l_upper.position = Vector3(0.10, -0.14, -0.12)
	l_upper.material_override = cyber_chrome_mat
	left_arm.add_child(l_upper)
	
	var gauntlet = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(0.12, 0.14, 0.16)
	gauntlet.mesh = g_box
	gauntlet.position = Vector3(0.24, -0.20, -0.26)
	gauntlet.material_override = cyan_neon_mat
	left_arm.add_child(gauntlet)
	
	# Right Arm: Armed with Weapon
	right_arm = Node3D.new()
	right_arm.position = Vector3(0.30, 0.12, 0)
	torso.add_child(right_arm)
	
	var r_upper = MeshInstance3D.new()
	r_upper.mesh = l_cyl
	r_upper.rotation_degrees.z = 10
	r_upper.rotation_degrees.x = 20
	r_upper.position = Vector3(0.02, -0.14, -0.10)
	r_upper.material_override = jacket_mat
	right_arm.add_child(r_upper)
	
	# 4. Modular Weapon Mount (Transforms with weapon selection!)
	rifle_mount = Node3D.new()
	rifle_mount.position = Vector3(0.34, -0.04, -0.26)
	torso.add_child(rifle_mount)
	
	# --- Weapon 0: Vanguard Pulse Assault Rifle ---
	gun_mesh_rifle = Node3D.new()
	rifle_mount.add_child(gun_mesh_rifle)
	
	var rb = MeshInstance3D.new()
	var rb_box = BoxMesh.new()
	rb_box.size = Vector3(0.10, 0.18, 0.65)
	rb.mesh = rb_box
	rb.position = Vector3(0, 0, -0.12)
	rb.material_override = weapon_steel_mat
	gun_mesh_rifle.add_child(rb)
	
	var r_cell = MeshInstance3D.new()
	var rc_box = BoxMesh.new()
	rc_box.size = Vector3(0.06, 0.14, 0.18)
	r_cell.mesh = rc_box
	r_cell.position = Vector3(0, -0.04, 0.05)
	r_cell.material_override = cyan_neon_mat
	gun_mesh_rifle.add_child(r_cell)
	
	var sight = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.06, 0.09, 0.18)
	sight.mesh = s_box
	sight.position = Vector3(0, 0.13, -0.18)
	sight.material_override = cyan_neon_mat
	gun_mesh_rifle.add_child(sight)
	
	var barrel = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.035
	b_cyl.bottom_radius = 0.035
	b_cyl.height = 0.55
	barrel.mesh = b_cyl
	barrel.rotation_degrees.x = 90
	barrel.position = Vector3(0, 0.02, -0.52)
	barrel.material_override = weapon_steel_mat
	gun_mesh_rifle.add_child(barrel)
	
	# --- Weapon 1: Scatter Plasma Shotgun ---
	gun_mesh_shotgun = Node3D.new()
	gun_mesh_shotgun.visible = false
	rifle_mount.add_child(gun_mesh_shotgun)
	
	var sb = MeshInstance3D.new()
	var sb_box = BoxMesh.new()
	sb_box.size = Vector3(0.14, 0.20, 0.55)
	sb.mesh = sb_box
	sb.position = Vector3(0, 0, -0.10)
	sb.material_override = weapon_steel_mat
	gun_mesh_shotgun.add_child(sb)
	
	for sx in [-0.04, 0.04]:
		var s_bar = MeshInstance3D.new()
		var s_cyl = CylinderMesh.new()
		s_cyl.top_radius = 0.045
		s_cyl.bottom_radius = 0.045
		s_cyl.height = 0.48
		s_bar.mesh = s_cyl
		s_bar.rotation_degrees.x = 90
		s_bar.position = Vector3(sx, 0.02, -0.45)
		s_bar.material_override = weapon_steel_mat
		gun_mesh_shotgun.add_child(s_bar)
		
	var s_mag = MeshInstance3D.new()
	var sm_box = BoxMesh.new()
	sm_box.size = Vector3(0.10, 0.12, 0.20)
	s_mag.mesh = sm_box
	s_mag.position = Vector3(0, -0.06, 0.02)
	s_mag.material_override = magenta_mat
	gun_mesh_shotgun.add_child(s_mag)
	
	# --- Weapon 2: Hyper Ion Railgun ---
	gun_mesh_railgun = Node3D.new()
	gun_mesh_railgun.visible = false
	rifle_mount.add_child(gun_mesh_railgun)
	
	var rlg_b = MeshInstance3D.new()
	var rlg_box = BoxMesh.new()
	rlg_box.size = Vector3(0.12, 0.18, 0.75)
	rlg_b.mesh = rlg_box
	rlg_b.position = Vector3(0, 0, -0.14)
	rlg_b.material_override = weapon_steel_mat
	gun_mesh_railgun.add_child(rlg_b)
	
	# Dual magnetic accelerator rails
	for side in [-0.04, 0.04]:
		var rail = MeshInstance3D.new()
		var rail_box = BoxMesh.new()
		rail_box.size = Vector3(0.025, 0.05, 0.75)
		rail.mesh = rail_box
		rail.position = Vector3(side, 0.02, -0.65)
		rail.material_override = cyan_neon_mat
		gun_mesh_railgun.add_child(rail)
		
	# High-magnification sniper scope
	var scope = MeshInstance3D.new()
	var sc_cyl = CylinderMesh.new()
	sc_cyl.top_radius = 0.04
	sc_cyl.bottom_radius = 0.04
	sc_cyl.height = 0.35
	scope.mesh = sc_cyl
	scope.rotation_degrees.x = 90
	scope.position = Vector3(0, 0.14, -0.22)
	scope.material_override = cyber_chrome_mat
	gun_mesh_railgun.add_child(scope)
	
	# Shared Muzzle Marker & Flash
	muzzle_marker = Marker3D.new()
	muzzle_marker.position = Vector3(0, 0.02, -0.85)
	rifle_mount.add_child(muzzle_marker)
	
	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color(0.1, 0.95, 1.0)
	muzzle_light.light_energy = 0.0
	muzzle_light.omni_range = 9.0
	muzzle_marker.add_child(muzzle_light)

	# 5. Articulated Legs & Combat Boots
	var leg_data_left = _create_human_leg(Vector3(-0.16, 0.0, 0), pants_mat, boots_mat, armor_mat, cyan_neon_mat)
	left_leg = leg_data_left[0]
	left_shin = leg_data_left[1]
	body_root.add_child(left_leg)
	
	var leg_data_right = _create_human_leg(Vector3(0.16, 0.0, 0), pants_mat, boots_mat, armor_mat, cyan_neon_mat)
	right_leg = leg_data_right[0]
	right_shin = leg_data_right[1]
	body_root.add_child(right_leg)
	
	# Dash Boot Thruster Spark Particles
	dash_particles = CPUParticles3D.new()
	dash_particles.emitting = false
	dash_particles.amount = 26
	dash_particles.lifetime = 0.28
	dash_particles.spread = 120.0
	dash_particles.initial_velocity_min = 4.0
	dash_particles.initial_velocity_max = 9.0
	dash_particles.gravity = Vector3(0, 2.5, 0)
	dash_particles.color = Color(0.0, 0.95, 1.0)
	dash_particles.position = Vector3(0, 0.1, 0.15)
	body_root.add_child(dash_particles)
	
	# Overclock Lightning Particle Aura
	overclock_particles = CPUParticles3D.new()
	overclock_particles.emitting = false
	overclock_particles.amount = 32
	overclock_particles.lifetime = 0.4
	overclock_particles.spread = 180.0
	overclock_particles.initial_velocity_min = 2.0
	overclock_particles.initial_velocity_max = 5.0
	overclock_particles.gravity = Vector3(0, 1.0, 0)
	overclock_particles.color = Color(0.2, 0.9, 1.0)
	overclock_particles.position = Vector3(0, 0.9, 0)
	body_root.add_child(overclock_particles)
	
	# Shield Shimmer Mesh (Flashes when shield absorbs hits)
	shield_shimmer = MeshInstance3D.new()
	var s_capsule = CapsuleMesh.new()
	s_capsule.radius = 0.65
	s_capsule.height = 2.1
	shield_shimmer.mesh = s_capsule
	shield_shimmer.position.y = 0.95
	var s_mat = StandardMaterial3D.new()
	s_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s_mat.albedo_color = Color(0.0, 0.8, 1.0, 0.35)
	s_mat.emission_enabled = true
	s_mat.emission = Color(0.0, 0.8, 1.0)
	s_mat.emission_energy_multiplier = 2.0
	shield_shimmer.material_override = s_mat
	shield_shimmer.visible = false
	body_root.add_child(shield_shimmer)

func _create_human_leg(pos: Vector3, pants_mat: Material, boots_mat: Material, armor_mat: Material, neon_mat: Material) -> Array:
	var thigh_root = Node3D.new()
	thigh_root.position = pos + Vector3(0, 0.92, 0)
	
	# Thigh
	var thigh = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.09
	t_cyl.bottom_radius = 0.08
	t_cyl.height = 0.44
	thigh.mesh = t_cyl
	thigh.position.y = -0.22
	thigh.material_override = pants_mat
	thigh_root.add_child(thigh)
	
	# Knee Shin Joint
	var shin_root = Node3D.new()
	shin_root.position = Vector3(0, -0.44, 0)
	thigh_root.add_child(shin_root)
	
	# Knee Guard Armor Pad
	var knee = MeshInstance3D.new()
	var k_box = BoxMesh.new()
	k_box.size = Vector3(0.14, 0.12, 0.08)
	knee.mesh = k_box
	knee.position = Vector3(0, 0, -0.08)
	knee.material_override = armor_mat
	shin_root.add_child(knee)
	
	# Shin
	var shin = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.075
	s_cyl.bottom_radius = 0.07
	s_cyl.height = 0.44
	shin.mesh = s_cyl
	shin.position.y = -0.22
	shin.material_override = pants_mat
	shin_root.add_child(shin)
	
	# Armored Combat Boot
	var boot = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.15, 0.14, 0.28)
	boot.mesh = b_box
	boot.position = Vector3(0, -0.42, -0.05)
	boot.material_override = boots_mat
	shin_root.add_child(boot)
	
	# Glowing Cyan Anti-Grav Sole Thruster Strip
	var thruster_sole = MeshInstance3D.new()
	var ts_box = BoxMesh.new()
	ts_box.size = Vector3(0.12, 0.02, 0.24)
	thruster_sole.mesh = ts_box
	thruster_sole.position = Vector3(0, -0.49, -0.05)
	thruster_sole.material_override = neon_mat
	shin_root.add_child(thruster_sole)
	
	return [thigh_root, shin_root]
