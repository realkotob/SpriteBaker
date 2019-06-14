tool
extends SplitContainer

const Tools: Script = preload("tools.gd")

const PlayIcon: Texture = preload("res://addons/sprite-baker/icons/play.svg")
const PauseIcon: Texture = preload("res://addons/sprite-baker/icons/pause.svg")
const LoopIcon: Texture = preload("res://addons/sprite-baker/icons/loop.svg")
const LoopActiveIcon: Texture = preload("res://addons/sprite-baker/icons/loop_active.svg")

export(NodePath) var pixel_density_path: NodePath
export(NodePath) var root_motion_dialog_path: NodePath
export(NodePath) var root_motion_clear_path: NodePath
export(NodePath) var root_motion_path: NodePath
export(NodePath) var timeline_path: NodePath
export(NodePath) var play_path: NodePath
export(NodePath) var stop_path: NodePath
export(NodePath) var time_spin_path: NodePath
export(NodePath) var loop_path: NodePath

onready var root_motion_clear: Button = get_node(root_motion_clear_path)
onready var root_motion: Button = get_node(root_motion_path)
onready var timeline: Container = get_node(timeline_path)
onready var play: Button = get_node(play_path)
onready var stop: Button = get_node(stop_path)
onready var time_spin: SpinBox = get_node(time_spin_path)
onready var loop: Button = get_node(loop_path)

var anim_player: AnimationPlayer
var current_animation: String = ""


func update_model(model: Spatial) -> void:
	anim_player = Tools.find_single_node_by_type("AnimationPlayer", model)
	if current_animation != "":
		stop_animation(true)


func clear_model() -> void:
	current_animation = ""
	anim_player = null
	stop_animation(true)
	timeline.clear()


func get_animation(anim_name: String) -> Animation:
	return anim_player.get_animation(anim_name)


func play_animation(anim_name: String) -> void:
	if Tools.is_node_being_edited(self):
		return
	current_animation = anim_name
	var anim: Animation = anim_player.get_animation(anim_name)
	timeline.play_animation(anim.length, anim.loop)
	play.disabled = false
	play.icon = PauseIcon
	stop.disabled = false
	time_spin.editable = true
	time_spin.value = 0.0
	time_spin.max_value = timeline.anim_length
	loop.disabled = false
	if anim.loop:
		loop.icon = LoopActiveIcon
		loop.pressed = true
	else:
		loop.icon = LoopIcon
		loop.pressed = false


func stop_animation(back_to_rest: bool) -> void:
	current_animation = ""
	timeline.stop_animation(back_to_rest)
	if back_to_rest:
		play.disabled = true
		play.icon = PlayIcon
		stop.disabled = true
		time_spin.editable = false
		time_spin.value = 0.0
		loop.pressed = false
		loop.disabled = true
		loop.icon = LoopIcon


func reset_animation() -> void:
	timeline.reset_animation()
	time_spin.value = 0.0


func set_animation_loop(anim_name: String, value: bool) -> void:
	anim_player.get_animation(anim_name).loop = value
	if anim_name == current_animation:
		timeline.looping = value
		if value:
			loop.icon = LoopActiveIcon
			loop.pressed = true
		else:
			loop.icon = LoopIcon
			loop.pressed = false


func _on_SpriteView_pixel_density_changed(value: float) -> void:
	get_node(pixel_density_path).value = value


func _on_RootMotion_pressed() -> void:
	get_node(root_motion_dialog_path).popup_centered(Vector2(340, 500))


func _on_BonesTree_root_motion_selected(root_path: String, id: int) -> void:
	root_motion_clear.disabled = false
	for node in get_tree().get_nodes_in_group("3D2SS.ModelAnimation"):
		node.reset_animation()
	for node in get_tree().get_nodes_in_group("3D2SS.Model"):
		node.set_root_motion_track(root_path, id)


func _on_RootMotionClear_pressed() -> void:
	root_motion_clear.disabled = true
	root_motion.text = "Assign..."
	root_motion.icon = null
	for node in get_tree().get_nodes_in_group("3D2SS.Model"):
		node.clear_root_motion_track()


func _on_Timeline_time_changed(time) -> void:
	time_spin.value = time


func _on_Time_value_changed(value: float) -> void:
	timeline.set_time(value)


func _on_Play_pressed() -> void:
	if timeline.paused:
		timeline.resume_animation()
		play.icon = PauseIcon
	else:
		timeline.pause_animation()
		play.icon = PlayIcon


func _on_Stop_pressed() -> void:
	for node in get_tree().get_nodes_in_group("3D2SS.ModelAnimation"):
		node.stop_animation(true)
	for node in get_tree().get_nodes_in_group("3D2SS.ModelData"):
		if node.name == "AnimationsTree":
			node.stop_item_playing()
			break


func _on_Loop_toggled(button_pressed: bool) -> void:
	if current_animation != "":
		for node in get_tree().get_nodes_in_group("3D2SS.ModelAnimation"):
			node.set_animation_loop(current_animation, button_pressed)
		for node in get_tree().get_nodes_in_group("3D2SS.ModelData"):
			if node.name == "AnimationsTree":
				node.set_item_playing_looping(button_pressed)


func _on_Timeline_animation_finished() -> void:
	play.icon = PlayIcon