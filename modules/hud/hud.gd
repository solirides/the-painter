extends Control


@export var player:Node = null
@export var label:Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	label.text = ""
	#var properties = player.get_property_list()
	for key in ["health", "position"]:
		var value = player.get(key)
		if value != null:
			label.text += str(value) + "\n"
		#if properties.has_key(key):
			#label.text += properties[key] + "\n"
	
	queue_redraw()
	

func _draw():
	for eye in get_tree().get_nodes_in_group("eye"):
		var spatial_distance = player.global_position.distance_to(eye.global_position)
		var cutoff = eye.radius * eye.scale.x / (spatial_distance * 2*sin(player.fov / 2.0))
		draw_circle(get_viewport().get_visible_rect().size / 2.0, cutoff * get_viewport().get_visible_rect().size.y, Color(0,1,1), false)
		#print(cutoff)
