extends Area3D

# Advanced Multi-Weapon Plasma & Kinetic Projectile (Godot 4.7)
# Supports Pulse Rifle, Plasma Shotgun, and Ion Railgun

var speed: float = 75.0
var damage: float = 30.0
var team: String = "player" # "player", "ally", "enemy"
var weapon_type: String = "pulse_rifle" # "pulse_rifle", "shotgun", "railgun", "enemy"
var lifetime: float = 3.5
var direction: Vector3 = Vector3.FORWARD
var pierce_count: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	var mesh_inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	var col = Color(0.0, 0.95, 1.0)
	
	match weapon_type:
		"pulse_rifle":
			var cap = CapsuleMesh.new()
			cap.radius = 0.12
			cap.height = 1.1
			mesh_inst.mesh = cap
			col = Color(0.0, 0.95, 1.0) # Luminous cyan
			speed = 85.0
		"shotgun":
			var sph = SphereMesh.new()
			sph.radius = 0.16
			sph.height = 0.32
			mesh_inst.mesh = sph
			col = Color(0.85, 0.15, 1.0) # Violet / Magenta plasma
			speed = 65.0
			lifetime = 0.65 # Short range burst
		"railgun":
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.08
			cyl.bottom_radius = 0.08
			cyl.height = 3.2
			mesh_inst.mesh = cyl
			col = Color(0.3, 0.8, 1.0) # Electric blue hyper-beam
			speed = 180.0 # Near-instant hit
			pierce_count = 3
			lifetime = 1.0
		"enemy":
			var cap = CapsuleMesh.new()
			cap.radius = 0.18
			cap.height = 1.4
			mesh_inst.mesh = cap
			col = Color(1.0, 0.35, 0.05) # Burning orange
			speed = 46.0 # Telegraphed so Kai can react and dodge!
	
	mesh_inst.rotation_degrees.x = 90
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.5
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Dynamic Projectile Light
	var light = OmniLight3D.new()
	light.light_color = col
	light.light_energy = 2.8
	light.omni_range = 7.0
	add_child(light)
	
	# Collision Shape
	var col_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.45
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
			pierce_count -= 1
			if pierce_count <= 0:
				queue_free()
			return
			
	if not (body.has_method("take_damage") and body.get("team") == team):
		_spawn_impact_burst()
		queue_free()

func _spawn_impact_burst() -> void:
	var p = CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 24
	p.lifetime = 0.4
	p.direction = -direction
	p.spread = 75.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 14.0
	p.gravity = Vector3(0, -9.8, 0)
	
	var col = Color(0.1, 0.95, 1.0) if (team == "player" or team == "ally") else Color(1.0, 0.5, 0.1)
	if weapon_type == "shotgun":
		col = Color(0.9, 0.2, 1.0)
	p.color = col
	get_parent().add_child(p)
	p.global_position = global_position
	
	# Impact flash light
	var flash = OmniLight3D.new()
	flash.light_color = col
	flash.light_energy = 4.0
	flash.omni_range = 8.0
	get_parent().add_child(flash)
	flash.global_position = global_position
	
	var tween = create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.22)
	tween.tween_callback(flash.queue_free)
	get_tree().create_timer(0.45).timeout.connect(p.queue_free)
