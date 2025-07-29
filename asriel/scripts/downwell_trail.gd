@tool
extends Sprite2D

@export var do_stuff := false:
    set(value):
        do_stuff = value
        _t = 0.0
        RESET = true

@export var RESET := false:
    set(value):
        RESET = false
        for child in get_children():
            child.queue_free()

@export var max_speed := 30.0

@export var trail_spawn_timer := 0.02
@export var trail_last_timer := 0.2

var _t := 0.0

var _prev_pos := Vector2.ZERO

var _vel := Vector2.ZERO
var _angle := 0.0

var override_vel := false
var override_vel_value := Vector2.ZERO

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    self_modulate = Color.TRANSPARENT

func _process(delta: float) -> void:
    if Engine.is_editor_hint() and not do_stuff:
        return
    _vel = (global_position - _prev_pos)
    if override_vel:
        _vel = override_vel_value
    _angle = _vel.angle()
    _prev_pos = global_position
    _t -= delta
    material.set_shader_parameter("u_angle", _angle)
    if _t < 0.0:
        _t = trail_spawn_timer
        var s := _add_trail_sprite()
        var t := s.create_tween()
        t.tween_method(_process_trail.bind(s), 0.0, 1.0, trail_last_timer).set_ease(Tween.EASE_OUT_IN)
        t.tween_callback(s.queue_free)
        t.play()

func _process_trail(p: float, sprite: Sprite2D) -> void:
    var norm_vel := _vel.length_squared() / (max_speed * max_speed)
    var base := Vector2(2.5, 1.2)
    # var stretch := Vector2(3.5, 0.9)
    var stretch = base
    sprite.scale = base.lerp(stretch, norm_vel) * (1.0 - p)

func _add_trail_sprite() -> Sprite2D:
    var s := Sprite2D.new()
    add_child(s)
    s.texture = texture
    s.modulate = modulate
    s.material = material.duplicate()
    s.rotation = _angle
    s.top_level = true
    s.z_index = -1
    s.global_position = global_position
    return s