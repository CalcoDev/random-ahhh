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

@export_group("Weapons")
@export var _start_weapon: PackedScene

@export var _weapon_hold_spot: Marker2D

var _weapon: Weapon

func _ready() -> void:
    _dash_trail.top_level = true
    if _start_weapon:
        _weapon = _start_weapon.instantiate()
        _weapon_hold_spot.add_child(_weapon)

# var _weapon_bob_offset := Vector2.ZERO
# var _interp_vel := Vector2.ZERO
# var _random := {}
var __vel := Vector2.ZERO
func _process(delta: float) -> void:
    var inp := InputManager.data.move_vec

    if _weapon:
        var key := InputManager.data.fire_weapon
        if key.pressed or (_weapon.hold_downable and key.held):
            _weapon.try_use()

        var parent := _weapon_hold_spot.get_parent() as Node2D

        var vp := get_viewport()
        var vp_size := vp.get_visible_rect().size
        var mp_normalised := ((vp.get_mouse_position() - vp_size * 0.5) / vp_size * 2.0).rotated(-parent.rotation)

        if _weapon.rotate_pivot_self:
            if inp.x > 0.0:
                parent.scale.x = 1.0
            else:
                parent.scale.x = -1.0
        else:
            parent.rotation = (InputManager.data.mouse_pos - parent.global_position).angle()

            var mouse_offset := mp_normalised * (_weapon.hold_position_offset + _weapon.hold_position_min)
            _weapon.position = mouse_offset
            
            if parent.rotation < -PI / 2.0 or parent.rotation > PI / 2.0:
                _weapon.get_child(0).flip_v = true
            else:
                _weapon.get_child(0).flip_v = false

        var elapsed_time := Time.get_ticks_msec() / 1000.0 * _weapon.bob_freq * 2.0
        
        var inverse_mouse_mult := pow((1.0 - mp_normalised.length()), 1)

        var bob_offset := (Vector2.DOWN * sin(elapsed_time) * _weapon.bob_strength / 2.0) * inverse_mouse_mult

        _weapon.position += bob_offset 
        _weapon.rotation = sin(elapsed_time * _weapon.bob_rot_freq / 4.0) * deg_to_rad(_weapon.bob_rot_strength / 2.0) * inverse_mouse_mult

        var target_vel := self.velocity.normalized() * self.velocity.length_squared() / (max_speed * max_speed)
        __vel = __vel.lerp(target_vel, delta * 2.0)
        var vel_off := 4.0 * _weapon.bob_vel_delay *  __vel
        var c := _weapon.get_child(0)
        c.position = c.position.lerp(-parent.scale.y * vel_off.rotated(-parent.rotation), delta * 3.0)

    if Input.is_action_just_pressed("dbg"):
        kcam.shake_spring(Vector2.RIGHT * 200, 200.0, 1.0, kcam.process_callback)
    
    if is_dashing:
        anim.play("dash")
    else:
        if inp.length_squared() > 0.01:
            anim.play("run")
            if inp.x > 0.0:
                anim.flip_h = false
                # _weapon_hold_spot.scale.x = -1.0
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
        if not is_dashing:
            if _dash_timer > 0.0:
                duration = 0.0
            if inp.length_squared() < 0.01:
                duration = 0.09

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
    _dash_dir = InputManager.data.last_nonzero_move_vec
    _dash_trail_spawner_timer = 0.0

    var vfx := dash_enter_vfx.instantiate() as GPUParticles2D
    add_child(vfx)
    vfx.global_position = self.global_position
    vfx.one_shot = true
    vfx.finished.connect(vfx.queue_free)

    kcam.shake_spring(-_dash_dir * 200, 200.0, 10.0, kcam.process_callback)
    kcam.shake_noise(5, 5, 0.15, true, kcam.process_callback)

    # anim.hide()

func _end_dash() -> void:
    is_dashing = false
    _dash_timer = dash_cooldown
    self.velocity *= 0.5
    _dash_trail_spawner_timer = 0.0

    # anim.show()