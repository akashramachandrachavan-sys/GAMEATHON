extends Node3D

# Generates the Heavy Industrial Cyberpunk Boxing Ring Arena
# Complete with 4 corner hydraulic turnbuckles, glowing containment cables,
# hazard warning borders, elevated steel combat floor, and dynamic arena floodlights.

const RING_HALF_SIZE = 18.0

func _ready() -> void:
	_build_floor()
	_build_corner_posts()
	_build_ring_cables()
	_build_industrial_surroundings()
	_build_lighting()

func _build_floor() -> void:
	# Main combat deck (elevated steel plate)
	var floor_body = StaticBody3D.new()
	var floor_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(RING_HALF_SIZE * 2.0, 1.0, RING_HALF_SIZE * 2.0)
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.5
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.14, 0.17)
	mat.metallic = 0.85
	mat.roughness = 0.35
	mat.rim_enabled = true
	mat.rim = 0.5
	floor_mesh.material_override = mat
	floor_body.add_child(floor_mesh)
	
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(RING_HALF_SIZE * 2.0, 1.0, RING_HALF_SIZE * 2.0)
	col.shape = col_box
	col.position.y = -0.5
	floor_body.add_child(col)
	add_child(floor_body)
	
	# Center ring logo / circle decal
	var center_ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 4.8
	ring_mesh.outer_radius = 5.2
	center_ring.mesh = ring_mesh
	center_ring.position.y = 0.02
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.0, 0.7, 1.0)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.0, 0.8, 1.0)
	ring_mat.emission_energy_multiplier = 3.0
	center_ring.material_override = ring_mat
	add_child(center_ring)
	
	# Hazard warning perimeter border
	_build_hazard_borders()

func _build_hazard_borders() -> void:
	var border_mat = StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.85, 0.7, 0.0)
	border_mat.metallic = 0.7
	border_mat.roughness = 0.4
	border_mat.emission_enabled = true
	border_mat.emission = Color(0.6, 0.45, 0.0)
	border_mat.emission_energy_multiplier = 1.5

	var h = 0.05
	var w = 0.8
	var l = RING_HALF_SIZE * 2.0
	
	var sides = [
		Vector3(0, 0.02, RING_HALF_SIZE - w * 0.5),
		Vector3(0, 0.02, -RING_HALF_SIZE + w * 0.5),
		Vector3(RING_HALF_SIZE - w * 0.5, 0.02, 0),
		Vector3(-RING_HALF_SIZE + w * 0.5, 0.02, 0)
	]
	
	for i in range(4):
		var strip = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		if i < 2:
			mesh.size = Vector3(l, h, w)
		else:
			mesh.size = Vector3(w, h, l)
		strip.mesh = mesh
		strip.position = sides[i]
		strip.material_override = border_mat
		add_child(strip)

func _build_corner_posts() -> void:
	# 4 Heavy hydraulic turnbuckle posts
	var corner_coords = [
		Vector3(RING_HALF_SIZE, 0, RING_HALF_SIZE),
		Vector3(-RING_HALF_SIZE, 0, RING_HALF_SIZE),
		Vector3(RING_HALF_SIZE, 0, -RING_HALF_SIZE),
		Vector3(-RING_HALF_SIZE, 0, -RING_HALF_SIZE)
	]
	
	var post_mat = StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.18, 0.2, 0.24)
	post_mat.metallic = 0.95
	post_mat.roughness = 0.25
	
	for i in range(4):
		var pos = corner_coords[i]
		var post_body = StaticBody3D.new()
		post_body.position = pos
		
		# Base pedestal
		var base = MeshInstance3D.new()
		var base_mesh = CylinderMesh.new()
		base_mesh.top_radius = 1.2
		base_mesh.bottom_radius = 1.6
		base_mesh.height = 1.0
		base.mesh = base_mesh
		base.position.y = 0.5
		base.material_override = post_mat
		post_body.add_child(base)
		
		# Main upright hydraulic shaft
		var shaft = MeshInstance3D.new()
		var shaft_mesh = CylinderMesh.new()
		shaft_mesh.top_radius = 0.6
		shaft_mesh.bottom_radius = 0.7
		shaft_mesh.height = 6.0
		shaft.mesh = shaft_mesh
		shaft.position.y = 3.5
		shaft.material_override = post_mat
		post_body.add_child(shaft)
		
		# Glowing corner status beacon
		var beacon = MeshInstance3D.new()
		var beacon_mesh = SphereMesh.new()
		beacon_mesh.radius = 0.5
		beacon_mesh.height = 1.0
		beacon.mesh = beacon_mesh
		beacon.position.y = 6.8
		var beacon_mat = StandardMaterial3D.new()
		var beacon_color = Color(0.0, 0.85, 1.0) if i == 0 else Color(1.0, 0.15, 0.15)
		beacon_mat.albedo_color = beacon_color
		beacon_mat.emission_enabled = true
		beacon_mat.emission = beacon_color
		beacon_mat.emission_energy_multiplier = 5.0
		beacon.material_override = beacon_mat
		post_body.add_child(beacon)
		
		# Omni light on beacon
		var beacon_light = OmniLight3D.new()
		beacon_light.light_color = beacon_color
		beacon_light.light_energy = 2.5
		beacon_light.omni_range = 10.0
		beacon_light.position.y = 7.0
		post_body.add_child(beacon_light)
		
		# Collision
		var col = CollisionShape3D.new()
		var col_shape = CylinderShape3D.new()
		col_shape.radius = 1.2
		col_shape.height = 7.0
		col.shape = col_shape
		col.position.y = 3.5
		post_body.add_child(col)
		
		add_child(post_body)

func _build_ring_cables() -> void:
	# 3 Heavy glowing laser/steel containment ropes around the boxing ring
	var cable_heights = [1.5, 3.0, 4.5]
	var cable_mat = StandardMaterial3D.new()
	cable_mat.albedo_color = Color(0.0, 0.9, 1.0)
	cable_mat.emission_enabled = true
	cable_mat.emission = Color(0.0, 0.9, 1.0)
	cable_mat.emission_energy_multiplier = 4.0
	
	for h in cable_heights:
		# 4 sides
		var segments = [
			[Vector3(-RING_HALF_SIZE, h, -RING_HALF_SIZE), Vector3(RING_HALF_SIZE, h, -RING_HALF_SIZE)],
			[Vector3(RING_HALF_SIZE, h, -RING_HALF_SIZE), Vector3(RING_HALF_SIZE, h, RING_HALF_SIZE)],
			[Vector3(RING_HALF_SIZE, h, RING_HALF_SIZE), Vector3(-RING_HALF_SIZE, h, RING_HALF_SIZE)],
			[Vector3(-RING_HALF_SIZE, h, RING_HALF_SIZE), Vector3(-RING_HALF_SIZE, h, -RING_HALF_SIZE)]
		]
		
		for seg in segments:
			var cable = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.08
			cyl.bottom_radius = 0.08
			cyl.height = RING_HALF_SIZE * 2.0
			cable.mesh = cyl
			var mid = (seg[0] + seg[1]) * 0.5
			cable.position = mid
			
			if abs(seg[0].x - seg[1].x) > 0.1:
				cable.rotation_degrees = Vector3(0, 0, 90)
			else:
				cable.rotation_degrees = Vector3(90, 0, 0)
				
			cable.material_override = cable_mat
			add_child(cable)
	
	# Arena invisible containment boundary walls (keep robots inside boxing ring)
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
	# Surrounding factory walls, gantry trusses, and ceiling pipes
	var outer_wall_mat = StandardMaterial3D.new()
	outer_wall_mat.albedo_color = Color(0.08, 0.09, 0.11)
	outer_wall_mat.metallic = 0.8
	outer_wall_mat.roughness = 0.6
	
	# 4 Warehouse exterior backdrop walls
	var dist = 32.0
	var h = 18.0
	var w = 70.0
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
		wall.material_override = outer_wall_mat
		add_child(wall)
		
	# Overhead industrial gantry beams
	for z_pos in [-12.0, 0.0, 12.0]:
		var beam = MeshInstance3D.new()
		var beam_mesh = BoxMesh.new()
		beam_mesh.size = Vector3(50.0, 1.2, 1.2)
		beam.mesh = beam_mesh
		beam.position = Vector3(0, 12.0, z_pos)
		beam.material_override = outer_wall_mat
		add_child(beam)

func _build_lighting() -> void:
	# Overhead stadium spotlight pointing down at the ring center
	var spot = SpotLight3D.new()
	spot.position = Vector3(0, 14.0, 0)
	spot.rotation_degrees = Vector3(-90, 0, 0)
	spot.spot_range = 25.0
	spot.spot_angle = 55.0
	spot.light_energy = 5.0
	spot.light_color = Color(0.9, 0.95, 1.0)
	spot.shadow_enabled = true
	add_child(spot)
	
	# Atmospheric directional fill light
	var sun = DirectionalLight3D.new()
	sun.position = Vector3(10, 20, 10)
	sun.rotation_degrees = Vector3(-45, 35, 0)
	sun.light_energy = 1.2
	sun.light_color = Color(0.7, 0.8, 1.0)
	sun.shadow_enabled = true
	add_child(sun)
