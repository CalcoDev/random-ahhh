@tool
extends Node

@export var camera: Camera2D

@export var polygon_vp: SubViewport
@export var polygon_cutout_vp: SubViewport

@export var polygon_cutout: ColorRect

@export var set_materials: bool = false:
    set(value):
        set_materials = false
        if true:
            var mat := polygon_cutout.material as ShaderMaterial
            mat.set_shader_parameter("u_polygon_tex", polygon_vp.get_texture())

func _notification(what: int) -> void:
    if what == NOTIFICATION_ENTER_TREE:
        set_materials = true

func _process(_delta: float) -> void:
    var t := camera.get_canvas_transform()
    polygon_vp.canvas_transform = t
    # polygon_cutout_vp.canvas_transform = t