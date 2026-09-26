extends Node3D

# Realistic Cyberpunk Boxing Ring Arena Generator
# Features PBR diamond plate floor with center insignia, hazard borders,
# authentic red/white/blue wrapped boxing ropes, padded turnbuckles,
# an illuminated background OMEGA ROBOTICS billboard, and overhead stadium truss lighting.

const RING_HALF_SIZE = 18.0

func _ready() -> void:
	_build_floor()
	_build_corner_posts()
	_build_ring_ropes()
	_build_industrial_surroundings()
	_build_stadium_lighting()

func _build_floor() -> void:
	var floor_body = StaticBody3D.new()
	var floor_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(RING_HALF_SIZE * 2.0, 1.0, RING_HALF_SIZE * 2.0)
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.5
	
	# High-Res Industrial Steel PBR Material
	var mat = StandardMaterial3D.new()
	var albedo_tex = load("res://assets/floor_albedo.png")
	var normal_tex = load("res://assets/floor_normal.png")
	
	mat.albedo_texture = albedo_tex
	mat.normal_enabled = true
	mat.normal_texture = normal_tex
	mat.normal_scale = 1.4
	mat.metallic = 0.8
	mat.roughness = 0.28
	mat.uv1_scale = Vector3(1, 1, 1)
	floor_mesh.material_override = mat
	floor_body.add_child(floor_mesh)
	
	# Collision
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(RING_HALF_SIZE * 2.0, 1.0, RING_HALF_SIZE * 2.0)
	col.shape = col_box
	col.position.y = -0.5
	floor_body.add_child(col)
	add_child(floor_body)
	
	# Ring Side Steel Apron
	var skirt = MeshInstance3D.new()
	var skirt_box = BoxMesh.new()
	skirt_box.size = Vector3(RING_HALF_SIZE * 2.15, 1.2, RING_HALF_SIZE * 2.15)
	skirt.mesh = skirt_box
	skirt.position.y = -1.1
	var skirt_mat = StandardMaterial3D.new()
	skirt_mat.albedo_color = Color(0.18, 0.2, 0.24)
	skirt_mat.metallic = 0.95
	skirt_mat.roughness = 0.35
	skirt.material_override = skirt_mat
	add_child(skirt)

func _build_corner_posts() -> void:
	var corner_coords = [
		Vector3(RING_HALF_SIZE, 0, RING_HALF_SIZE),
		Vector3(-RING_HALF_SIZE, 0, RING_HALF_SIZE),
		Vector3(RING_HALF_SIZE, 0, -RING_HALF_SIZE),
		Vector3(-RING_HALF_SIZE, 0, -RING_HALF_SIZE)
	]
	
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.28, 0.3, 0.35)
	steel_mat.metallic = 0.96
	steel_mat.roughness = 0.2
	
	for i in range(4):
		var pos = corner_coords[i]
		var post_body = StaticBody3D.new()
		post_body.position = pos
		
		# Steel Pedestal Base
		var base = MeshInstance3D.new()
		var base_mesh = CylinderMesh.new()
		base_mesh.top_radius = 1.0
		base_mesh.bottom_radius = 1.4
		base_mesh.height = 0.8
		base.mesh = base_mesh
		base.position.y = 0.4
		base.material_override = steel_mat
		post_body.add_child(base)
		
		# Upright Pylon
		var shaft = MeshInstance3D.new()
		var shaft_mesh = CylinderMesh.new()
		shaft_mesh.top_radius = 0.45
		shaft_mesh.bottom_radius = 0.55
		shaft_mesh.height = 5.5
		shaft.mesh = shaft_mesh
		shaft.position.y = 3.2
		shaft.material_override = steel_mat
		post_body.add_child(shaft)
		
		# Boxing Ring Padded Turnbuckle Cushion
		var pad = MeshInstance3D.new()
		var pad_mesh = BoxMesh.new()
		pad_mesh.size = Vector3(1.0, 4.2, 1.0)
		pad.mesh = pad_mesh
		pad.position.y = 3.0
		var pad_mat = StandardMaterial3D.new()
		var pad_col = Color(0.0, 0.5, 0.95) if i == 0 else Color(0.9, 0.15, 0.15)
		pad_mat.albedo_color = pad_col
		pad_mat.roughness = 0.5
		pad.material_override = pad_mat
		post_body.add_child(pad)
		
		# Corner Beacon Light
		var beacon = MeshInstance3D.new()
		var beacon_mesh = SphereMesh.new()
		beacon_mesh.radius = 0.35
		beacon_mesh.height = 0.7
		beacon.mesh = beacon_mesh
		beacon.position.y = 6.2
		var beacon_mat = StandardMaterial3D.new()
		beacon_mat.albedo_color = pad_col
		beacon_mat.emission_enabled = true
		beacon_mat.emission = pad_col
		beacon_mat.emission_energy_multiplier = 1.2
		beacon.material_override = beacon_mat
		post_body.add_child(beacon)
		
		# Collision
		var col = CollisionShape3D.new()
		var col_shape = CylinderShape3D.new()
		col_shape.radius = 1.0
		col_shape.height = 6.0
		col.shape = col_shape
		col.position.y = 3.0
		post_body.add_child(col)
		
		add_child(post_body)

func _build_ring_ropes() -> void:
	# Authentic Boxing Ring Wrapped Ropes (Top: Red, Middle: White/Silver, Bottom: Blue)
	var rope_configs = [
		{"height": 3.8, "color": Color(0.85, 0.15, 0.15)}, # Top Red Rope
		{"height": 2.5, "color": Color(0.9, 0.92, 0.95)},  # Middle White/Silver Rope
		{"height": 1.2, "color": Color(0.12, 0.35, 0.85)}  # Bottom Blue Rope
	]
	
	for cfg in rope_configs:
		var h = cfg["height"]
		var rope_mat = StandardMaterial3D.new()
		rope_mat.albedo_color = cfg["color"]
		rope_mat.roughness = 0.35
		rope_mat.metallic = 0.4
		
		var segments = [
			[Vector3(-RING_HALF_SIZE, h, -RING_HALF_SIZE), Vector3(RING_HALF_SIZE, h, -RING_HALF_SIZE)],
			[Vector3(RING_HALF_SIZE, h, -RING_HALF_SIZE), Vector3(RING_HALF_SIZE, h, RING_HALF_SIZE)],
			[Vector3(RING_HALF_SIZE, h, RING_HALF_SIZE), Vector3(-RING_HALF_SIZE, h, RING_HALF_SIZE)],
			[Vector3(-RING_HALF_SIZE, h, RING_HALF_SIZE), Vector3(-RING_HALF_SIZE, h, -RING_HALF_SIZE)]
		]
		
		for seg in segments:
			var rope = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.08
			cyl.bottom_radius = 0.08
			cyl.height = RING_HALF_SIZE * 2.0
			rope.mesh = cyl
			var mid = (seg[0] + seg[1]) * 0.5
			rope.position = mid
			
			if abs(seg[0].x - seg[1].x) > 0.1:
				rope.rotation_degrees = Vector3(0, 0, 90)
			else:
				rope.rotation_degrees = Vector3(90, 0, 0)
				
			rope.material_override = rope_mat
			add_child(rope)
			
	_build_boundary_colliders()

func _build_boundary_colliders() -> void:
	var boundary = StaticBody3D.new()
	var wall_dist = RING_HALF_SIZE + 0.5
	var wall_height = 8.0
	
	var wall_configs = [
		[Vector3(0, wall_height * 0.5, wall_dist), Vector3(RING_HALF_SIZE * 2.2, wall_height, 1.0)],
		[Vector3(0, wall_height * 0.5, -wall_dist), Vector3(RING_HALF_SIZE * 2.2, wall_height, 1.0)],
		[Vector3(wall_dist, wall_height * 0.5, 0), Vector3(1.0, wall_height, RING_HALF_SIZE * 2.2)],
		[Vector3(-wall_dist, wall_height * 0.5, 0), Vector3(1.0, wall_height, RING_HALF_SIZE * 2.2)]
	]
	
	for cfg in wall_configs:
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = cfg[1]
		col.shape = box
		col.position = cfg[0]
		boundary.add_child(col)
		
	add_child(boundary)

func _build_industrial_surroundings() -> void:
	var outer_mat = StandardMaterial3D.new()
	outer_mat.albedo_color = Color(0.2, 0.23, 0.28)
	outer_mat.metallic = 0.75
	outer_mat.roughness = 0.45
	
	var dist = 30.0
	var h = 18.0
	var w = 68.0
	var wall_offsets = [
		Vector3(0, h * 0.5, dist),
		Vector3(0, h * 0.5, -dist),
		Vector3(dist, h * 0.5, 0),
		Vector3(-dist, h * 0.5, 0)
	]
	
	for i in range(4):
		var wall = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		if i < 2:
			mesh.size = Vector3(w, h, 2.0)
		else:
			mesh.size = Vector3(2.0, h, w)
		wall.mesh = mesh
		wall.position = wall_offsets[i]
		wall.material_override = outer_mat
		add_child(wall)
		
	# Illuminated Far Billboard Sign ("OMEGA ROBOTICS // SECTOR 01")
	var sign_mesh = MeshInstance3D.new()
	var s_quad = QuadMesh.new()
	s_quad.size = Vector2(24.0, 6.0)
	sign_mesh.mesh = s_quad
	sign_mesh.position = Vector3(0, 10.0, -28.5)
	
	var sign_mat = StandardMaterial3D.new()
	sign_mat.albedo_texture = load("res://assets/sign_omega.png")
	sign_mat.emission_enabled = true
	sign_mat.emission_texture = load("res://assets/sign_omega.png")
	sign_mat.emission_energy_multiplier = 0.9
	sign_mesh.material_override = sign_mat
	add_child(sign_mesh)
	
	# Overhead Steel Trusses / Gantry
	for z_pos in [-12.0, 0.0, 12.0]:
		var beam = MeshInstance3D.new()
		var beam_mesh = BoxMesh.new()
		beam_mesh.size = Vector3(54.0, 1.2, 1.2)
		beam.mesh = beam_mesh
		beam.position = Vector3(0, 14.0, z_pos)
		beam.material_override = outer_mat
		add_child(beam)

func _build_stadium_lighting() -> void:
	# 1. Main Overhead Center Floodlight
	var center_spot = SpotLight3D.new()
	center_spot.position = Vector3(0, 16.0, 0)
	center_spot.rotation_degrees = Vector3(-90, 0, 0)
	center_spot.spot_range = 32.0
	center_spot.spot_angle = 70.0
	center_spot.light_energy = 5.5
	center_spot.light_color = Color(1.0, 0.98, 0.95)
	center_spot.shadow_enabled = true
	add_child(center_spot)
	
	# 2. 4 Corner Stadium Cross-Floodlights (angled down into boxing ring)
	var corners = [
		Vector3(20, 15, 20),
		Vector3(-20, 15, 20),
		Vector3(20, 15, -20),
		Vector3(-20, 15, -20)
	]
	
	for pos in corners:
		var spot = SpotLight3D.new()
		spot.position = pos
		add_child(spot)
		spot.look_at(Vector3.ZERO, Vector3.UP)
		spot.spot_range = 38.0
		spot.spot_angle = 50.0
		spot.light_energy = 3.2
		spot.light_color = Color(0.95, 0.96, 1.0)
		spot.shadow_enabled = true
		
	# 3. 4 Warm Amber Industrial Wall Lamps (light up warehouse surroundings)
	var wall_lamp_positions = [
		Vector3(0, 8.0, -27.0),
		Vector3(0, 8.0, 27.0),
		Vector3(-27.0, 8.0, 0),
		Vector3(27.0, 8.0, 0)
	]
	
	for lamp_pos in wall_lamp_positions:
		var lamp = OmniLight3D.new()
		lamp.position = lamp_pos
		lamp.light_color = Color(1.0, 0.7, 0.3)
		lamp.light_energy = 3.5
		lamp.omni_range = 28.0
		add_child(lamp)
		
	# 4. Sun Key Light
	var sun = DirectionalLight3D.new()
	sun.position = Vector3(15, 25, 15)
	sun.rotation_degrees = Vector3(-55, 40, 0)
	sun.light_energy = 1.8
	sun.light_color = Color(0.9, 0.95, 1.0)
	sun.shadow_enabled = true
	add_child(sun)
