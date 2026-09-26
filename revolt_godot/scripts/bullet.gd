extends Area3D

# High-Velocity Plasma/Autocannon Projectile

var speed: float = 60.0
var damage: float = 18.0
var team: String = "player" # "player", "ally", "enemy"
var lifetime: float = 3.0
var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Visual tracer mesh
	var mesh_inst = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.08
	cap.height = 0.7
	mesh_inst.mesh = cap
	mesh_inst.rotation_degrees.x = 90
	
	var mat = StandardMaterial3D.new()
	var col = Color(0.1, 0.9, 1.0) if (team == "player" or team == "ally") else Color(1.0, 0.3, 0.1)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 6.0
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Light
	var light = OmniLight3D.new()
	light.light_color = col
	light.light_energy = 1.5
	light.omni_range = 3.0
	add_child(light)
	
	# Collision shape
	var col_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.25
	col_shape.shape = sphere
	add_child(col_shape)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		var target_team = body.get("team") if "team" in body else ""
		if target_team != team:
			body.take_damage(damage, global_position)
			AudioManager.play_hit()
			_spawn_hit_sparks()
			queue_free()
			return
			
	# If hit world/wall
	if not (body.has_method("take_damage") and body.get("team") == team):
		_spawn_hit_sparks()
		queue_free()

func _spawn_hit_sparks() -> void:
	# Small spark particle burst
	var particles = CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12
	particles.lifetime = 0.3
	particles.direction = -direction
	particles.spread = 60.0
	particles.initial_velocity_min = 4.0
	particles.initial_velocity_max = 8.0
	particles.gravity = Vector3(0, -9.8, 0)
	particles.color = Color(1.0, 0.8, 0.2)
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Free particles after burst
	get_tree().create_timer(0.4).timeout.connect(particles.queue_free)
