extends Node3D
class_name Eye



@export var radius = 0.5 # for calculating paintbrush attack
var particles = preload("res://modules/eye/particles.tscn")
signal eye_damaged(node)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func damage():
	print("damaged")
	eye_damaged.emit(self)
	var instance = particles.instantiate()
	get_tree().get_root().add_child(instance)
	instance.global_position = self.global_position
	instance.emitting = true
	
	self.queue_free()
