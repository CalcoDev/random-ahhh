@tool
extends Node2D

@export var do_the_thing: bool = false:
    set(value):
        rect.material.set_shader_parameter("u_negative_texture", vp.get_texture())
        print("Tried thinging.")
        value = false

@export var rect: ColorRect
@export var vp: SubViewport