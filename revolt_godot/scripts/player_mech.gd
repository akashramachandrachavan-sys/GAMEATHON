extends CharacterBody3D

# Teen Resistance Hero: KAI
# A human teenager in cyberpunk tactical armor wielding an experimental
# EMP Pulse Rifle and a cybernetic hacking gauntlet to reprogram rogue robots.

signal health_changed(current_hp, max_hp)
signal emp_cooldown_updated(current, max_time)
signal heat_updated(current_heat, max_heat)
signal alliance_count_updated(current_count, max_count)
signal reprogram_progress_updated(progress)

const SPEED = 7.5
const SPRINT_SPEED = 12.0
const ACCEL = 14.0
const ROT_SPEED = 10.0
const MOUSE_SENSITIVITY = 0.0025

var max_health: float = 100.0
var health: float = 100.0
var team: String = "player"

# EMP Disruptor
var emp_max_cooldown: float = 7.0
var emp_cooldown: float = 0.0
var emp_radius: float = 16.0

# Pulse Rifle & Overheat
var max_heat: float = 100.0
var current_heat: float = 0.0
var is_overheated: bool = false
var fire_rate: float = 0.11
var fire_timer: float = 0.0

# Tactical Slide / Dash
var dash_cooldown: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0

# Procedural Human Run Cycle
var run_cycle: float = 0.0
var step_interval: float = 0.32
var step_timer: float = 0.0

# Over-The-Shoulder Camera
var camera_pitch: float = -12.0
var camera_yaw: float = 0.0
var camera_shake: float = 0.0

# Node References
var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var body_root: Node3D
var torso: Node3D
var head: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var rifle: Node3D
var muzzle: Marker3D
var rifle_barrel: MeshInstance3D

# Reprogram target
var nearby_stunned_enemy: Node3D = null
var reprogram_timer: float = 0.0
var reprogram_duration: float = 1.0

func _ready() -> void:
	_build_human_character()
	_setup_camera()
	_setup_collision()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_changed.emit(health, max_health)
	emp_cooldown_updated.emit(0.0, emp_max_cooldown)
	heat_updated.emit(current_heat, max_heat)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
		camera_pitch -= event.relative.y * MOUSE_SENSITIVITY * 40.0
		camera_pitch = clamp(camera_pitch, -50.0, 25.0)
		
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if emp_cooldown > 0.0:
		emp_cooldown = max(0.0, emp_cooldown - delta)
		emp_cooldown_updated.emit(emp_cooldown, emp_max_cooldown)
		
	if dash_cooldown > 0.0:
		dash_cooldown = max(0.0, dash_cooldown - delta)
		
	if current_heat > 0.0:
		var cooling_speed = 40.0 if is_overheated else 60.0
		current_heat = max(0.0, current_heat - cooling_speed * delta)
		if is_overheated and current_heat <= 10.0:
			is_overheated = false
		heat_updated.emit(current_heat, max_heat)

	# Movement input
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"): input_dir.y += 1.0
	if Input.is_action_pressed("move_backward"): input_dir.y -= 1.0
	if Input.is_action_pressed("move_left"): input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"): input_dir.x += 1.0
	input_dir = input_dir.normalized()
	
	# Tactical Slide / Dash
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0 and input_dir != Vector2.ZERO:
		is_dashing = true
		dash_timer = 0.25
		dash_cooldown = 1.8
		AudioManager.play_dash()
		camera_shake = 0.3
		
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	# Calculate Movement Direction relative to Camera
	var cam_forward = Vector3(-sin(camera_yaw), 0, -cos(camera_yaw)).normalized()
	var cam_right = Vector3(cos(camera_yaw), 0, -sin(camera_yaw)).normalized()
	var move_vec = (cam_forward * input_dir.y + cam_right * input_dir.x).normalized()
	
	var target_speed = SPEED
	if is_dashing:
		target_speed = SPRINT_SPEED * 1.8
		
	var target_vel = move_vec * target_speed
	velocity.x = lerp(velocity.x, target_vel.x, ACCEL * delta)
	velocity.z = lerp(velocity.z, target_vel.z, ACCEL * delta)
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	else:
		velocity.y = 0.0
		
	move_and_slide()
	
	# Human Stride Animation & Aim Rotation
	# Kai always faces aiming direction
	rotation.y = lerp_angle(rotation.y, camera_yaw, ROT_SPEED * delta)
	
	if move_vec.length() > 0.1:
		run_cycle += delta * (14.0 if not is_dashing else 26.0)
		left_leg.rotation_degrees.x = sin(run_cycle) * 32.0
		right_leg.rotation_degrees.x = -sin(run_cycle) * 32.0
		left_arm.rotation_degrees.x = -sin(run_cycle) * 25.0
		torso.position.y = 1.0 + abs(sin(run_cycle * 2.0)) * 0.05
		
		step_timer += delta
		if step_timer >= step_interval:
			step_timer = 0.0
			AudioManager.play_step()
	else:
		left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, 0.0, 10.0 * delta)
		right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, 0.0, 10.0 * delta)
		left_arm.rotation_degrees.x = lerp(left_arm.rotation_degrees.x, 15.0, 10.0 * delta)
		torso.position.y = lerp(torso.position.y, 1.0, 10.0 * delta)
	
	_update_camera(delta)
	
	# Weapon actions
	fire_timer -= delta
	if Input.is_action_pressed("fire") and fire_timer <= 0.0 and not is_overheated:
		_shoot_pulse_rifle()
		
	if Input.is_action_just_pressed("fire_emp") and emp_cooldown <= 0.0:
		_trigger_emp()
		
	_process_reprogram(delta)

func _shoot_pulse_rifle() -> void:
	fire_timer = fire_rate
	current_heat += 4.0
	if current_heat >= max_heat:
		is_overheated = true
		AudioManager.play_alert()
	heat_updated.emit(current_heat, max_heat)
	
	AudioManager.play_shoot(1.15)
	camera_shake = max(camera_shake, 0.08)
	
	# Bullet
	var bullet_script = load("res://scripts/bullet.gd")
	var bullet = Area3D.new()
	bullet.set_script(bullet_script)
	bullet.team = "player"
	bullet.damage = 25.0
	
	# Rifle recoil animation
	rifle.position.z = 0.25
	var tween = create_tween()
	tween.tween_property(rifle, "position:z", 0.35, 0.07)
	
	var aim_target = _get_aim_target()
	var spawn_pos = muzzle.global_position
	var aim_dir = (aim_target - spawn_pos).normalized()
	
	bullet.direction = aim_dir
	get_parent().add_child(bullet)
	bullet.global_position = spawn_pos

func _get_aim_target() -> Vector3:
	var ray_length = 120.0
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
	camera_shake = 0.35
	
	# Expanding cyan EMP shockwave ring
	var blast_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.4
	blast_mesh.mesh = torus
	blast_mesh.rotation_degrees.x = 90
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.9, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.9, 1.0)
	mat.emission_energy_multiplier = 1.8
	blast_mesh.material_override = mat
	
	get_parent().add_child(blast_mesh)
	blast_mesh.global_position = global_position + Vector3(0, 0.4, 0)
	
	var tween = create_tween()
	tween.tween_property(blast_mesh, "scale", Vector3(emp_radius, 1.0, emp_radius), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tween.tween_callback(blast_mesh.queue_free)
	
	# Stun all rogue enemy robots in 16m radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("apply_emp_stun"):
			var d = global_position.distance_to(enemy.global_position)
			if d <= emp_radius:
				enemy.apply_emp_stun(6.5)

func _process_reprogram(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_stunned: Node3D = null
	var min_dist = 5.0
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.get("is_stunned") == true:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_stunned = enemy
				
	nearby_stunned_enemy = closest_stunned
	
	if nearby_stunned_enemy and Input.is_action_pressed("reprogram"):
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
	enemy.queue_free()
	
	var ally_scene = load("res://scripts/ally_mech.gd")
	var ally = CharacterBody3D.new()
	ally.set_script(ally_scene)
	get_parent().add_child(ally)
	ally.global_position = spawn_pos
	
	var main_node = get_parent()
	if main_node.has_method("on_bot_reprogrammed"):
		main_node.on_bot_reprogrammed()

func take_damage(amount: float, _hit_pos: Vector3 = Vector3.ZERO) -> void:
	health = max(0.0, health - amount)
	health_changed.emit(health, max_health)
	camera_shake = max(camera_shake, 0.35)
	
	if health <= 0.0:
		AudioManager.play_explosion()
		var main_node = get_parent()
		if main_node.has_method("game_over"):
			main_node.game_over(false)

func _update_camera(delta: float) -> void:
	# Smooth over-the-shoulder follow
	camera_pivot.global_position = global_position + Vector3(0, 1.6, 0)
	camera_pivot.rotation.y = camera_yaw
	spring_arm.rotation_degrees.x = camera_pitch
	
	if camera_shake > 0.0:
		camera_shake = max(0.0, camera_shake - delta * 2.0)
		var shake_offset = Vector3(
			randf_range(-camera_shake, camera_shake) * 0.15,
			randf_range(-camera_shake, camera_shake) * 0.15,
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
	spring_arm.spring_length = 4.8 # Over-the-shoulder shooter distance
	spring_arm.margin = 0.2
	camera_pivot.add_child(spring_arm)
	
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 72.0
	spring_arm.add_child(camera)
	
	# Over Kai's right shoulder offset
	spring_arm.position = Vector3(0.65, 0.6, 0)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)

func _build_human_character() -> void:
	body_root = Node3D.new()
	body_root.rotation_degrees.y = 180 # Orient Kai facing forward (-Z)
	add_child(body_root)
	
	# Materials for Teen Hero Kai
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.92, 0.76, 0.64)
	skin_mat.roughness = 0.7
	
	var hair_mat = StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.15, 0.16, 0.2)
	hair_mat.roughness = 0.6
	
	var vest_mat = StandardMaterial3D.new()
	vest_mat.albedo_color = Color(0.16, 0.22, 0.3)
	vest_mat.metallic = 0.4
	vest_mat.roughness = 0.4
	
	var pants_mat = StandardMaterial3D.new()
	pants_mat.albedo_color = Color(0.22, 0.25, 0.3)
	pants_mat.roughness = 0.6
	
	var boots_mat = StandardMaterial3D.new()
	boots_mat.albedo_color = Color(0.1, 0.12, 0.15)
	boots_mat.metallic = 0.7
	boots_mat.roughness = 0.3
	
	var visor_mat = StandardMaterial3D.new()
	var neon_cyan = Color(0.0, 0.9, 1.0)
	visor_mat.albedo_color = neon_cyan
	visor_mat.emission_enabled = true
	visor_mat.emission = neon_cyan
	visor_mat.emission_energy_multiplier = 1.5
	
	var rifle_mat = StandardMaterial3D.new()
	rifle_mat.albedo_color = Color(0.22, 0.24, 0.28)
	rifle_mat.metallic = 0.9
	rifle_mat.roughness = 0.3
	
	# 1. Torso & Tactical Vest
	torso = Node3D.new()
	torso.position.y = 1.0
	body_root.add_child(torso)
	
	var chest = MeshInstance3D.new()
	var chest_box = BoxMesh.new()
	chest_box.size = Vector3(0.52, 0.55, 0.28)
	chest.mesh = chest_box
	chest.material_override = vest_mat
	torso.add_child(chest)
	
	# Tactical Armor Plate on chest with cyan LED strip
	var plate = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(0.42, 0.38, 0.08)
	plate.mesh = p_box
	plate.position = Vector3(0, 0.04, 0.15)
	plate.material_override = vest_mat
	torso.add_child(plate)
	
	var led_strip = MeshInstance3D.new()
	var l_box = BoxMesh.new()
	l_box.size = Vector3(0.3, 0.04, 0.02)
	led_strip.mesh = l_box
	led_strip.position = Vector3(0, 0.08, 0.2)
	led_strip.material_override = visor_mat
	torso.add_child(led_strip)
	
	# 2. Head & Cyber Visor
	head = Node3D.new()
	head.position = Vector3(0, 0.45, 0)
	torso.add_child(head)
	
	var face = MeshInstance3D.new()
	var f_sph = SphereMesh.new()
	f_sph.radius = 0.16
	f_sph.height = 0.34
	face.mesh = f_sph
	face.material_override = skin_mat
	head.add_child(face)
	
	# Spiky Cyber Hair
	var hair = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.34, 0.2, 0.34)
	hair.mesh = h_box
	hair.position = Vector3(0, 0.12, -0.02)
	hair.material_override = hair_mat
	head.add_child(hair)
	
	# Cyber Tactical Visor over eyes
	var visor = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.26, 0.06, 0.12)
	visor.mesh = v_box
	visor.position = Vector3(0, 0.04, 0.14)
	visor.material_override = visor_mat
	head.add_child(visor)
	
	# Comms Headset Boom
	var comms = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.34, 0.04, 0.04)
	comms.mesh = c_box
	comms.position = Vector3(0, 0.04, 0.04)
	comms.material_override = boots_mat
	head.add_child(comms)
	
	# 3. Arms & Heavy Pulse Rifle
	# Left Arm (Cybernetic Gauntlet)
	left_arm = Node3D.new()
	left_arm.position = Vector3(-0.35, 0.15, 0)
	torso.add_child(left_arm)
	
	var l_shoulder = MeshInstance3D.new()
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.07
	l_cyl.bottom_radius = 0.06
	l_cyl.height = 0.5
	l_shoulder.mesh = l_cyl
	l_shoulder.position.y = -0.22
	l_shoulder.material_override = vest_mat
	left_arm.add_child(l_shoulder)
	
	# Cybernetic Hacking Gauntlet on left wrist
	var gauntlet = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(0.12, 0.18, 0.14)
	gauntlet.mesh = g_box
	gauntlet.position = Vector3(0, -0.38, 0.04)
	gauntlet.material_override = visor_mat
	left_arm.add_child(gauntlet)
	
	# Right Arm (Gripping Rifle)
	right_arm = Node3D.new()
	right_arm.position = Vector3(0.35, 0.15, 0)
	torso.add_child(right_arm)
	
	var r_shoulder = MeshInstance3D.new()
	r_shoulder.mesh = l_cyl
	r_shoulder.position.y = -0.22
	r_shoulder.material_override = vest_mat
	right_arm.add_child(r_shoulder)
	
	# 4. Experimental Heavy Pulse Rifle
	rifle = Node3D.new()
	rifle.position = Vector3(0.28, -0.1, 0.35)
	torso.add_child(rifle)
	
	var r_body = MeshInstance3D.new()
	var rb_box = BoxMesh.new()
	rb_box.size = Vector3(0.12, 0.18, 0.7)
	r_body.mesh = rb_box
	r_body.material_override = rifle_mat
	rifle.add_child(r_body)
	
	rifle_barrel = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.04
	b_cyl.bottom_radius = 0.04
	b_cyl.height = 0.6
	rifle_barrel.mesh = b_cyl
	rifle_barrel.rotation_degrees.x = 90
	rifle_barrel.position = Vector3(0, 0.02, 0.5)
	rifle_barrel.material_override = rifle_mat
	rifle.add_child(rifle_barrel)
	
	# Underslung EMP Canister Launcher
	var emp_tube = MeshInstance3D.new()
	var et_cyl = CylinderMesh.new()
	et_cyl.top_radius = 0.05
	et_cyl.bottom_radius = 0.05
	et_cyl.height = 0.4
	emp_tube.mesh = et_cyl
	emp_tube.rotation_degrees.x = 90
	emp_tube.position = Vector3(0, -0.08, 0.35)
	emp_tube.material_override = visor_mat
	rifle.add_child(emp_tube)
	
	muzzle = Marker3D.new()
	muzzle.position = Vector3(0, 0.02, 0.85)
	rifle.add_child(muzzle)
	
	# 5. Human Legs & Combat Boots
	left_leg = _create_human_leg(Vector3(-0.16, 0.0, 0), pants_mat, boots_mat)
	right_leg = _create_human_leg(Vector3(0.16, 0.0, 0), pants_mat, boots_mat)
	body_root.add_child(left_leg)
	body_root.add_child(right_leg)

func _create_human_leg(pos: Vector3, pants_mat: Material, boots_mat: Material) -> Node3D:
	var leg_root = Node3D.new()
	leg_root.position = pos + Vector3(0, 0.9, 0)
	
	# Thigh
	var thigh = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.1
	t_cyl.bottom_radius = 0.08
	t_cyl.height = 0.48
	thigh.mesh = t_cyl
	thigh.position.y = -0.24
	thigh.material_override = pants_mat
	leg_root.add_child(thigh)
	
	# Shin
	var shin = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.08
	s_cyl.bottom_radius = 0.07
	s_cyl.height = 0.48
	shin.mesh = s_cyl
	shin.position.y = -0.62
	shin.material_override = pants_mat
	leg_root.add_child(shin)
	
	# Combat Boot
	var boot = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.16, 0.15, 0.3)
	boot.mesh = b_box
	boot.position = Vector3(0, -0.85, 0.06)
	boot.material_override = boots_mat
	leg_root.add_child(boot)
	
	return leg_root
