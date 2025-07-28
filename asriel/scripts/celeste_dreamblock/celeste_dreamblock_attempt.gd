@tool
extends ColorRect

@export var mid: ColorRect
@export var front: ColorRect

@export var force: bool = false:
    set(value):
        force = false

@export var _noise: FastNoiseLite
@export var _ampl: float

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED or what == NOTIFICATION_ENTER_TREE:
        mid.size = self.size
        front.size = self.size
        self.material.set_shader_parameter("u_aspect_ratio", self.size.x / self.size.y)
        mid.material.set_shader_parameter("u_aspect_ratio", self.size.x / self.size.y)
        front.material.set_shader_parameter("u_aspect_ratio", self.size.x / self.size.y)

var t := 0.0
func _process(delta: float) -> void:
    t += delta * 0.5
    var angle := _noise.get_noise_1d(t) * TAU
    var _global_offset = Vector2(cos(angle), sin(angle)) * _ampl * 0.5
    var offset: Vector2 = Vector2.ZERO

    if Engine.is_editor_hint():
        var vp := EditorInterface.get_editor_viewport_2d()
        var transform := vp.global_canvas_transform
        var center := transform.affine_inverse() * (vp.size * 0.5)
        offset = (center - size * 0.5) * 0.001
    # else:
    #     pass

    self.material.set_shader_parameter("u_offset", offset * 0.9 + _global_offset)
    mid.material.set_shader_parameter("u_offset", offset * 0.75 + _global_offset)
    front.material.set_shader_parameter("u_offset", offset * 0.5 + _global_offset)
    # pass