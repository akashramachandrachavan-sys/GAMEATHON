extends Node3D

# High-Tech Cyber Proving Ground & Military Testing Sector
# 84m x 84m open combat facility with asphalt runway markings, blast barrier walls,
# tactical multi-level cargo containers, energy power pylons, and stadium floodlight towers.

const FIELD_HALF_SIZE = 44.0

func _ready() -> void:
	_build_open_ground()
	_build_tactical_cover()
	_build_floodlight_towers()
	_build_blast_barrier_perimeter()

func _build_open_ground() -> void:
	var ground_body = StaticBody3D.new()
	var ground_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(FIELD_HALF_SIZE * 2.0, 1.0, FIELD_HALF_SIZE * 2.0)
	ground_mesh.mesh = box
	ground_mesh.position.y = -0.5
	
	# High-Resolution Cyber Runway Ground Material
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/cyber_ground.png")
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/floor_normal.png")
	mat.normal_scale = 1.0
	mat.metallic = 0.65
	mat.roughness = 0.35
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
	var crate_mat = StandardMaterial3D.new()
	crate_mat.albedo_texture = load("res://assets/crate_albedo.png")
	crate_mat.metallic = 0.8
	crate_mat.roughness = 0.35
	
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_texture = load("res://assets/blast_wall.png")
	wall_mat.metallic = 0.85
	wall_mat.roughness = 0.30
	
	# Multi-level container stacks (providing high ground and cover)
	var container_positions = [
		# Left flank defense bunker
		[Vector3(-15, 1.3, -12), Vector3(0, 25, 0), Vector3(5.5, 2.6, 2.6)],
		[Vector3(-18, 1.3, -8), Vector3(0, -15, 0), Vector3(5.5, 2.6, 2.6)],
		[Vector3(-16.5, 3.8, -10), Vector3(0, 5, 0), Vector3(5.0, 2.4, 2.4)], # Stacked top
		
		# Right flank defense bunker
		[Vector3(15, 1.3, -14), Vector3(0, 40, 0), Vector3(5.5, 2.6, 2.6)],
		[Vector3(18, 1.3, -10), Vector3(0, 10, 0), Vector3(5.5, 2.6, 2.6)],
		[Vector3(16.5, 3.8, -12), Vector3(0, 25, 0), Vector3(5.0, 2.4, 2.4)], # Stacked top
		
		# Rear tactical cover
		[Vector3(-15, 1.3, 14), Vector3(0, -35, 0), Vector3(5.5, 2.6, 2.6)],
		[Vector3(15, 1.3, 14), Vector3(0, 20, 0), Vector3(5.5, 2.6, 2.6)],
		
		# Mid-field blast barriers
		[Vector3(-10, 1.3, -24), Vector3(0, 15, 0), Vector3(6.0, 2.6, 2.6)],
		[Vector3(10, 1.3, -24), Vector3(0, -15, 0), Vector3(6.0, 2.6, 2.6)]
	]
	
	for cfg in container_positions:
		var c_body = StaticBody3D.new()
		c_body.position = cfg[0]
		c_body.rotation_degrees = cfg[1]
		
		var c_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = cfg[2]
		c_mesh.mesh = box
		c_mesh.material_override = crate_mat
		c_body.add_child(c_mesh)
		
		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = cfg[2]
		col.shape = col_box
		c_body.add_child(col)
		add_child(c_body)
		
	# Low concrete blast barrier walls for ducking / crouching
	var barrier_coords = [
		[Vector3(0, 0.9, -16), Vector3(0, 0, 0), Vector3(7.0, 1.8, 0.8)],
		[Vector3(-8, 0.9, 0), Vector3(0, 45, 0), Vector3(5.0, 1.8, 0.8)],
		[Vector3(8, 0.9, 0), Vector3(0, -45, 0), Vector3(5.0, 1.8, 0.8)]
	]
	for b_cfg in barrier_coords:
		var b_body = StaticBody3D.new()
		b_body.position = b_cfg[0]
		b_body.rotation_degrees = b_cfg[1]
		
		var b_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = b_cfg[2]
		b_mesh.mesh = box
		b_mesh.material_override = wall_mat
		b_body.add_child(b_mesh)
		
		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = b_cfg[2]
		col.shape = col_box
		b_body.add_child(col)
		add_child(b_body)
		
	# Energy Generator Towers (4 corner power pylons with cyan rings)
	var tower_coords = [
		Vector3(-26, 0, -26),
		Vector3(26, 0, -26),
		Vector3(-26, 0, 26),
		Vector3(26, 0, 26)
	]
	
	var tower_mat = StandardMaterial3D.new()
	tower_mat.albedo_color = Color(0.2, 0.24, 0.3)
	tower_mat.metallic = 0.95
	tower_mat.roughness = 0.25
	
	var energy_mat = StandardMaterial3D.new()
	energy_mat.albedo_color = Color(0.0, 0.9, 1.0)
	energy_mat.emission_enabled = true
	energy_mat.emission = Color(0.0, 0.9, 1.0)
	energy_mat.emission_energy_multiplier = 2.5
	
	for pos in tower_coords:
		var t_body = StaticBody3D.new()
		t_body.position = pos
		
		var base = MeshInstance3D.new()
		var base_cyl = CylinderMesh.new()
		base_cyl.top_radius = 1.3
		base_cyl.bottom_radius = 1.8
		base_cyl.height = 1.4
		base.mesh = base_cyl
		base.position.y = 0.7
		base.material_override = tower_mat
		t_body.add_child(base)
		
		var shaft = MeshInstance3D.new()
		var shaft_cyl = CylinderMesh.new()
		shaft_cyl.top_radius = 0.75
		shaft_cyl.bottom_radius = 0.95
		shaft_cyl.height = 10.0
		shaft.mesh = shaft_cyl
		shaft.position.y = 5.8
		shaft.material_override = tower_mat
		t_body.add_child(shaft)
		
		# Glowing Energy Rings
		for y_ring in [3.8, 6.8, 9.8]:
			var ring = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = 0.85
			torus.outer_radius = 1.25
			ring.mesh = torus
			ring.position.y = y_ring
			ring.material_override = energy_mat
			t_body.add_child(ring)
			
		var col = CollisionShape3D.new()
		var col_cyl = CylinderShape3D.new()
		col_cyl.radius = 1.4
		col_cyl.height = 11.0
		col.shape = col_cyl
		col.position.y = 5.5
		t_body.add_child(col)
		add_child(t_body)

func _build_floodlight_towers() -> void:
	var light_pos = [
		Vector3(-FIELD_HALF_SIZE + 5, 0, -FIELD_HALF_SIZE + 5),
		Vector3(FIELD_HALF_SIZE - 5, 0, -FIELD_HALF_SIZE + 5),
		Vector3(-FIELD_HALF_SIZE + 5, 0, FIELD_HALF_SIZE - 5),
		Vector3(FIELD_HALF_SIZE - 5, 0, FIELD_HALF_SIZE - 5)
	]
	
	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.18, 0.20, 0.24)
	pole_mat.metallic = 0.9
	pole_mat.roughness = 0.25
	
	var lamp_mat = StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(0.9, 0.95, 1.0)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(0.9, 0.95, 1.0)
	lamp_mat.emission_energy_multiplier = 4.0
	
	for pos in light_pos:
		var pole_body = StaticBody3D.new()
		pole_body.position = pos
		
		var pole = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.35
		p_cyl.bottom_radius = 0.45
		p_cyl.height = 18.0
		pole.mesh = p_cyl
		pole.position.y = 9.0
		pole.material_override = pole_mat
		pole_body.add_child(pole)
		
		# Lamp gantry head
		var head = MeshInstance3D.new()
		var h_box = BoxMesh.new()
		h_box.size = Vector3(2.5, 0.6, 1.2)
		head.mesh = h_box
		head.position = Vector3(0, 18.0, 0)
		head.material_override = lamp_mat
		pole_body.add_child(head)
		
		# Powerful Stadium Floodlight casting dramatic shadow cones
		var spot = SpotLight3D.new()
		spot.light_color = Color(0.85, 0.92, 1.0)
		spot.light_energy = 8.5
		spot.spot_range = 65.0
		spot.spot_angle = 50.0
		spot.position = Vector3(0, 18.0, 0)
		var angle_y = rad_to_deg(atan2(-pos.x, -pos.z))
		spot.rotation_degrees = Vector3(-45.0, angle_y, 0)
		pole_body.add_child(spot)
		
		var col = CollisionShape3D.new()
		var col_cyl = CylinderShape3D.new()
		col_cyl.radius = 0.6
		col_cyl.height = 18.0
		col.shape = col_cyl
		col.position.y = 9.0
		pole_body.add_child(col)
		add_child(pole_body)

func _build_blast_barrier_perimeter() -> void:
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_texture = load("res://assets/blast_wall.png")
	wall_mat.metallic = 0.9
	wall_mat.roughness = 0.3
	wall_mat.uv1_scale = Vector3(12, 1, 1)
	
	var beacon_mat = StandardMaterial3D.new()
	beacon_mat.albedo_color = Color(1.0, 0.1, 0.1)
	beacon_mat.emission_enabled = true
	beacon_mat.emission = Color(1.0, 0.1, 0.1)
	beacon_mat.emission_energy_multiplier = 3.5
	
	var half = FIELD_HALF_SIZE
	var wall_data = [
		[Vector3(0, 2.5, -half), Vector3(half * 2.0, 5.0, 1.2)],
		[Vector3(0, 2.5, half), Vector3(half * 2.0, 5.0, 1.2)],
		[Vector3(-half, 2.5, 0), Vector3(1.2, 5.0, half * 2.0)],
		[Vector3(half, 2.5, 0), Vector3(1.2, 5.0, half * 2.0)]
	]
	
	for w in wall_data:
		var w_body = StaticBody3D.new()
		w_body.position = w[0]
		
		var mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = w[1]
		mesh.mesh = box
		mesh.material_override = wall_mat
		w_body.add_child(mesh)
		
		# Red Security Strobe Beacons on wall top
		for bx in [-20.0, 0.0, 20.0]:
			var beacon = MeshInstance3D.new()
			var b_cyl = CylinderMesh.new()
			b_cyl.top_radius = 0.15
			b_cyl.bottom_radius = 0.18
			b_cyl.height = 0.4
			beacon.mesh = b_cyl
			beacon.position = Vector3(bx, 2.7, 0) if w[1].x > w[1].z else Vector3(0, 2.7, bx)
			beacon.material_override = beacon_mat
			w_body.add_child(beacon)
		
		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = w[1]
		col.shape = col_box
		w_body.add_child(col)
		add_child(w_body)
