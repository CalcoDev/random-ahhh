@tool
extends Node2D

@export var do_the_thing: bool = false
@export var _debug_view: ColorRect

@export var stiffnes: float = 70.0
@export var damping: float = 3.0
@export var blur_strength: float = 1.0
@export var max_delta_time: float = 1.0 / 60.0

var _temp_vel_vp: SubViewport

var _vel_blitter_vp: SubViewport
var _vel_blitter_mat: ShaderMaterial

var _vps: Array[SubViewport] = []
var _rects: Array[ColorRect] = []

var _current_idx: int = 0

func _enter_tree() -> void:
    _vel_blitter_vp = %VelocityBlitterPass
    _vel_blitter_mat = _vel_blitter_vp.get_child(0).material

    _temp_vel_vp = %TemporaryVelocityTexture
    
    _vps.assign([%VelocityTextureA, %VelocityTextureB])
    _rects.clear()
    for vp in _vps:
        _rects.append(vp.get_child(0))
    
    _temp_vel_vp.world_2d = get_world_2d()

func _process(delta: float) -> void:
    if not do_the_thing:
        return
    # do_the_thing = false

    var front := _get_front_idx()
    var back := _get_back_idx()

    # simulate step
    _rects[front].visible = true

    # blit temp velocity onto prev velocity
    _vel_blitter_mat.set_shader_parameter("u_temp_velocity_tex", _temp_vel_vp.get_texture())
    _vel_blitter_mat.set_shader_parameter("u_prev_velocity_tex", _vps[back].get_texture())

    var mat := _rects[front].material as ShaderMaterial
    # mat.set_shader_parameter("u_temp_velocity_tex", _temp_vel_vp.get_texture())
    # mat.set_shader_parameter("u_prev_velocity_tex", _vps[back].get_texture())
    mat.set_shader_parameter("u_prev_velocity_tex", _vel_blitter_vp.get_texture())
    mat.set_shader_parameter("u_sim_params", _get_sim_params(delta))
    mat.set_shader_parameter("u_prev_velocity_tex_texel_size", Vector2(1.0 / 240.0, 1.0 / 240.0))

    _rects[back].visible = false

    # _debug_view.texture = _vps[front].get_texture()
    _debug_view.material.set_shader_parameter("u_obtained_tex", _vps[front].get_texture())

    _swap_buffers()

func _get_sim_params(delta: float) -> Vector4:
    delta = min(delta, max_delta_time)
    return Vector4(stiffnes, damping, blur_strength, delta)

func _get_front_idx() -> int:
    return _current_idx

func _get_back_idx() -> int:
    return (_current_idx + 1) % 2

func _swap_buffers() -> void:
    _current_idx = _get_back_idx()