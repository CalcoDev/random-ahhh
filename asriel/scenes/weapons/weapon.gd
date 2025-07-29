class_name Weapon
extends Node2D

@export var use_cooldown: float = 0.3
@export var hold_downable: bool = true

@export var bullet_prefab: PackedScene

@export var fire_point: Marker2D

@export_group("Shake Settings")
@export var shake_freq: float = 10.0
@export var shake_intensity: float = 5.0
@export var shake_duration: float = 0.09

@export var recoil_intensity_range: Vector2 = Vector2(10, 30)
@export var recoil_shake: float = 10.0
@export var recoil_duration: float = 0.2

@export_group("Bullet Settings")
@export var bullets_per_shot: int = 1
@export var bullet_spread: float = 30.0
@export var bullet_speed_range: Vector2 = Vector2(50, 50)
# @export var bullet_max_spread_range: Vector2 = Vector2(0.0, 45.0)

@export_group("Display")
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
func can_use() -> bool:
    if _use_timer < 0.0:
        return true
    return false

# force a use
func use(params: Dictionary) -> Dictionary:
    var d := {}

    _use_timer = use_cooldown

    if "is_bullet" in params:
        var dir = params["bullet_direction"]

        d["recoil"] = true
        d["recoil_intensity"] = _rand_range(recoil_intensity_range)
        d["recoil_duration"] = recoil_duration
        d["recoil_shake"] = recoil_shake
        d["shake"] = true

        d["sparks"] = true
        d["spark_count"] = 4
        d["spark_pos"] = fire_point.global_position
        d["spark_size"] = Vector2(5, 2)
        d["spark_angle"] = dir.angle()
        d["spark_angle_random"] = randf() * PI / 5.0
        d["spark_speed"] = 500
        d["spark_lifetime"] = 0.25
        
        var bs := []
        for i in bullets_per_shot:
            var b := bullet_prefab.instantiate() as Bullet
            for bbb in bs:
                b.add_collision_exception_with(bbb)
                bbb.add_collision_exception_with(b)
            bs.append(b)
            var angle: float = dir.angle() + deg_to_rad(randf_range(-bullet_spread, bullet_spread))
            if params["is_first_bullet"] and i == 0:
                angle = dir.angle()
            b.rotation = angle
            b.velocity = Vector2(cos(angle), sin(angle)) * _rand_range(bullet_speed_range)
            b.is_player_bullet = true

            params["parent_node"].add_child(b)
            b.global_position = params["position"]

            # vfx.rotation = angle
        
    return d

func _process(delta: float) -> void:
    _use_timer -= delta

@warning_ignore("shadowed_global_identifier")
func _rand_range(range: Vector2) -> float:
    return randf_range(range.x, range.y)