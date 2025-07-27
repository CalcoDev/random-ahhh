class_name WobblyLine2D
extends Line2D

var normal_pushback_range: Vector2
var point_wander_range: Vector2
var point_wander_time_range: Vector2
var point_wander_speed_range: Vector2

var _info: Array[Dictionary] = []

func _process(delta: float) -> void:
    if not Engine.is_editor_hint():
        _process_wobblyness(delta)

func init_wobblyness(offset: bool) -> void:
    clear_points()
    for info in _info:
        add_point(info["base_pos"] + info["normal"] * (-2 + (int(offset) * _rand_range(normal_pushback_range))))
        info["wander_timer"] = 0.0
        info["wander_speed"] = _rand_range(point_wander_speed_range)
        info["target_pos"] = info["base_pos"]
    add_point(points[0])

func _process_wobblyness(delta: float) -> void:
    for i in _info.size():
        var info := _info[i]
        info["wander_timer"] += delta
        if info["wander_timer"] > _rand_range(point_wander_time_range):
            info["wander_timer"] = 0.0
            info["wander_speed"] = _rand_range(point_wander_speed_range)
            info["target_pos"] = info["base_pos"] + _rand_vec2() * _rand_range(point_wander_range)
        points[i] = points[i].lerp(info["target_pos"], delta * info["wander_speed"])
    points[points.size() - 1] = points[0]

@warning_ignore("shadowed_global_identifier")
func _rand_range(range: Vector2) -> float:
    return randf_range(range.x, range.y)

func _rand_vec2() -> Vector2:
    var angle := randf() * TAU
    return Vector2(cos(angle), sin(angle))