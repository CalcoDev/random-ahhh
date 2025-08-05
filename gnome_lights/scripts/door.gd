@tool
class_name Door
extends Node2D

signal on_id_changed(old_id: StringName, door: Door)

@export var id: StringName:
    set(value):
        var new_id := value.to_upper()
        if get_parent() != null and get_parent().get_parent() != null:
            print(get_parent().get_parent().name, "'s ID changed from ", id, " to ", new_id, "!")
        on_id_changed.emit(id, self)
        id = new_id
        name = "Door" + id

@export var to_room: Room:
    set(value):
        to_room = value
        notify_property_list_changed()

var _to_door_id: StringName = &""

# Inspector Stuff
func _get(property: StringName) -> Variant:
    if property == "to_door_id":
        return _to_door_id
    return null

func _set(property: StringName, value: Variant) -> bool:
    if property == "to_door_id":
        _to_door_id = value
        update_configuration_warnings()
        return true
    return false

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []

    if to_room:
        var door_hint_ids := ",".join(to_room.get_all_door_ids())
        properties.append({
            "name": "to_door_id",
            "type": TYPE_STRING_NAME,
            "hint": PROPERTY_HINT_ENUM,
            "hint_string": door_hint_ids,
        })

    return properties

func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    if id == &"":
        warnings.append("No ID assigned to Door.")
    if not to_room:
        warnings.append("No Room assigned to 'to_room'.")
    if to_room and _to_door_id == &"":
        warnings.append("No ID assigned to 'to_door_id'.")
    return warnings

# Debug View Stuff
const LINE_GRADIENT_SEGMENT_COUNT := 40
static var LINE_GRADIENT_FROM_COLOR := Color.BLUE
static var LINE_GRADIENT_TO_COLOR := Color.GREEN
const LINE_WIDTH := 2.0

const DEBUG_VIEW_ENABLED := false

func _process(_delta: float) -> void:
    if Engine.is_editor_hint():
        if DEBUG_VIEW_ENABLED:
            queue_redraw()

func _draw() -> void:
    if not Engine.is_editor_hint():
        return
    
    if not DEBUG_VIEW_ENABLED:
        return

    var warnings := _get_configuration_warnings()
    if warnings.size() > 0:
        return

    if not to_room or _to_door_id == &"":
        return

    var to_door := to_room.get_door(_to_door_id)
    if not to_door:
        return

    # Draw line with gradient
    var start_pos := Vector2.ZERO
    var end_pos := to_door.global_position - global_position

    var direction = end_pos - start_pos
    var segment_add := direction.normalized() * (direction.length() / LINE_GRADIENT_SEGMENT_COUNT)
        
    for i in LINE_GRADIENT_SEGMENT_COUNT:
        var color := LINE_GRADIENT_FROM_COLOR.lerp(LINE_GRADIENT_TO_COLOR, float(i) / float(LINE_GRADIENT_SEGMENT_COUNT))
        var s := start_pos + segment_add * i
        draw_line(s, s + segment_add, color, LINE_WIDTH)
    
    var arrow_size = 10.0
    direction = direction.normalized()
    var perpendicular = Vector2(-direction.y, direction.x)
    var arrow_tip = end_pos
    var arrow_base1 = end_pos - direction * arrow_size + perpendicular * arrow_size * 0.5
    var arrow_base2 = end_pos - direction * arrow_size - perpendicular * arrow_size * 0.5
    
    draw_colored_polygon(PackedVector2Array([arrow_tip, arrow_base1, arrow_base2]), LINE_GRADIENT_TO_COLOR)