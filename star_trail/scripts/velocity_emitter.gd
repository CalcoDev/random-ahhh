@tool
extends Sprite2D

@export var debug: bool = false

@export var max_speed: float = 100.0

var _prev_pos: Vector2
var _position_delta := Vector2(0, 0)

var _mat: ShaderMaterial

func _enter_tree() -> void:
    _prev_pos = global_position
    _mat = material as ShaderMaterial

var _a := 0.0
func _process(_delta: float) -> void:
    if not Engine.is_editor_hint():
        global_position = Vector2(120, 120) + Vector2(cos(_a), sin(_a)) * 60.0
        _a += _delta * 3.0

    var new_pos := global_position
    _position_delta = new_pos - _prev_pos
    _prev_pos = new_pos

    var position_delta := _position_delta / max_speed
    _mat.set_shader_parameter("u_position_delta", position_delta)
    # print(position_delta)

    if debug:
        if _position_delta.length() > 0.01:
            print(_position_delta / max_speed)
