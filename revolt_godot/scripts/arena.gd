extends Node3D

# Massive Open Industrial Battlefield (No Boxing Ring!)
# An 80m x 80m open facility testing grounds with tactical cargo containers,
# energy generator towers, runway markings, and stadium floodlight towers.

const FIELD_HALF_SIZE = 42.0

func _ready() -> void:
	_build_open_ground()
	_build_tactical_cover()
	_build_floodlight_towers()
	_build_perimeter_boundaries()

func _build_open_ground() -> void:
	var ground_body = StaticBody3D.new()
	var ground_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(FIELD_HALF_SIZE * 2.0, 1.0, FIELD_HALF_SIZE * 2.0)
	ground_mesh.mesh = box
	ground_mesh.position.y = -0.5
	
	# Open Ground Runway PBR Material
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/open_ground.png")
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/floor_normal.png")
	mat.normal_scale = 1.0
	mat.metallic = 0.55
	mat.roughness = 0.45
	mat.uv1_scale = Vector3(1, 1, 1)
	ground_mesh.material_override = mat
	ground_body.add_child(ground_mesh)
	
	# Collision
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(FIELD_HALF_SIZE * 2.0, 1.0, FIELD_HALF_SIZE * 2.0)
	col.shape = col_box
	col.position.y = -0.5
	ground_body.add_child(col)
	add_child(ground_body)

func _build_tactical_cover() -> void:
	# Strategic High-Tech Cargo Containers for human cover against robot fire
	var crate_mat = StandardMaterial3D.new()
	crate_mat.albedo_texture = load("res://assets/crate_albedo.png")
	crate_mat.metallic = 0.75
	crate_mat.roughness = 0.4
	
	var container_positions = [
		[Vector3(-14, 1.3, -12), Vector3(0, 25, 0)],
		[Vector3(-16, 1.3, -8), Vector3(0, -15, 0)],
		[Vector3(15, 1.3, -14), Vector3(0, 40, 0)],
		[Vector3(18, 1.3, -10), Vector3(0, 10, 0)],
		[Vector3(-15, 1.3, 14), Vector3(0, -35, 0)],
		[Vector3(15, 1.3, 14), Vector3(0, 20, 0)],
		[Vector3(-10, 1.3, -24), Vector3(0, 15, 0)],
		[Vector3(10, 1.3, -24), Vector3(0, -15, 0)]
	]
	
	for cfg in container_positions:
		var c_body = StaticBody3D.new()
		c_body.position = cfg[0]
		c_body.rotation_degrees = cfg[1]
		
		var c_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(5.5, 2.6, 2.6)
		c_mesh.mesh = box
		c_mesh.material_override = crate_mat
		c_body.add_child(c_mesh)
		
		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = Vector3(5.5, 2.6, 2.6)
		col.shape = col_box
		c_body.add_child(col)
		
		add_child(c_body)
		
	# Energy Generator Towers (4 corner power pylons with cyan rings)
	var tower_coords = [
		Vector3(-24, 0, -24),
		Vector3(24, 0, -24),
		Vector3(-24, 0, 24),
		Vector3(24, 0, 24)
	]
	
	var tower_mat = StandardMaterial3D.new()
	tower_mat.albedo_color = Color(0.2, 0.24, 0.3)
	tower_mat.metallic = 0.95
	tower_mat.roughness = 0.25
	
	var energy_mat = StandardMaterial3D.new()
	energy_mat.albedo_color = Color(0.0, 0.85, 1.0)
	energy_mat.emission_enabled = true
	energy_mat.emission = Color(0.0, 0.85, 1.0)
	energy_mat.emission_energy_multiplier = 1.6
	
	for pos in tower_coords:
		var t_body = StaticBody3D.new()
		t_body.position = pos
		
		# Base
		var base = MeshInstance3D.new()
		var base_cyl = CylinderMesh.new()
		base_cyl.top_radius = 1.2
		base_cyl.bottom_radius = 1.6
		base_cyl.height = 1.2
		base.mesh = base_cyl
		base.position.y = 0.6
		base.material_override = tower_mat
		t_body.add_child(base)
		
		# Tower shaft
		var shaft = MeshInstance3D.new()
		var shaft_cyl = CylinderMesh.new()
		shaft_cyl.top_radius = 0.7
		shaft_cyl.bottom_radius = 0.9
		shaft_cyl.height = 7.0
		shaft.mesh = shaft_cyl
		shaft.position.y = 4.7
		shaft.material_override = tower_mat
		t_body.add_child(shaft)
		
		# Glowing Energy Ring
		var ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 0.9
		torus.outer_radius = 1.3
		ring.mesh = torus
		ring.position.y = 6.0
		ring.material_override = energy_mat
		t_body.add_child(ring)
		
		# Collision
		var col = CollisionShape3D.new()
		var col_shape = CylinderShape3D.new()
		col_shape.radius = 1.4
		col_shape.height = 8.5
		col.shape = col_shape
		col.position.y = 4.25
		t_body.add_child(col)
		
		add_child(t_body)

func _build_floodlight_towers() -> void:
	# 4 High Stadium Floodlight Towers illuminating the large open field
	var flood_positions = [
		Vector3(-FIELD_HALF_SIZE + 4, 0, -FIELD_HALF_SIZE + 4),
		Vector3(FIELD_HALF_SIZE - 4, 0, -FIELD_HALF_SIZE + 4),
		Vector3(-FIELD_HALF_SIZE + 4, 0, FIELD_HALF_SIZE - 4),
		Vector3(FIELD_HALF_SIZE - 4, 0, FIELD_HALF_SIZE - 4)
	]
	
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.25, 0.28, 0.35)
	steel_mat.metallic = 0.9
	steel_mat.roughness = 0.3
	
	for pos in flood_positions:
		# Pylon
		var pylon = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.4
		cyl.bottom_radius = 0.7
		cyl.height = 16.0
		pylon.mesh = cyl
		pylon.position = pos + Vector3(0, 8.0, 0)
		pylon.material_override = steel_mat
		add_child(pylon)
		
		# Floodlight Spot
		var spot = SpotLight3D.new()
		spot.position = pos + Vector3(0, 16.0, 0)
		add_child(spot)
		spot.look_at(Vector3.ZERO, Vector3.UP)
		spot.spot_range = 65.0
		spot.spot_angle = 58.0
		spot.light_energy = 4.5
		spot.light_color = Color(0.95, 0.97, 1.0)
		spot.shadow_enabled = true
		
	# Center Key Sun Light
	var sun = DirectionalLight3D.new()
	sun.position = Vector3(25, 35, 25)
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.8
	sun.light_color = Color(0.92, 0.95, 1.0)
	sun.shadow_enabled = true
	add_child(sun)

func _build_perimeter_boundaries() -> void:
	# Low concrete security barricades around the 80m perimeter
	var boundary = StaticBody3D.new()
	var wall_dist = FIELD_HALF_SIZE
	var wall_height = 4.0
	
	var bar_mat = StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.25, 0.28, 0.32)
	bar_mat.metallic = 0.6
	bar_mat.roughness = 0.5
	
	var configs = [
		[Vector3(0, wall_height * 0.5, wall_dist), Vector3(FIELD_HALF_SIZE * 2.0, wall_height, 1.2)],
		[Vector3(0, wall_height * 0.5, -wall_dist), Vector3(FIELD_HALF_SIZE * 2.0, wall_height, 1.2)],
		[Vector3(wall_dist, wall_height * 0.5, 0), Vector3(1.2, wall_height, FIELD_HALF_SIZE * 2.0)],
		[Vector3(-wall_dist, wall_height * 0.5, 0), Vector3(1.2, wall_height, FIELD_HALF_SIZE * 2.0)]
	]
	
	for cfg in configs:
		var b_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = cfg[1]
		b_mesh.mesh = box
		b_mesh.position = cfg[0]
		b_mesh.material_override = bar_mat
		boundary.add_child(b_mesh)
		
		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = cfg[1]
		col.shape = col_box
		col.position = cfg[0]
		boundary.add_child(col)
		
	add_child(boundary)
