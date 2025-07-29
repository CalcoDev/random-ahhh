class_name Bullet
extends CharacterBody2D

@export var trail: Node2D

var is_player_bullet := false

var v := Vector2.ZERO
func _ready() -> void:
    v = velocity
    trail.max_speed = v.length()
    trail.override_vel = true
    trail.override_vel_value = v

func _physics_process(_delta: float) -> void:
    trail.override_vel_value = v
    velocity = v
    move_and_slide()
    if get_slide_collision_count() > 0:
        var coll := get_last_slide_collision()
        var other := coll.get_collider()
        if other is Bullet and other.is_player_bullet:
            add_collision_exception_with(other)
        else:
            var sparks: SparksRenderer = get_tree().get_first_node_in_group(&"sparks")
            for i in 4:
                sparks.spawn_spark(coll.get_position(), Vector2(3.0, 1.5), (-v).angle(), 10, 0.3)
            queue_free()