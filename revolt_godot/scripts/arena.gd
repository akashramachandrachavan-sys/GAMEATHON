extends Node3D

# Expanded Cyber Proving Grounds (150m x 150m) & 2150 Robot-Era Metropolis
# Features:
# 1. Massive 150m x 150m open combat arena with multi-level tactical container bunkers.
# 2. Photorealistic Cyberpunk 2150 Metropolis background:
#    - Towering megastructure skyscrapers (80m to 240m tall) with illuminated window grids.
#    - Giant 40-meter holographic billboards (Sterling Robotics & Omega-Zero Alert).
#    - Illuminated sky-bridges spanning across buildings.
#    - Rooftop communication masts with blinking red aviation warning beacons.
#    - Industrial refinery towers and power conduits.

const FIELD_HALF_SIZE = 75.0

func _ready() -> void:
	_build_open_ground()
	_build_tactical_cover()
	_build_energy_pylons()
	_build_floodlight_towers()
	_build_blast_barrier_perimeter()
	_build_cyberpunk_metropolis_background()

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
	mat.uv1_scale = Vector3(1.8, 1.8, 1.8)
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
	
	# Expansive Metropolis Foundation Ground (extending 650m beneath outer city skyline)
	var outer_ground = MeshInstance3D.new()
	var outer_box = BoxMesh.new()
	outer_box.size = Vector3(650.0, 1.0, 650.0)
	outer_ground.mesh = outer_box
	outer_ground.position.y = -0.7
	var outer_mat = StandardMaterial3D.new()
	outer_mat.albedo_color = Color(0.05, 0.07, 0.10)
	outer_mat.metallic = 0.85
	outer_mat.roughness = 0.35
	outer_ground.material_override = outer_mat
	add_child(outer_ground)

func _build_tactical_cover() -> void:
	var crate_mat = StandardMaterial3D.new()
	crate_mat.albedo_texture = load("res://assets/crate_albedo.png")
	crate_mat.metallic = 0.8
	crate_mat.roughness = 0.35
	
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_texture = load("res://assets/blast_wall.png")
	wall_mat.metallic = 0.85
	wall_mat.roughness = 0.30
	
	# Multi-level container complexes distributed across the 150m arena
	var container_positions = [
		# Left flank defense bunker (West)
		[Vector3(-26, 1.3, -22), Vector3(0, 25, 0), Vector3(6.5, 2.6, 2.8)],
		[Vector3(-31, 1.3, -16), Vector3(0, -15, 0), Vector3(6.5, 2.6, 2.8)],
		[Vector3(-28.5, 3.8, -19), Vector3(0, 5, 0), Vector3(6.0, 2.4, 2.6)], # Stacked tier 2
		[Vector3(-38, 1.3, -8), Vector3(0, 45, 0), Vector3(6.5, 2.6, 2.8)],
		
		# Right flank defense bunker (East)
		[Vector3(26, 1.3, -22), Vector3(0, -25, 0), Vector3(6.5, 2.6, 2.8)],
		[Vector3(31, 1.3, -16), Vector3(0, 15, 0), Vector3(6.5, 2.6, 2.8)],
		[Vector3(28.5, 3.8, -19), Vector3(0, -5, 0), Vector3(6.0, 2.4, 2.6)], # Stacked tier 2
		[Vector3(38, 1.3, -8), Vector3(0, -45, 0), Vector3(6.5, 2.6, 2.8)],
		
		# North advance staging area
		[Vector3(-18, 1.3, -42), Vector3(0, 15, 0), Vector3(7.0, 2.6, 2.8)],
		[Vector3(18, 1.3, -42), Vector3(0, -15, 0), Vector3(7.0, 2.6, 2.8)],
		[Vector3(0, 1.3, -48), Vector3(0, 90, 0), Vector3(6.5, 2.6, 2.8)],
		[Vector3(0, 3.8, -48), Vector3(0, 90, 0), Vector3(6.0, 2.4, 2.6)], # Stacked
		
		# South staging area (Near player spawn)
		[Vector3(-22, 1.3, 24), Vector3(0, -30, 0), Vector3(6.5, 2.6, 2.8)],
		[Vector3(22, 1.3, 24), Vector3(0, 30, 0), Vector3(6.5, 2.6, 2.8)],
		[Vector3(-14, 1.3, 38), Vector3(0, 10, 0), Vector3(6.5, 2.6, 2.8)],
		[Vector3(14, 1.3, 38), Vector3(0, -10, 0), Vector3(6.5, 2.6, 2.8)],
		
		# Central proving plaza cover pods
		[Vector3(-12, 1.3, -6), Vector3(0, 40, 0), Vector3(5.5, 2.6, 2.6)],
		[Vector3(12, 1.3, -6), Vector3(0, -40, 0), Vector3(5.5, 2.6, 2.6)]
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
		[Vector3(0, 0.9, -24), Vector3(0, 0, 0), Vector3(10.0, 1.8, 0.9)],
		[Vector3(-16, 0.9, 8), Vector3(0, 45, 0), Vector3(7.0, 1.8, 0.9)],
		[Vector3(16, 0.9, 8), Vector3(0, -45, 0), Vector3(7.0, 1.8, 0.9)],
		[Vector3(0, 0.9, 14), Vector3(0, 0, 0), Vector3(8.0, 1.8, 0.9)]
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

func _build_energy_pylons() -> void:
	var tower_coords = [
		Vector3(-46, 0, -46),
		Vector3(46, 0, -46),
		Vector3(-46, 0, 46),
		Vector3(46, 0, 46)
	]
	
	var tower_mat = StandardMaterial3D.new()
	tower_mat.albedo_color = Color(0.2, 0.24, 0.3)
	tower_mat.metallic = 0.95
	tower_mat.roughness = 0.25
	
	var energy_mat = StandardMaterial3D.new()
	energy_mat.albedo_color = Color(0.0, 0.9, 1.0)
	energy_mat.emission_enabled = true
	energy_mat.emission = Color(0.0, 0.9, 1.0)
	energy_mat.emission_energy_multiplier = 2.8
	
	for pos in tower_coords:
		var t_body = StaticBody3D.new()
		t_body.position = pos
		
		var base = MeshInstance3D.new()
		var base_cyl = CylinderMesh.new()
		base_cyl.top_radius = 1.5
		base_cyl.bottom_radius = 2.0
		base_cyl.height = 1.6
		base.mesh = base_cyl
		base.position.y = 0.8
		base.material_override = tower_mat
		t_body.add_child(base)
		
		var shaft = MeshInstance3D.new()
		var shaft_cyl = CylinderMesh.new()
		shaft_cyl.top_radius = 0.85
		shaft_cyl.bottom_radius = 1.1
		shaft_cyl.height = 12.0
		shaft.mesh = shaft_cyl
		shaft.position.y = 6.8
		shaft.material_override = tower_mat
		t_body.add_child(shaft)
		
		# Glowing Energy Rings
		for y_ring in [4.2, 7.8, 11.2]:
			var ring = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = 0.95
			torus.outer_radius = 1.4
			ring.mesh = torus
			ring.position.y = y_ring
			ring.material_override = energy_mat
			t_body.add_child(ring)
			
		var col = CollisionShape3D.new()
		var col_cyl = CylinderShape3D.new()
		col_cyl.radius = 1.5
		col_cyl.height = 13.0
		col.shape = col_cyl
		col.position.y = 6.5
		t_body.add_child(col)
		add_child(t_body)

func _build_floodlight_towers() -> void:
	var light_pos = [
		Vector3(-FIELD_HALF_SIZE + 8, 0, -FIELD_HALF_SIZE + 8),
		Vector3(FIELD_HALF_SIZE - 8, 0, -FIELD_HALF_SIZE + 8),
		Vector3(-FIELD_HALF_SIZE + 8, 0, FIELD_HALF_SIZE - 8),
		Vector3(FIELD_HALF_SIZE - 8, 0, FIELD_HALF_SIZE - 8),
		Vector3(0, 0, -FIELD_HALF_SIZE + 6),
		Vector3(0, 0, FIELD_HALF_SIZE - 6)
	]
	
	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.18, 0.20, 0.24)
	pole_mat.metallic = 0.9
	pole_mat.roughness = 0.25
	
	var lamp_mat = StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(0.9, 0.95, 1.0)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(0.9, 0.95, 1.0)
	lamp_mat.emission_energy_multiplier = 4.5
	
	for pos in light_pos:
		var pole_body = StaticBody3D.new()
		pole_body.position = pos
		
		var pole = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.4
		p_cyl.bottom_radius = 0.55
		p_cyl.height = 22.0
		pole.mesh = p_cyl
		pole.position.y = 11.0
		pole.material_override = pole_mat
		pole_body.add_child(pole)
		
		var head = MeshInstance3D.new()
		var h_box = BoxMesh.new()
		h_box.size = Vector3(3.2, 0.8, 1.4)
		head.mesh = h_box
		head.position = Vector3(0, 22.0, 0)
		head.material_override = lamp_mat
		pole_body.add_child(head)
		
		var spot = SpotLight3D.new()
		spot.light_color = Color(0.88, 0.94, 1.0)
		spot.light_energy = 9.0
		spot.spot_range = 95.0
		spot.spot_angle = 55.0
		spot.position = Vector3(0, 22.0, 0)
		var angle_y = rad_to_deg(atan2(-pos.x, -pos.z))
		spot.rotation_degrees = Vector3(-42.0, angle_y, 0)
		pole_body.add_child(spot)
		
		var col = CollisionShape3D.new()
		var col_cyl = CylinderShape3D.new()
		col_cyl.radius = 0.7
		col_cyl.height = 22.0
		col.shape = col_cyl
		col.position.y = 11.0
		pole_body.add_child(col)
		add_child(pole_body)

func _build_blast_barrier_perimeter() -> void:
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_texture = load("res://assets/blast_wall.png")
	wall_mat.metallic = 0.9
	wall_mat.roughness = 0.3
	wall_mat.uv1_scale = Vector3(20, 1, 1)
	
	var beacon_mat = StandardMaterial3D.new()
	beacon_mat.albedo_color = Color(1.0, 0.1, 0.1)
	beacon_mat.emission_enabled = true
	beacon_mat.emission = Color(1.0, 0.1, 0.1)
	beacon_mat.emission_energy_multiplier = 3.5
	
	var half = FIELD_HALF_SIZE
	var wall_data = [
		[Vector3(0, 3.0, -half), Vector3(half * 2.0, 6.0, 1.4)],
		[Vector3(0, 3.0, half), Vector3(half * 2.0, 6.0, 1.4)],
		[Vector3(-half, 3.0, 0), Vector3(1.4, 6.0, half * 2.0)],
		[Vector3(half, 3.0, 0), Vector3(1.4, 6.0, half * 2.0)]
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
		
		# Red Security Strobe Beacons along the wall tops
		for bx in [-50.0, -25.0, 0.0, 25.0, 50.0]:
			var beacon = MeshInstance3D.new()
			var b_cyl = CylinderMesh.new()
			b_cyl.top_radius = 0.16
			b_cyl.bottom_radius = 0.20
			b_cyl.height = 0.45
			beacon.mesh = b_cyl
			beacon.position = Vector3(bx, 3.2, 0) if w[1].x > w[1].z else Vector3(0, 3.2, bx)
			beacon.material_override = beacon_mat
			w_body.add_child(beacon)
		
		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = w[1]
		col.shape = col_box
		w_body.add_child(col)
		add_child(w_body)

# Photorealistic Cyberpunk 2150 Metropolis Skyline
func _build_cyberpunk_metropolis_background() -> void:
	var bldg_node = Node3D.new()
	bldg_node.name = "CyberpunkMetropolis"
	add_child(bldg_node)
	
	# PBR Materials for Futuristic Skyscrapers
	var facade1_mat = StandardMaterial3D.new()
	facade1_mat.albedo_texture = load("res://assets/building_facade_1.png")
	facade1_mat.emission_enabled = true
	facade1_mat.emission_texture = load("res://assets/building_facade_1.png")
	facade1_mat.emission_energy_multiplier = 1.4
	facade1_mat.metallic = 0.85
	facade1_mat.roughness = 0.25
	facade1_mat.uv1_scale = Vector3(1, 4, 1)
	
	var facade2_mat = StandardMaterial3D.new()
	facade2_mat.albedo_texture = load("res://assets/building_facade_2.png")
	facade2_mat.emission_enabled = true
	facade2_mat.emission_texture = load("res://assets/building_facade_2.png")
	facade2_mat.emission_energy_multiplier = 1.2
	facade2_mat.metallic = 0.90
	facade2_mat.roughness = 0.30
	facade2_mat.uv1_scale = Vector3(1, 3, 1)
	
	# Unshaded Holographic Billboards (Vibrant, high-contrast digital neon)
	var holo1_mat = StandardMaterial3D.new()
	holo1_mat.albedo_texture = load("res://assets/holo_billboard_1.png")
	holo1_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	holo1_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	var holo2_mat = StandardMaterial3D.new()
	holo2_mat.albedo_texture = load("res://assets/holo_billboard_2.png")
	holo2_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	holo2_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	var beacon_red = StandardMaterial3D.new()
	beacon_red.albedo_color = Color(1.0, 0.1, 0.1)
	beacon_red.emission_enabled = true
	beacon_red.emission = Color(1.0, 0.1, 0.1)
	beacon_red.emission_energy_multiplier = 6.0
	
	var neon_cyan = StandardMaterial3D.new()
	neon_cyan.albedo_color = Color(0.0, 0.95, 1.0)
	neon_cyan.emission_enabled = true
	neon_cyan.emission = Color(0.0, 0.95, 1.0)
	neon_cyan.emission_energy_multiplier = 5.0
	
	var neon_amber = StandardMaterial3D.new()
	neon_amber.albedo_color = Color(1.0, 0.65, 0.05)
	neon_amber.emission_enabled = true
	neon_amber.emission = Color(1.0, 0.65, 0.05)
	neon_amber.emission_energy_multiplier = 4.5

	# 1. Inner Skyline Ring (Distance 105m to 145m from center)
	# Structured for an open cinematic vista down the center runway
	var inner_buildings = [
		# North Horizon (Behind Titan Boss spawn) - Twin Corporate Citadels flanking center
		{"pos": Vector3(-44, 65, -125), "size": Vector3(40, 130, 36), "mat": facade1_mat, "spire": true, "ad": holo1_mat, "ad_face": "south"},
		{"pos": Vector3(44, 65, -125), "size": Vector3(40, 130, 36), "mat": facade2_mat, "spire": true, "ad": holo2_mat, "ad_face": "south"},
		{"pos": Vector3(0, 105, -185), "size": Vector3(50, 210, 48), "mat": facade1_mat, "spire": true}, # Massive deep central spire
		{"pos": Vector3(-88, 52, -115), "size": Vector3(36, 104, 34), "mat": facade2_mat},
		{"pos": Vector3(88, 52, -115), "size": Vector3(36, 104, 34), "mat": facade1_mat},
		
		# East Horizon
		{"pos": Vector3(115, 55, -75), "size": Vector3(36, 110, 34), "mat": facade1_mat},
		{"pos": Vector3(135, 75, 0), "size": Vector3(44, 150, 42), "mat": facade2_mat, "spire": true, "ad": holo2_mat, "ad_face": "west"},
		{"pos": Vector3(118, 50, 75), "size": Vector3(34, 100, 32), "mat": facade1_mat},
		
		# South Horizon (Behind Kai spawn)
		{"pos": Vector3(52, 45, 120), "size": Vector3(34, 90, 34), "mat": facade2_mat},
		{"pos": Vector3(0, 60, 135), "size": Vector3(46, 120, 40), "mat": facade1_mat, "spire": true, "ad": holo1_mat, "ad_face": "north"},
		{"pos": Vector3(-52, 48, 120), "size": Vector3(36, 96, 34), "mat": facade1_mat},
		
		# West Horizon
		{"pos": Vector3(-118, 50, 75), "size": Vector3(34, 100, 34), "mat": facade1_mat},
		{"pos": Vector3(-135, 75, 0), "size": Vector3(44, 150, 44), "mat": facade1_mat, "spire": true, "ad": holo1_mat, "ad_face": "east"},
		{"pos": Vector3(-115, 54, -75), "size": Vector3(38, 108, 36), "mat": facade2_mat}
	]
	
	for b in inner_buildings:
		var b_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = b["size"]
		b_mesh.mesh = box
		b_mesh.position = b["pos"]
		b_mesh.material_override = b["mat"]
		bldg_node.add_child(b_mesh)
		
		var half_h = b["size"].y * 0.5
		
		# Vertical Neon Accent Strips along building facade edges
		var strip_l = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.5, b["size"].y * 0.9, 0.5)
		strip_l.mesh = s_box
		strip_l.position = b["pos"] + Vector3(-b["size"].x * 0.48, 0, b["size"].z * 0.48)
		strip_l.material_override = neon_cyan
		bldg_node.add_child(strip_l)
		
		var strip_r = MeshInstance3D.new()
		strip_r.mesh = s_box
		strip_r.position = b["pos"] + Vector3(b["size"].x * 0.48, 0, b["size"].z * 0.48)
		strip_r.material_override = neon_amber
		bldg_node.add_child(strip_r)
		
		# Rooftop Communications Spire & Aviation Beacon
		if b.get("spire", false):
			var spire = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.2
			cyl.bottom_radius = 1.0
			cyl.height = 26.0
			spire.mesh = cyl
			spire.position = b["pos"] + Vector3(0, half_h + 13.0, 0)
			spire.material_override = facade2_mat
			bldg_node.add_child(spire)
			
			var beacon = MeshInstance3D.new()
			var b_sph = SphereMesh.new()
			b_sph.radius = 1.0
			b_sph.height = 2.0
			beacon.mesh = b_sph
			beacon.position = b["pos"] + Vector3(0, half_h + 26.5, 0)
			beacon.material_override = beacon_red
			bldg_node.add_child(beacon)
			
		# Giant Holographic Billboard Display
		if b.has("ad"):
			var ad_face = b.get("ad_face", "south")
			var ad_mesh = MeshInstance3D.new()
			var q = QuadMesh.new()
			q.size = Vector2(30.0, 15.0)
			ad_mesh.mesh = q
			ad_mesh.material_override = b["ad"]
			
			var ad_rot_y = 0.0
			var ad_offset = Vector3.ZERO
			match ad_face:
				"south":
					ad_rot_y = 0.0
					ad_offset = Vector3(0, 0, b["size"].z * 0.5 + 0.6)
				"north":
					ad_rot_y = 180.0
					ad_offset = Vector3(0, 0, -(b["size"].z * 0.5 + 0.6))
				"west":
					ad_rot_y = -90.0
					ad_offset = Vector3(-(b["size"].x * 0.5 + 0.6), 0, 0)
				"east":
					ad_rot_y = 90.0
					ad_offset = Vector3(b["size"].x * 0.5 + 0.6, 0, 0)
			
			ad_mesh.rotation_degrees.y = ad_rot_y
			ad_mesh.position = b["pos"] + ad_offset + Vector3(0, -b["size"].y * 0.1, 0)
			bldg_node.add_child(ad_mesh)
			
	# 2. Outer Skyline Ring (Monolithic Cyberpunk Towers at 180m - 260m)
	# Creates rich parallax and city density
	for i in range(18):
		var angle = (float(i) / 18.0) * TAU
		var radius = randf_range(190.0, 250.0)
		var h = randf_range(130.0, 230.0)
		var w = randf_range(38.0, 60.0)
		var d = randf_range(38.0, 60.0)
		
		var outer_bldg = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(w, h, d)
		outer_bldg.mesh = box
		outer_bldg.position = Vector3(cos(angle) * radius, h * 0.5, sin(angle) * radius)
		outer_bldg.material_override = facade1_mat if (i % 2 == 0) else facade2_mat
		bldg_node.add_child(outer_bldg)
		
		# Rooftop red strobe
		var beacon = MeshInstance3D.new()
		var b_sph = SphereMesh.new()
		b_sph.radius = 1.4
		b_sph.height = 2.8
		beacon.mesh = b_sph
		beacon.position = outer_bldg.position + Vector3(0, h * 0.5 + 1.8, 0)
		beacon.material_override = beacon_red
		bldg_node.add_child(beacon)

	# 3. High-Altitude Illuminated Sky-Bridges Connecting Towers
	var skybridges = [
		# Grand Skybridge connecting the North Twin Citadels across the central avenue
		{"pos": Vector3(0, 72, -125), "size": Vector3(50, 7, 8), "rot": Vector3(0, 0, 0)},
		# East Skybridge
		{"pos": Vector3(124, 70, -40), "size": Vector3(12, 6, 52), "rot": Vector3(0, 18, 0)},
		# West Skybridge
		{"pos": Vector3(-124, 70, 40), "size": Vector3(12, 6, 52), "rot": Vector3(0, -18, 0)}
	]
	
	for sb in skybridges:
		var bridge = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = sb["size"]
		bridge.mesh = box
		bridge.position = sb["pos"]
		if sb.has("rot"): bridge.rotation_degrees = sb["rot"]
		bridge.material_override = facade2_mat
		bldg_node.add_child(bridge)
		
		# Glowing transit windows along bridge
		var win = MeshInstance3D.new()
		var w_box = BoxMesh.new()
		w_box.size = Vector3(bridge.mesh.size.x * 0.96, 1.6, bridge.mesh.size.z + 0.3)
		win.mesh = w_box
		win.position = bridge.position
		if sb.has("rot"): win.rotation_degrees = sb["rot"]
		win.material_override = neon_cyan
		bldg_node.add_child(win)

