extends Node2D

# @export var player: Node2D
@export var cam: Camera2D
@export var vp: SubViewport

func _process(_delta: float) -> void:
    # vp.canvas_transform.origin = -player.global_position - Vector2(240, 240)
    vp.canvas_transform = cam.get_canvas_transform()
    # var t := Transform2D()
    # vp.canvas_transform = t
    # vp_cam.global_position = player.global_position
