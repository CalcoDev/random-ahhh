@tool
extends Node

@export var polygon_vp: SubViewport
@export var polygon_cutout_vp: SubViewport

@export var polygon_cutout: ColorRect

@export var set_materials: bool = false:
    set(value):
        set_materials = false
        if true:
            var mat := polygon_cutout.material as ShaderMaterial
            mat.set_shader_parameter("u_polygon_tex", polygon_vp.get_texture())

func _ready() -> void:
    set_materials = true