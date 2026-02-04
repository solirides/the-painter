extends Node


func load_level(scene:String):
	get_tree().change_scene_to_file(scene)
	
