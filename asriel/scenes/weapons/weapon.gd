class_name Weapon
extends Node2D

@export var use_cooldown: float = 0.3
@export var hold_downable: bool = true

@export var hold_position_min: Vector2 = Vector2.ZERO
@export var hold_position_offset: Vector2 = Vector2.ZERO
# true -> moves left and right but rotates around itself
# false -> rotates arond player
@export var rotate_pivot_self: bool = false

@export var bob_freq: float = 2.0
@export var bob_strength: float = 6.0

@export var bob_rot_freq: float = 2.0
@export var bob_rot_strength: float = 45.0

@export var bob_vel_delay: float = 2.0

var _use_timer: float = 0.0

# try to use, accounting for use timer
func try_use() -> bool:
    if _use_timer < 0.0:
        use()
        return true
    return false

# force a use
func use() -> void:
    print("used!")
    _use_timer = use_cooldown

func _process(delta: float) -> void:
    _use_timer -= delta