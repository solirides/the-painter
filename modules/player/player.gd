extends RigidBody3D


@export_category("Player Movement")
@export var mouse_sensitivity:float = 0.16
@export var fov:float = 80.0
@export var dynamic_fov:float = 12.0
@export var dynamic_fov_min:float = 6.0
@export var roll_sensitivity:float = 2
@export var camera_sway:float = 2
@export var lean_scale:float = 0.005
@export var lean_angle:float = 0.04
@export var lean_speed:float = 10
@export var movement_speed:float = 7
#export var max_speed = 14
#export var acceleration_speed = 1000
#@export var deceleration_speed = 0.1
@export var drag:float = 0.1
@export var ground_drag:float = 0.1
@export var speed_cap:float = 10
@export var gravity:float = 9.8
@export var jump_speed:float = 6.0
@export var hold_strength:float = 10.0
@export var fly:bool = false

@export_category("Player Properties")
@export var max_health = 100

@export_category("Nodes")
@export var camera_yaw:Node
@export var camera_pitch:Node
@export var camera_lean:Node
@export var camera:Node
@export var feet_collision:Node
#@export var jump_cooldown:Node
#@export var sway_timer:Node
@export var raycast:Node
@export var mobile_raycast:Node
@export var anim_player:Node
@export var anim_tree:Node
#@export var hold_position:Node
@export var hands:Node
@export var hud:Node
@export var current_hand_item:Node
@export var hand_items:Array[Node]

var health = 100
var last_damage_time = 0
var speed_multiplier:float = 1.0
var jump_ready = true

enum CameraMode {
	STANDARD,
	DAMPED,
	LOCKED
}

var camera_mode = CameraMode.STANDARD

signal primary(state)
signal secondary(state)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#anim_player.play("walk_bob",-1,1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		print(Input.mouse_mode)
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("toggle_perspective"):
		if camera.position.z != 0:
			camera.position.z = 0
		else:
			camera.position.z = 5
	
	if Input.is_action_just_pressed("primary"):
		primary.emit("down")
		if current_hand_item is HandItem:
			current_hand_item.primary_down(self)
	
	if Input.is_action_just_released("primary"):
		primary.emit("up")
		if current_hand_item is HandItem:
			current_hand_item.primary_up(self)
		
	if Input.is_action_just_pressed("secondary"):
		secondary.emit("down")
		if current_hand_item is HandItem:
			current_hand_item.secondary_down(self)
		
	if Input.is_action_just_released("secondary"):
		secondary.emit("up")
		if current_hand_item is HandItem:
			current_hand_item.secondary_up(self)
	
	if Input.is_action_just_pressed("item_1"):
		switch_hand_item(0)
		
	elif Input.is_action_just_pressed("item_2"):
		switch_hand_item(1)
		
	
	#var fov_logistic = logistic((linear_velocity.length() - dynamic_fov_min), 4, 9.0, 1.0)
	#var new_fov = fov + max(0, fov_logistic * dynamic_fov)
	#print(new_fov)
	#camera.fov = lerp(camera.fov, new_fov, delta * 20)

func _physics_process(delta: float) -> void:
	var now = Time.get_ticks_msec()
	
	# handle movement
	var direction = Vector3.ZERO
	direction.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction = direction.normalized()
	var velocity = camera_yaw.global_transform.basis * direction * movement_speed * speed_multiplier
	velocity = (2 - linear_velocity.normalized().dot(velocity.normalized())) * velocity # bhop
	velocity = max(speed_cap - linear_velocity.length(), 1) * velocity
	
	self.apply_central_force(velocity * self.mass)
	
	# animate leaning
	if (true):
		var lean_dir = -self.linear_velocity.cross(self.global_transform.basis.y).normalized()
		#print(lean_dir)
		var current_rot = camera_lean.global_transform.basis
	#	var target_rot = Quaternion(Basis.looking_at(lean_dir, self.global_transform.basis.y)).normalized()
		var target_rot:Basis
		if lean_dir == Vector3.ZERO:
			target_rot = camera_pitch.global_transform.basis
		else:
			target_rot = camera_pitch.global_transform.basis.rotated(lean_dir, clamp(linear_velocity.length() * lean_scale, -lean_angle, lean_angle))
		var smooth_rot = current_rot.orthonormalized().slerp(target_rot.orthonormalized(), delta * lean_speed)
		camera_lean.global_transform.basis = smooth_rot
	
	#camera.rotation.slerp(Vector3(0,0,0), delta * 10)
	# correct camera rotation
	#camera.rotation.z = lerp_angle(camera.rotation.z, 0.0, delta * 10)
	#camera.rotation.y = lerp_angle(camera.rotation.y, 0.0, delta * 10)
	#camera.rotation.x = lerp_angle(camera.rotation.z, 0.0, delta * 10)
	
	
	
	#if held_object != null and held_object is RigidBody3D:
		#var force = hold_strength * held_object.mass * (hold_position.global_position - held_object.global_position)
		#held_object.apply_central_force(force)
		#print(force)
	
	var time_diff = now - last_damage_time
	var heal_start = 1000.0
	var heal_base = 1.1
	if time_diff > heal_start:
		var heal_amount = pow(heal_base, time_diff / 1000.0) - pow(heal_base, heal_start / 1000.0)
		heal(clamp(heal_amount, 0, 1) * delta)
	
	
	#anim_player.speed_scale = Vector2(linear_velocity.x, linear_velocity.z).length() * 0.4
	var horizontal_speed = Vector2(linear_velocity.x, linear_velocity.z).length()
	anim_tree.set("parameters/TimeScale/scale", horizontal_speed * 0.4)
	anim_tree.set("parameters/Blend2/blend_amount", (1 - pow(1.4,-horizontal_speed)) * 0.4)
	#print(anim_tree.get_property_list())
	


func _integrate_forces(state):
	
	state.apply_central_force(Vector3.DOWN * mass * gravity)
	
	for i in state.get_contact_count():
		var normal = state.get_contact_local_normal(i)
		if normal.dot(Vector3.UP) > 0.8 and normal.dot(Vector3.UP) < 1: # if on a slanted surface
			var fix = false
			
			for axis in [Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1)]:
				if abs(linear_velocity.dot(axis)) < 0.4 and normal.dot(axis) > 0:
					#print(-normal.dot(axis) * mass * gravity * axis)
					
					#print(state.linear_velocity)
					#state.linear_velocity = state.linear_velocity * (Vector3.ONE - axis) + \
						#lerp((state.linear_velocity * axis).length(), 0.0, 1.0) * axis
					#state.linear_velocity = state.linear_velocity * (Vector3.ONE - axis)
					#print(state.linear_velocity)
					
					#state.apply_central_force(-normal.dot(axis) * mass * gravity * axis)
					
					state.linear_velocity -= state.linear_velocity.dot(axis) * axis
					
					fix = true
			
			#state.linear_velocity -= state.linear_velocity.dot(Vector3.UP) * Vector3.UP
			
			if fix:
				#apply_central_force(mass * gravity * (1 + normal.dot(Vector3.DOWN)) * Vector3.UP)
				state.apply_central_force(Vector3.UP * mass * gravity * 1.0)
	
	
		#if is_on_ground and !jumped:
	state.linear_velocity.x = lerp(state.linear_velocity.x,0.0,drag)
	#state.linear_velocity.y = lerp(state.linear_velocity.y,0.0,ground_drag)
	state.linear_velocity.z = lerp(state.linear_velocity.z,0.0,drag)
	

func _input(event):
	if event is InputEventMouseMotion:
		match camera_mode:
			CameraMode.STANDARD:
				# yaw
				camera_yaw.rotate_y(deg_to_rad(-event.screen_relative.x * mouse_sensitivity))
				# pitch
				camera_pitch.rotate_x(deg_to_rad(-event.screen_relative.y * mouse_sensitivity))
				camera_pitch.rotation.x = clamp(camera_pitch.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			CameraMode.DAMPED:
				var damping = 0.1
				camera_yaw.rotate_y(deg_to_rad(-event.screen_relative.x * mouse_sensitivity * damping))
				# pitch
				camera_pitch.rotate_x(deg_to_rad(-event.screen_relative.y * mouse_sensitivity * damping))
				camera_pitch.rotation.x = clamp(camera_pitch.rotation.x, deg_to_rad(-90), deg_to_rad(90))
				#print("damp")
			_:
				pass


func _on_jump_cooldown_timeout():
	jump_ready = true

func damage(amount:float):
	health -= amount
	last_damage_time = Time.get_ticks_msec()

func heal(amount:float):
	health = min(health + amount, max_health)

func exponential(x:float, b:float, a:float, c:float, d:float, min:float, max:float) -> float:
	return clamp(pow(b, a*x - c) - pow(b, d*x - c), min, max)

func logistic(x:float, b:float, c:float, k:float) -> float:
	return 1.0 / (1.0 + c * pow(b, -k * x))

func switch_hand_item(idx):
	current_hand_item = hand_items[idx]
	for item in hand_items:
		item.visible = false
	hand_items[idx].visible = true
