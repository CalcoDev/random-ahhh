extends CharacterBody2D

# @export var InputManager: Inp_manager_hidden

@export_group("References")
@export var kcam: KCamera
@export var anim: AnimatedSprite2D
@export var _dash_trail: Node2D

@export_group("Movement")
@export var max_speed: float = 200.0
@export var acceleration: float = 800.0 * 2.0
@export var deceleration: float = 600.0 * 2.0
@export var turn_speed: float = 900.0 * 2.0

@export var walk_trail_duration: float = 0.1

@export_group("Dash")
@export var dash_cooldown: float = 0.25
@export var dash_duration: float = 0.2
@export var dash_speed: float = 20.0

@export var dash_trail_spawn_time: float = 0.05
@export var dash_trail_duration: float = 0.15
var _dash_trail_spawner_timer: float = 0.0
@export var dash_trail_color: Color

@export var dash_enter_vfx: PackedScene

var is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO

var _prev_inp := Vector2.ZERO

func _ready() -> void:
    _dash_trail.top_level = true

func _process(delta: float) -> void:
    var inp := InputManager.data.move_vec

    if Input.is_action_just_pressed("dbg"):
        print("Shake")
        # kcam.shake_noise(5, 10, 0.2, true, kcam.process_callback)
        kcam.shake_spring(Vector2.RIGHT * 200, 200.0, 1.0, kcam.process_callback)
    
    if is_dashing:
        anim.play("dash")
    else:
        if inp.length_squared() > 0.01:
            anim.play("run")
            if inp.x > 0.0:
                anim.flip_h = false
            else:
                anim.flip_h = true
        else:
            anim.play("idle")
    
    if not is_dashing and _dash_timer < 0.0 and InputManager.data.dash.pressed:
        _start_dash()
    _dash_timer -= delta
    if is_dashing:
        if _dash_timer < 0.0:
            _end_dash()

    # if is_dashing:
    _dash_trail_spawner_timer -= delta
    if _dash_trail_spawner_timer < 0.0:
        _dash_trail_spawner_timer = dash_trail_spawn_time

        _dash_trail_count += 1

        var duration := dash_trail_duration if is_dashing else walk_trail_duration
        if not is_dashing and _dash_timer > 0.0:
            duration = 0.0

        var sprite := Sprite2D.new()
        sprite.texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
        sprite.flip_h = anim.flip_h
        sprite.global_position = self.global_position
        sprite.modulate = dash_trail_color
        _dash_trail.add_child(sprite)
        var t := _dash_trail.create_tween()
        t.set_ease(Tween.EASE_IN_OUT)
        t.tween_method(_dash_sprite_update_callback.bind(sprite, _dash_trail_count), 0.0, 1.0, duration)
        t.parallel().tween_property(sprite, "scale", Vector2(0.8, 0.8), duration)
        t.tween_callback(_dash_sprite_free_callback.bind(sprite))
        t.play()

var _dash_trail_count: int = 0
func _dash_sprite_update_callback(_p: float, sprite: Sprite2D, index: int):
    var target := Color.TRANSPARENT.lerp(Color.WHITE, float(index) / float(_dash_trail_count))
    target.a *= 0.5
    if target.a < sprite.modulate.a:
        sprite.modulate.a = target.a

func _dash_sprite_free_callback(sprite: Sprite2D):
    sprite.queue_free()
    _dash_trail_count -= 1

func _physics_process(delta: float) -> void:
    var inp := InputManager.data.move_vec
    var body := self

    if is_dashing:
        body.velocity = _dash_dir * dash_speed * 10.0
        body.move_and_slide()
        if get_slide_collision_count() != 0:
            _end_dash()
    else:
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
        body.move_and_slide()

    _prev_inp = inp

func _start_dash() -> void:
    is_dashing = true
    _dash_timer = dash_duration
    _dash_dir = InputManager.data.move_vec
    _dash_trail_spawner_timer = 0.0

    var vfx := dash_enter_vfx.instantiate() as GPUParticles2D
    add_child(vfx)
    vfx.global_position = self.global_position
    vfx.one_shot = true
    vfx.finished.connect(vfx.queue_free)
    # anim.hide()

func _end_dash() -> void:
    is_dashing = false
    _dash_timer = dash_cooldown
    self.velocity *= 0.5
    _dash_trail_spawner_timer = 0.0

    # anim.show()