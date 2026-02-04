extends HandItem


var attack_ready = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func primary_down(player):
	if attack_ready:
		print("attack!")
		attack_ready = false
		$AttackCooldown.start()
		
		var object = player.raycast.get_collider()
		if object != null:
			print("collide!")
			if object.is_in_group("eye"):
				print("hit!")
				object.damage()
			elif object.is_in_group("enemy"):
				print("knockback!")
				object.apply_central_impulse((object.global_position - player.global_position).normalized() * 10)

func _on_cooldown_timeout() -> void:
	attack_ready = true
	
