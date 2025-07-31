extends CharacterBody2D

# @export var InputManager: Inp_manager_hidden

@export_group("References")
@export var kcam: KCamera
@export var anim: AnimatedSprite2D
@export var _dash_trail: Node2D

@export var bullet_node: Node

@export var _downwell_lines: ColorRect

@export var _sparks: SparksRenderer

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
        _is_ready_to_throw = false

        anim.animation_finished.connect(_weapon_animation_finished)

        # anim.sprite_frames.set_animation_speed(&"throw_prepare", weapon.use_cooldown)
        anim.sprite_frames.set_animation_speed(&"throw_prepare", float(anim.sprite_frames.get_frame_count(&"throw_prepare")) / _weapon.use_cooldown)
        anim.sprite_frames.set_animation_speed(&"throw_finish", float(anim.sprite_frames.get_frame_count(&"throw_finish")) / _weapon.use_cooldown)
        # print(anim.sprite_frames.get_animation_speed(&"throw_prepare"))
        anim.play(&"throw_prepare")

var __vel := Vector2.ZERO

var _is_throwing := false

var _is_ready_to_throw := false

func _weapon_animation_finished() -> void:
    if anim.animation == &"throw":
        anim.stop()
        _is_throwing = false
    elif anim.animation == &"throw_prepare":
        _is_ready_to_throw = true
    elif anim.animation == &"throw_finished":
        pass

var _weapon_recoil_offset := 0.0

var _downwell_lines_angle := 0.0

func _process(delta: float) -> void:
    var inp := InputManager.data.move_vec

    # _downwell_lines_angle = lerp_angle(_downwell_lines_angle, InputManager.data.last_nonzero_move_vec.angle(), delta * 2.0)
    # _downwell_lines.material.set_shader_parameter("u_angle", _downwell_lines_angle)

    if _weapon:
        var d := {}
        if not is_dashing:
            var key := InputManager.data.fire_weapon
            if key.pressed or (_weapon.hold_downable and key.held):
                if _is_ready_to_throw and _weapon.can_use():
                    # _downwell_lines.material.set_shader_parameter("u_angle", (InputManager.data.mouse_pos - global_position).angle())
                    d = _weapon.use({
                        "is_bullet": true,
                        "position": global_position,
                        "bullet_direction": (InputManager.data.mouse_pos - global_position).normalized(),
                        "is_first_bullet": key.held_time > 0.1,
                        "parent_node": bullet_node
                    })
                    if d["shake"]:
                        kcam.shake_noise(_weapon.shake_freq, _weapon.shake_intensity, _weapon.shake_duration, true, kcam.process_callback)
                    if d["recoil"]:
                        _weapon_recoil_offset = d["recoil_intensity"]
                        # _weapon.get_child(0).get_child(0).position.x = _weapon_recoil_offset
                    anim.play(&"throw_finish")
                    _is_ready_to_throw = false
                    _is_throwing = true

        var parent := _weapon_hold_spot.get_parent() as Node2D

        var vp := get_viewport()
        var vp_size := vp.get_visible_rect().size
        var mp_normalised := ((vp.get_mouse_position() - vp_size * 0.5) / vp_size * 2.0).rotated(-parent.rotation)

        var w_pos := Vector2.ZERO
        if _weapon.rotate_pivot_self:
            if inp.x > 0.0:
                parent.scale.x = 1.0
            else:
                parent.scale.x = -1.0
        else:
            parent.rotation = (InputManager.data.mouse_pos - parent.global_position).angle()

            var mouse_offset := mp_normalised * (_weapon.hold_position_offset + _weapon.hold_position_min)
            w_pos = mouse_offset
            
            if parent.rotation < -PI / 2.0 or parent.rotation > PI / 2.0:
                _weapon.get_child(0).get_child(0).flip_v = true
            else:
                _weapon.get_child(0).get_child(0).flip_v = false
        _weapon.position = w_pos

        var elapsed_time := Time.get_ticks_msec() / 1000.0 * _weapon.bob_freq * 2.0
        
        # var inverse_mouse_mult := pow((1.0 - mp_normalised.length()), 0.5)
        var inverse_mouse_mult := 1.0 - pow(mp_normalised.length(), 3.0)

        var bob_offset := (Vector2.DOWN * sin(elapsed_time) * _weapon.bob_strength / 2.0) * inverse_mouse_mult

        _weapon.position += bob_offset 
        _weapon.rotation = sin(elapsed_time * _weapon.bob_rot_freq / 4.0) * deg_to_rad(_weapon.bob_rot_strength / 2.0) * inverse_mouse_mult

        var target_vel := self.velocity.normalized() * self.velocity.length_squared() / (max_speed * max_speed)
        __vel = __vel.lerp(target_vel, delta * 2.0)
        var vel_off := 8.0 * _weapon.bob_vel_delay *  __vel
        var c := _weapon.get_child(0)
        c.position = c.position.lerp(-parent.scale.y * vel_off.rotated(-parent.rotation), delta * 3.0)

        _weapon_recoil_offset = lerp(_weapon_recoil_offset, 0.0, 2.0 * delta)
        var cc := c.get_child(0)
        cc.position.x = _weapon_recoil_offset

        if "sparks" in d:
            for i in d["spark_count"]:
                _sparks.spawn_spark(d["spark_pos"], d["spark_size"], d["spark_angle"] + randf() * d["spark_angle_random"], d["spark_speed"], d["spark_lifetime"])

    if is_dashing:
        anim.play(&"dash")
    elif anim.is_playing() and anim.animation in [&"throw_prepare", &"throw_finish", &"throw"]:
        pass
    elif _weapon != null and not _is_ready_to_throw:
        anim.play(&"throw_prepare")
    elif inp.length_squared() > 0.01:
        anim.play(&"run")
    else:
        var idle_anim := &"idle"
        if _weapon != null and _is_ready_to_throw:
            idle_anim = &"throw_prepared_idle"
        anim.play(idle_anim)
        
    if inp.length_squared() > 0.01:
        if inp.x > 0.0:
            anim.flip_h = false
        else:
            anim.flip_h = true
    else:
        var angle := (InputManager.data.mouse_pos - global_position).angle()
        if angle < -PI / 2.0 or angle > PI / 2.0:
            anim.flip_h = true
        else:
            anim.flip_h = false
    
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
    
    _sparks.spawn_spark(global_position, Vector2(12.0, 6.0) / 2.0, _dash_dir.angle() + PI / 4.0, 500.0, 0.6)
    _sparks.spawn_spark(global_position, Vector2(12.0, 6.0) / 2.0, _dash_dir.angle() + PI / 4.0 + PI, 500.0, 0.6)
    for i in 8:
        _sparks.spawn_spark(global_position, Vector2(4.0, 4.0), randf() * TAU, 200.0, 0.3)

    kcam.shake_spring(-_dash_dir * 200, 200.0, 10.0, kcam.process_callback)
    kcam.shake_noise(5, 5, 0.15, true, kcam.process_callback)

    # anim.hide()

func _end_dash() -> void:
    is_dashing = false
    _dash_timer = dash_cooldown
    self.velocity *= 0.5
    _dash_trail_spawner_timer = 0.0

    # anim.show()