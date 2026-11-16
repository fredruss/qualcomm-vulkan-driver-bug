extends Node3D
## GPU load for the fault: animated skinned characters, trees and grass with vertex wind, a sun with shadows.
## The camera holds still, so a fault shows as one frame that differs from both its neighbours.

const CROWD := 12
const CHARACTERS := ["Minion", "Warrior", "Rogue", "Mage"]
const CLIPS := ["general/Idle_A", "move/Walking_A"]
const TREES := {"Tree_1_A": 60, "Tree_2_A": 60, "Tree_4_A": 60, "Bush_1_A": 120}
const GRASS := {"Grass_1_A": 3000, "Grass_2_A": 3000}
const CLEARING := Vector2(0, 3)

var _wind := ShaderMaterial.new()

@onready var _camera: Camera3D = $Camera
@onready var _counter: Label = $Counter


func _ready() -> void:
	seed(1)
	_wind.shader = preload("res://wind.gdshader")
	_wind.set_shader_parameter("albedo_texture", preload("res://assets/nature/forest_texture.png"))
	_spawn_crowd()
	for kind in TREES:
		_scatter(kind, TREES[kind], Rect2(-35, -40, 70, 50), 9.0)
	for kind in GRASS:
		_scatter(kind, GRASS[kind], Rect2(-25, -15, 50, 27), 0.0)


func _process(_delta: float) -> void:
	_counter.text = "frame %d  %d fps" % [Engine.get_frames_drawn(), Engine.get_frames_per_second()]


## The characters stand in an arc in front of the camera and face it; half idle, half walk on the spot.
func _spawn_crowd() -> void:
	var libraries := {
		"general": _library("res://assets/animations/Rig_Medium_General.glb"),
		"move": _library("res://assets/animations/Rig_Medium_MovementBasic.glb"),
	}
	var eye := _camera.global_position
	for i in CROWD:
		var model: Node3D = load("res://assets/characters/Skeleton_%s.glb" % CHARACTERS[i % CHARACTERS.size()]).instantiate()
		add_child(model)
		var angle := deg_to_rad(lerpf(-55, 55, i / float(CROWD - 1)))
		var distance := 6.5 + 2.5 * (i % 3)
		model.position = Vector3(eye.x + sin(angle) * distance, 0, eye.z - cos(angle) * distance)
		model.look_at(Vector3(eye.x, 0, eye.z), Vector3.UP, true)
		var player := AnimationPlayer.new()
		model.add_child(player)
		player.root_node = ^".."
		for library_name in libraries:
			player.add_animation_library(library_name, libraries[library_name])
		player.play(CLIPS[i % 2])
		player.seek(randf() * player.current_animation_length)


func _library(path: String) -> AnimationLibrary:
	var scene: Node = load(path).instantiate()
	var library: AnimationLibrary = scene.get_node("AnimationPlayer").get_animation_library("")
	scene.free()
	for clip in library.get_animation_list():
		library.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	return library


## One MultiMesh of a KayKit nature model at random spots in the area, outside the clearing radius.
func _scatter(kind: String, count: int, area: Rect2, clearing: float) -> void:
	var scene: Node = load("res://assets/nature/%s_Color1.gltf" % kind).instantiate()
	var mesh: Mesh = scene.get_child(0).mesh
	scene.free()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = count
	var i := 0
	while i < count:
		var spot := area.position + Vector2(randf(), randf()) * area.size
		if spot.distance_to(CLEARING) < clearing:
			continue
		var basis := Basis(Vector3.UP, randf() * TAU).scaled(Vector3.ONE * randf_range(0.8, 1.3))
		multimesh.set_instance_transform(i, Transform3D(basis, Vector3(spot.x, 0, spot.y)))
		i += 1
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = _wind
	add_child(instance)
