class_name RoomReparenter
extends Area2D

signal on_enter_room(room: Room)
signal on_exited_room(room: Room)

var _unallowed: Dictionary[Room, bool] = {}

signal _deferred

func _wait_deferred() -> Signal:
    var deferred_signal := Signal(_deferred)
    deferred_signal.emit.call_deferred()
    return deferred_signal

var _parent: Node2D
func _ready() -> void:
    _parent = get_parent()
    _parent.tree_exited.connect(_handle_parent_exited)
    call_deferred("reparent", get_tree().get_first_node_in_group(&"reparent_handler"))

    area_entered.connect(_on_area_entered)
    area_exited.connect(_on_area_exited)

func _process(_delta: float) -> void:
    if _parent:
        global_position = _parent.global_position

func _handle_parent_exited() -> void:
    if is_inside_tree():
        await get_tree().create_timer(0.1).timeout
        if not _parent or not _parent.is_inside_tree():
            queue_free()

func _on_area_entered(other: Area2D) -> void:
    var other_parent = other.get_parent()
    if other_parent is not Room:
        return
    var room := other_parent as Room
    if room in _unallowed:
        return
    _unallowed[room] = true
    on_enter_room.emit(room)
    if room.add_entity(_parent):
        await _parent.tree_entered
        await get_tree().process_frame
    _unallowed.erase(room)

func _on_area_exited(other: Area2D) -> void:
    var other_parent = other.get_parent()
    if other_parent is not Room:
        return
    var room := other_parent as Room
    on_exited_room.emit(room)