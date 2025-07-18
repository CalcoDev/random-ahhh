extends Node2D

# @onready var viewport: SubViewport = $"../SubViewportContainer/SubViewport"
# @onready var shd: ShaderMaterial = $"../SubViewportContainer/SubViewport/Color".material

@export var front: SubViewport
@export var back: SubViewport

var front_shd: ShaderMaterial
var back_shd: ShaderMaterial

var idx: int = 0
var vps: Array[SubViewport]
var shds: Array[ShaderMaterial]

var size := 10.0
var prev_mouse := Vector2.ZERO
var prev_draw_frame := -1

func _ready() -> void:
    front_shd = front.get_child(0).material
    back_shd = back.get_child(0).material

    vps = [front, back]
    shds = [front_shd, back_shd]

func _process(_delta: float) -> void:
    @warning_ignore("shadowed_variable_base_class")
    var draw := Input.get_axis("undraw", "draw")
 
    var do_draw: bool = abs(draw) >= 0.01

    var dsize := \
        (1 if Input.is_action_just_released("size_up") else 0) - \
        (1 if Input.is_action_just_released("size_down") else 0)
    size += dsize
    # size = clampf(size, 100, 0)

    var mouse = get_local_mouse_position()
    # if mouse.distance_squared_to(prev_mouse) > size * size:
    #     if Engine.get_frames_drawn()  prev_draw_frame


    if do_draw:
        var oppidx = (idx + 1) % 2
        vps[idx].get_child(0).visible = true
        vps[oppidx].get_child(0).visible = false

        shds[idx].set_shader_parameter("u_draw_col", Color.WHITE if draw < 0.01 else Color.BLACK)

        shds[idx].set_shader_parameter("u_prev_tex", vps[oppidx].get_texture())
        shds[oppidx].set_shader_parameter("u_prev_tex", null)

        shds[idx].set_shader_parameter("u_pos", mouse / 240.0)
        shds[idx].set_shader_parameter("u_size", size)
        idx = (idx + 1) % 2
        # await RenderingServer.frame_post_draw
