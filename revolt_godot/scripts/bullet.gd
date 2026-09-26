extends Area3D

# Advanced Projectile Controller for REVOLT 2150
# Clean lifecycle management: zero leftover meshes, zero persistent lights, proper 3D orientation.

var speed: float = 80.0
var damage: float = 30.0
var team: String = "player" # "player", "ally", "enemy"
var weapon_type: String = "pulse_rifle" # "pulse_rifle", "shotgun", "railgun", "enemy"
var lifetime: float = 3.0
var direction: Vector3 = Vector3.FORWARD
var pierce_count: int = 1
var spawn_origin: Vector3 = Vector3.ZERO

func initialize_projectile(spawn_pos: Vector3, dir: Vector3, shooter_team: String, w_type: String, dmg: float) -> void:
	position = spawn_pos
	spawn_origin = spawn_pos
	direction = dir.normalized()
	team = shooter_team
	weapon_type = w_type
	damage = dmg

func _ready() -> void:
	if spawn_origin != Vector3.ZERO:
		global_position = spawn_origin
	else:
		spawn_origin = global_position
		
	body_entered.connect(_on_body_entered)
	
	var mesh_inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	var col = Color(0.0, 0.95, 1.0)
	
	match weapon_type:
		"pulse_rifle":
			var cap = CapsuleMesh.new()
			cap.radius = 0.10
			cap.height = 0.9
			mesh_inst.mesh = cap
			col = Color(0.0, 0.95, 1.0) # Luminous cyan
			speed = 95.0
			lifetime = 2.5
		"shotgun":
			var sph = SphereMesh.new()
			sph.radius = 0.16
			sph.height = 0.32
			mesh_inst.mesh = sph
			col = Color(0.9, 0.2, 1.0) # Violet / Magenta plasma
			speed = 75.0
			lifetime = 0.85
		"railgun":
			var cap = CapsuleMesh.new()
			cap.radius = 0.08
			cap.height = 2.6
			mesh_inst.mesh = cap
			col = Color(0.3, 0.85, 1.0) # Electric blue hyper-beam
			speed = 220.0
			pierce_count = 3
			lifetime = 0.60
		"enemy":
			var cap = CapsuleMesh.new()
			cap.radius = 0.18
			cap.height = 1.2
			mesh_inst.mesh = cap
			col = Color(1.0, 0.35, 0.05) # Burning orange/red plasma
			speed = 60.0
			lifetime = 3.5 # Travel full 150m arena
	
	mesh_inst.rotation_degrees.x = 90
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 4.5
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Light attached directly to bullet (freed automatically when bullet frees)
	var light = OmniLight3D.new()
	light.light_color = col
	light.light_energy = 2.5
	light.omni_range = 6.5
	add_child(light)
	
	# Collision Shape
	var col_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.38
	col_shape.shape = sphere
	add_child(col_shape)
	
	# Align projectile orientation with movement direction
	set_direction(direction)

func set_direction(dir: Vector3) -> void:
	direction = dir.normalized()
	if direction.length_squared() > 0.001:
		var up = Vector3.UP if abs(direction.y) < 0.95 else Vector3.RIGHT
		look_at(global_position + direction, up)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body == self: return
	
	# Check if target can take damage
	if body.has_method("take_damage"):
		var target_team = body.get("team") if "team" in body else ""
		if target_team != "" and target_team == team:
			return # Friendly unit, pass through safely
			
		body.take_damage(damage, global_position)
		AudioManager.play_hit()
		_spawn_impact_burst()
		pierce_count -= 1
		if pierce_count <= 0:
			queue_free()
		return
		
	# Ignore world geometry (floor/crates) collisions within 1.0m of spawn point to prevent muzzle clipping
	if global_position.distance_to(spawn_origin) < 1.0:
		return
		
	# Hit world geometry (cargo containers, blast walls, runway floor)
	_spawn_impact_burst()
	queue_free()

func _spawn_impact_burst() -> void:
	var root = get_parent() if is_instance_valid(get_parent()) else get_tree().current_scene
	if not is_instance_valid(root): return
	
	var p = CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 18
	p.lifetime = 0.30
	p.direction = -direction
	p.spread = 70.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 14.0
	p.gravity = Vector3(0, -9.8, 0)
	
	var col = Color(0.1, 0.95, 1.0) if (team == "player" or team == "ally") else Color(1.0, 0.45, 0.08)
	if weapon_type == "shotgun":
		col = Color(0.9, 0.2, 1.0)
	p.color = col
	
	root.add_child(p)
	p.global_position = global_position
	
	var pt = p.create_tween()
	pt.tween_interval(0.35)
	pt.tween_callback(p.queue_free)
