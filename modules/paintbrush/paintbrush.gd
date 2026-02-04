extends HandItem



var stroke_material = preload("res://assets/materials/paintbrush_ink.tres")

@export var radius = 0.1
@export var max_stroke_time = 4.0
@export var max_stroke_length = 2.0
@export var min_distance = 1.0
@export var max_distance = 8.0
@export var hit_radius = 20

@export var projection_distance = 4.0
@export var radius_curve:Curve = null
@export var player:Node = null

var canvas_mode = false
var drawing = false

var stroke_start_time = 0
var stroke_length = 0
var last_camera_transform = Transform3D.IDENTITY
var last_projected_point:Vector3 = Vector3.ZERO

var strokes = []
var stroke_points = []
var stroke_meshes = []
var stroke_displays = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if drawing == true \
	#&& Input.is_action_just_pressed("secondary") \
	:
		var current_time = Time.get_ticks_msec()
		var pos = player.camera.project_position(get_viewport().get_visible_rect().size/2, projection_distance)
		if len(strokes[-1]) >= 2:
			stroke_length += strokes[-1][-1].distance_to(strokes[-1][-2])
			#stroke_length += player.camera.global_rotation.angle_to(last_camera_rotation)
		#print(stroke_length)
		#print(get_viewport().get_mouse_position())
		
		if (current_time - stroke_start_time)/1000 > max_stroke_time \
		or stroke_length > max_stroke_length:
			drawing = false
			return
		
		
		var t = 1-pow(1.4,-(current_time - stroke_start_time)/1000.0*3.0)
		var current_radius = radius * radius_curve.sample(t)
		strokes[-1].append(pos)
		
		var tangent = (strokes[-1][-1] - strokes[-1][-2]).normalized()
		var cross = tangent.cross(player.camera.global_transform.basis.z).normalized()
		
		#print(cross)
		#print(tangent)
		#Debug.marker(pos, Color(0.5,0.5,1))
		#Debug.marker(pos+tangent, Color(0.5,1,1))
		#Debug.marker(pos-cross*current_radius, Color(1,1,0.5))
		
		#var points = [stroke_points[-1][-2], stroke_points[-1][-1], pos+radius, stroke_points[-1][-1], pos+radius, pos-radius]
		#var points = [stroke_points[-1][-1], pos+radius, pos-radius, stroke_points[-1][-1], stroke_points[-1][-2], pos+radius]
		var points = [stroke_points[-1][-2], stroke_points[-1][-1], pos+current_radius*cross, stroke_points[-1][-2], pos-current_radius*cross, pos+current_radius*cross]
		#var points2 = [stroke_points[-1][-1], stroke_points[-1][-2], pos+radius]
		
		#stroke_points[-1].append_array([pos+current_radius*cross, pos-current_radius*cross])
		stroke_points[-1].append_array(points)
		
		### MeshTool
		#stroke_meshes[-1].surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		#for point in points:
			#stroke_meshes[-1].surface_add_vertex(point)
			##stroke_meshes[-1].surface_set_tangent()
			##Debug.marker(point, Color(0.5,0.5,0))
		#stroke_meshes[-1].surface_end()
		#
		
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(stroke_points[-1])
		
		## ArrayMesh.
		#var arr_mesh = ArrayMesh.new()
		## Create the Mesh.
		#arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		#stroke_displays[-1].mesh = arr_mesh
		
		# SurfaceTool
		var st = SurfaceTool.new()
		st.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
		st.generate_normals()
		#st.generate_tangents()
		var array_mesh = st.commit()
		
		stroke_displays[-1].mesh = array_mesh
		
		
		#for target in player.enemies:
			#if target == null:
				#pass
			#else:
				#for i in range(len(target.eyes)):
					#if target != null:
						#var eye = target.eyes[i]
		var potential_targets = []
		for eye in get_tree().get_nodes_in_group("eye"):
			var a = get_viewport().get_visible_rect().size / 2
			var b = player.camera.unproject_position(last_projected_point)
			var p = player.camera.unproject_position(eye.global_position)
			var screen_distance = dist(p,a,b)
			var spatial_distance = player.global_position.distance_to(eye.global_position)
			#print(screen_distance)
			# this line below is sketchy but it seems to work which is surprising considering that I just wrote it out in one try
			var cutoff = eye.radius * eye.scale.x / (spatial_distance * 2*sin(player.fov / 2.0)) * get_viewport().get_visible_rect().size.y
			#print(str(screen_distance) + " " + str(cutoff))
			if screen_distance <= hit_radius + cutoff:
				print("potential target hit")
				potential_targets.append(eye)
				#eye.damage()
		
		var target = find_closest_node(player.global_position, potential_targets)
		if target != null:
			var distance = player.global_position.distance_to(target.global_position)
			# if within distance range
			if distance >= min_distance and distance <= max_distance:
				#target.damage()
				print("within range")
				player.mobile_raycast.look_at(target.global_position)
				player.mobile_raycast.force_raycast_update()
				if player.mobile_raycast.is_colliding():
					var object = player.mobile_raycast.get_collider()
					if object.is_in_group("eye"):
						target.damage()
						print("damage eye")
		
		#
		#if player.raycast.is_colliding():
			#var object = player.raycast.get_collider()
			#if object != null:
				#if object.is_in_group("eye"):
					#object.damage()
		#
	
	last_camera_transform = player.camera.global_transform

func secondary_down(player):
	canvas_mode = !canvas_mode
	if canvas_mode == true:
		player.camera_mode = player.CameraMode.DAMPED
		player.speed_multiplier = 0.05
		print("canvas mode")
	elif canvas_mode == false:
		player.camera_mode = player.CameraMode.STANDARD
		player.speed_multiplier = 1
		print("exit canvas mode")
	

func primary_down(player):
	print("draw")
	
	#var array = []
	var pos = player.camera.project_position(get_viewport().get_visible_rect().size/2, projection_distance)
	#array.append_array([pos,pos,pos])
	stroke_points.append([pos,pos,pos])
	strokes.append([pos])
	
	var mesh = ImmediateMesh.new()
	stroke_meshes.append(mesh)
	#mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	##mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	#mesh.surface_add_vertex(pos)
	#mesh.surface_add_vertex(pos+radius)
	#mesh.surface_add_vertex(pos-radius)
	##mesh.surface_add_vertex(Vector3(0,0,3))
	##mesh.surface_add_vertex(Vector3(0,0,4))
	##mesh.surface_add_vertex(Vector3(-1,3,4))
	##mesh.surface_add_vertex(Vector3(2,1,-1))
	##mesh.surface_add_vertex(Vector3(-2,0,0))
	##mesh.surface_add_vertex(Vector3(0,2,1))
	#mesh.surface_end()
	#
	var meshinstance = MeshInstance3D.new()
	stroke_displays.append(meshinstance)
	meshinstance.mesh = stroke_meshes[-1]
	meshinstance.material_override = stroke_material
	get_tree().get_root().add_child(meshinstance)
	##meshinstance.position = player.position
	
	
	last_projected_point = pos
	drawing = true
	stroke_start_time = Time.get_ticks_msec()
	

func primary_up(player):
	drawing = false
	stroke_length = 0

func unequip():
	pass

func equip():
	pass


func dist(p:Vector2, a:Vector2, b:Vector2):
	var ab = b - a
	var ap = p - a
	var result = 0
	
	var t = ab.dot(ap) / ab.length()**2
	
	if t < 0.0:
		#a
		result = (p - a).length()
	elif t > 1.0:
		#b
		result = (p - b).length()
	else:
		#segment
		result = (p - (a + t * ab)).length()
	
	return result
	

func find_closest_node(position:Vector3, candidates:Array) -> Node:
	var closest:Node = null
	var closest_distance:float = INF
	for node:Node in candidates:
		var distance:float = position.distance_squared_to(node.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = node
	return closest
