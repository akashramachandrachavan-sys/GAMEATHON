extends Node2D

var score = 0

func _ready():
	print("IEEE Gameathon Godot project initialized successfully!")

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
