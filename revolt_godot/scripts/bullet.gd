extends Area3D

# High-Energy Plasma & Kinetic Projectile
# Features luminous glow, tracer trail, dynamic light, and fiery impact bursts.

var speed: float = 65.0
var damage: float = 24.0
var team: String = "player" # "player", "ally", "enemy"
var lifetime: float = 3.5
var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# High-Luminance Plasma Tracer
	var mesh_inst = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.12 if team == "player" else 0.18
	cap.height = 1.0 if team == "player" else 1.4
	mesh_inst.mesh = cap
	mesh_inst.rotation_degrees.x = 90
	
	var mat = StandardMaterial3D.new()
	var col = Color(0.0, 0.95, 1.0) if (team == "player" or team == "ally") else Color(1.0, 0.25, 0.05)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.5
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Dynamic Projectile Light
	var light = OmniLight3D.new()
	light.light_color = col
	light.light_energy = 2.2
	light.omni_range = 6.0
	add_child(light)
	
	# Collision Shape
	var col_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.35
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
			_spawn_impact_burst()
			queue_free()
			return
			
	if not (body.has_method("take_damage") and body.get("team") == team):
		_spawn_impact_burst()
		queue_free()

func _spawn_impact_burst() -> void:
	# Multi-stage spark and dust impact burst
	var p = CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 20
	p.lifetime = 0.4
	p.direction = -direction
	p.spread = 70.0
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 12.0
	p.gravity = Vector3(0, -9.8, 0)
	var col = Color(0.2, 0.9, 1.0) if (team == "player" or team == "ally") else Color(1.0, 0.6, 0.1)
	p.color = col
	get_parent().add_child(p)
	p.global_position = global_position
	
	# Small impact light flash
	var flash = OmniLight3D.new()
	flash.light_color = col
	flash.light_energy = 3.5
	flash.omni_range = 7.0
	get_parent().add_child(flash)
	flash.global_position = global_position
	
	var tween = create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.25)
	tween.tween_callback(flash.queue_free)
	get_tree().create_timer(0.45).timeout.connect(p.queue_free)
