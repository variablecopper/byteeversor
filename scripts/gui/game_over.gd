extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	$Restart.grab_focus()

func _on_restart_pressed():
	SceneManager.change_scene("res://scenes/maps/episode_1/map_1.tscn")

func _on_title_screen_pressed():
	pass # Replace with function body.

func _on_exit_pressed():
	get_tree().quit()
