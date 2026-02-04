extends RigidBody3D



@export var target:Node = null

@export var damage_curve:Curve = null
@export var damage_scale:float = 50
@export var drag:float = 0.1
@export var speed_cap:float = 10
@export var movement_speed:float = 3

@export var raycast:Node = null
@export var eyes:Array[Node] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if len(players) > 0:
		target = players[0]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if target == null:
		return
	
	var direction = (target.global_position - self.global_position).normalized()
	#direction = Vector3(1,1,1).normalized()
	#print(direction)
	#var a = atan2(direction.x, direction.z)
	#print(a)
	#$Head.rotation.y = PI + a
	$Head.look_at(target.global_position)
	
	var velocity = direction * movement_speed
	velocity = (2 - linear_velocity.normalized().dot(velocity.normalized())) * velocity
	velocity = max(speed_cap - linear_velocity.length(), 1) * velocity
	self.apply_central_force(velocity * self.mass)
	#self.apply_central_force(direction * 1000)
	
	raycast.look_at(target.global_position)
	
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var object = raycast.get_collider()
		if object.is_in_group("player"):
			#print("icu")
			var dist = (raycast.get_collision_point() - raycast.global_position).length()
			var damage = damage_curve.sample(dist) * damage_scale * delta
			target.damage(damage)
			#print(damage)

func _integrate_forces(state):
	state.linear_velocity.x = lerp(state.linear_velocity.x,0.0,drag)
	#state.linear_velocity.y = lerp(state.linear_velocity.y,0.0,ground_drag)
	state.linear_velocity.z = lerp(state.linear_velocity.z,0.0,drag)

func _on_eye_damaged(node: Variant) -> void:
	self.eyes.erase(node)
	
	var count = 0
	for eye in eyes:
		if eye != null:
			count += 1
	if count == 0:
		self.queue_free()
