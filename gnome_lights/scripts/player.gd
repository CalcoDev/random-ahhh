extends CharacterBody2D

@export_group("Movement")
@export var max_speed: float = 200.0
@export var acceleration: float = 800.0 * 2.0
@export var deceleration: float = 600.0 * 2.0
@export var turn_speed: float = 900.0 * 2.0

func _ready() -> void:
    $"RoomReparenter".on_enter_room.connect(_handle_on_enter_room)

func _handle_on_enter_room(room: Room) -> void:
    RoomManager.get_instance(self).set_active_room(room)

func _process(_delta: float) -> void:
    pass

var _prev_inp := Vector2.ZERO
func _physics_process(delta: float) -> void:
    var inp := InputManager.data.move_vec
    var body := self

    if not (abs(_prev_inp.x) > 0.0 and abs(_prev_inp.y) > 0.0) and abs(inp.x) > 0.0 and abs(inp.y) > 0.0:
        body.global_position = body.global_position.round()
    if inp.length_squared() > 0.0:
        var curr_dir := body.velocity.normalized()
        var target_dir := inp.normalized()
        var dot := curr_dir.dot(target_dir)
        if abs(dot) < 0.0:
            body.velocity = body.velocity.move_toward(Vector2.ZERO, turn_speed * delta)
        else:
            body.velocity = body.velocity.move_toward(target_dir * max_speed, acceleration * delta)
    else:
        body.velocity = body.velocity.move_toward(Vector2.ZERO, deceleration * delta)
    move_and_slide()

    _prev_inp = inp