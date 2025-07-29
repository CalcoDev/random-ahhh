class_name Spark

var position := Vector2.ZERO
var size := Vector2.ONE
var angle := 0.0
var speed := 0.0

var lifetime := 2.0
var _t := 0.0

@warning_ignore("shadowed_variable")
func _init(position: Vector2 = Vector2.ZERO, size: Vector2 = Vector2.ONE, angle: float = 0.0, speed: float = 0.0, lifetime: float = 2.0):
    self.position = position
    self.size = size
    self.angle = angle
    self.speed = speed
    self.lifetime = lifetime

func process(delta: float) -> void:
    var curr_speed := lerpf(speed, 0.0, _t / lifetime)
    _t += delta
    
    position.x += cos(angle) * curr_speed * delta
    position.y += sin(angle) * curr_speed * delta

func _get_lifetime() -> float:
    return _t / lifetime

func _get_progress() -> float:
    return clampf(1.0 - pow(_get_lifetime(), 1.3), 0.0, 1.0)

func should_die() -> bool:
    return _t > lifetime