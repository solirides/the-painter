extends Node
#class_name Debugs

var marker_scene = preload("res://modules/debug/marker.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func marker(pos:Vector3, color := Color(1,0,1)):
	var instance = marker_scene.instantiate()
	instance.position = pos
	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.ShadingMode.SHADING_MODE_UNSHADED
	material.albedo_color = color
	instance.material_override = material
	#instance.material_override.albedo_color = color
	get_tree().get_root().add_child(instance)
