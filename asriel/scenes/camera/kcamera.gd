class_name KCamera
extends Camera2D

# TODO(calco): Support such featuers.
# signal on_shake_begin()
# signal on_shake_end()

var _shake_pos_offset := Vector2.ZERO:
    set(value):
        _shake_pos_offset = value
        offset = _shake_pos_offset

var _shake_rot_offset := 0.0

var _shake_scale := Vector2.ONE
# var _is_shaking := false

var _shake_coro: Coroutine
var _noise := FastNoiseLite.new()

var _shakers: Array[Marker2D] = []

func _process(_delta: float) -> void:
    var shake_offset := Vector2.ZERO
    for shaker in _shakers:
        shake_offset += shaker.position
    _shake_pos_offset = shake_offset

@warning_ignore("shadowed_global_identifier", "shadowed_variable")
func shake_noise(freq: float, ampl: float, duration: float, lerp: bool, process_event: Camera2DProcessCallback) -> void:
    await _shake_handler(_shake_noise_coro.bind(freq, ampl, duration, lerp, process_event))

@warning_ignore("shadowed_global_identifier", "shadowed_variable")
func shake_spring(velocity: Vector2, spring: float, damp: float, process_event: Camera2DProcessCallback) -> void:
    await _shake_handler(_shake_spring_coro.bind(velocity, spring, damp, process_event))

@warning_ignore("shadowed_global_identifier", "shadowed_variable")
func _shake_spring_coro(ctx: Coroutine.Ctx, velocity: Vector2, spring: float, damp: float, process_event: Camera2DProcessCallback) -> void:
    var obj := Marker2D.new()
    obj.name = "SHAKE SPRING!!!"
    add_child(obj)
    _shakers.append(obj)
    obj.position = Vector2.ZERO

    var s := Spring2D.new(spring, damp, velocity)
    var computed_offset := Vector2.ZERO
    while not s.is_approx_done(computed_offset, 0.001):
        if not ctx.is_valid() or not is_instance_valid(self) or not is_inside_tree():
            _shakers.erase(obj)
            obj.queue_free()
            return
        await _await_process_event(process_event)
        computed_offset = s.tick(_get_process_event_delta(process_event), computed_offset)
        obj.position = computed_offset
    
    _shakers.erase(obj)
    obj.queue_free()

@warning_ignore("shadowed_global_identifier", "shadowed_variable")
func _shake_noise_coro(ctx: Coroutine.Ctx, freq: float, ampl: float, duration: float, lerp: bool, process_event: Camera2DProcessCallback) -> void:
    var obj := Marker2D.new()
    obj.name = "SHAKE NOISE!!!"
    add_child(obj)
    _shakers.append(obj)
    obj.position = Vector2.ZERO

    _noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    var timer := 0.0
    while timer <= duration:
        if not ctx.is_valid() or not is_instance_valid(self) or not is_inside_tree():
            _shakers.erase(obj)
            obj.queue_free()
            return
        await _await_process_event(process_event)
        
        var curr_ampl := lerpf(ampl, 0.0, timer / duration) if lerp else ampl
        _noise.frequency = freq

        var x_off := _noise.get_noise_2d(timer * freq, 0.0) * curr_ampl
        var y_off := _noise.get_noise_2d(0.0, timer * freq) * curr_ampl

        obj.position.x = x_off
        obj.position.y = y_off

        timer += _get_process_event_delta(process_event)
    
    _shakers.erase(obj)
    obj.queue_free()

func _shake_handler(new_callable: Callable) -> void:
    # if _is_shaking and Coroutine.is_instance_valid(_shake_coro):
    #     _shake_coro.stop()
    # if not _is_shaking:
    #     on_shake_begin.emit()
    #     _is_shaking = true
    _shake_coro = Coroutine.make_single(true, new_callable)
    await _shake_coro.run()
    # _reset_shake()
    # _is_shaking = false
    # on_shake_end.emit()

func _reset_shake() -> void:
    _shake_pos_offset = Vector2.ZERO
    _shake_rot_offset = 0.0
    _shake_scale = Vector2.ONE

#endregion

@warning_ignore("shadowed_variable")
func _await_process_event(process_event: Camera2DProcessCallback) -> void:
    if process_event == Camera2DProcessCallback.CAMERA2D_PROCESS_IDLE:
        await get_tree().process_frame
    else:
        await get_tree().physics_frame

@warning_ignore("shadowed_variable")
func _get_process_event_delta(process_event: Camera2DProcessCallback) -> float:
    if process_event == Camera2DProcessCallback.CAMERA2D_PROCESS_IDLE:
        return get_process_delta_time()
    return get_physics_process_delta_time()