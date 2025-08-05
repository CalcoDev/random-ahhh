@tool
class_name Room
extends Node2D

@export_tool_button("Generate Outline", "Callable") var generate_outline_action = _generate_outline

@export var toggle_light: bool = false
@export_tool_button("Toggle Setup", "Callable") var toggle_setup_action = _toggle_setup

func _toggle_setup() -> void:
    var on := not get_edge_tiles().visible

    # get_floor_tiles().visible = on
    get_wall_tiles().visible = on
    get_edge_tiles().visible = on
    get_door_tiles().visible = on
    get_lightcast_tiles().visible = on and toggle_light

@export var test:= false:
    set(value):
        print(_doors)

var _doors: Dictionary[StringName, Door] = {}

func get_door(id: StringName) -> Door:
    return _doors.get(id, null)

func _ready() -> void:
    for child: Door in $"Doors".get_children():
        if child.id != &"":
            _doors[child.id] = child
        child.on_id_changed.connect(_handle_door_id_changed)

func _generate_outline() -> void:
    var floor_tiles :=  get_floor_tiles()
    var wall_tiles := get_wall_tiles()
    var edge_tiles :=  get_edge_tiles()
    var lightcast_tiles :=  get_lightcast_tiles()
    var door_tiles := get_door_tiles()

    for tile in wall_tiles.get_used_cells():
        wall_tiles.erase_cell(tile)
    for tile in edge_tiles.get_used_cells():
        edge_tiles.erase_cell(tile)
    for tile in lightcast_tiles.get_used_cells():
        lightcast_tiles.erase_cell(tile)

    for tile in floor_tiles.get_used_cells():
        var atlas_coords = _get_edge_autotile(tile, floor_tiles)
        if atlas_coords != Vector2i.ONE:
            edge_tiles.set_cell(tile, 0, atlas_coords + Vector2i(0, 1))
        lightcast_tiles.set_cell(tile, 0, Vector2i(3, 3))
        
        var door_data := door_tiles.get_cell_tile_data(tile)
        if door_data:
            var door_place := door_data.get_custom_data("door") as StringName
            if door_place == "right" or door_place == "left":
                var door_spawn := door_data.get_custom_data("spawn_door") as bool
                if not door_spawn:
                    continue
            else:
                continue

        if not floor_tiles.get_cell_tile_data(tile + Vector2i.UP * 2):
            if not floor_tiles.get_cell_tile_data(tile + Vector2i.UP):
                wall_tiles.set_cell(tile, 0, Vector2i(0, 0))
            else:
                wall_tiles.set_cell(tile, 0, Vector2i(1, 0))

    var outline := _trace_tilemap_outline(floor_tiles, Vector2i(0, 0), Vector2i(-1, 0))
    var polyline := PackedVector2Array()
    for cell_index in outline.size():
        var cell := outline[cell_index] as Vector2i
        var cell_world_pos := floor_tiles.map_to_local(cell)
        polyline.append(cell_world_pos)
    var room_area := get_room_area()
    (room_area.get_child(0) as CollisionPolygon2D).polygon = Geometry2D.offset_polyline(polyline, floor_tiles.tile_set.tile_size.x / 2.0)[0]

    var previous_ids: Dictionary[Vector2, Door] = {}
    for child: Door in $"Doors".get_children():
        if child.id != &"" and child.to_room and child._to_door_id != &"":
            previous_ids[child.position] = child

    if _doors:
        _doors.clear()

    var new_doors: Array[Door] = []
    for tile in door_tiles.get_used_cells():
        var data := door_tiles.get_cell_tile_data(tile)
        var door_data := data.get_custom_data("door") as StringName

        floor_tiles.set_cell(tile, 0, Vector2i(2, 0))
        if door_data != &"top_bottom":
            edge_tiles.erase_cell(tile)

            if data.get_custom_data("spawn_door"):
                var global_door_pos := door_tiles.to_global(door_tiles.map_to_local(tile)) + door_tiles.tile_set.tile_size * 0.5
                if door_data == &"left":
                    global_door_pos.x -= door_tiles.tile_set.tile_size.x
                var local_door_pos := to_local(global_door_pos)
                if local_door_pos in previous_ids:
                    new_doors.append(previous_ids[local_door_pos])
                else:
                    var door := preload("uid://5ej57o3nrqq2").instantiate() as Door
                    new_doors.append(door)
                    door.position = local_door_pos
                    door.on_id_changed.connect(_handle_door_id_changed)

    for child: Door in $"Doors".get_children():
        if child not in new_doors:
            child.queue_free()

    for door in new_doors:
        _doors[door.id] = door
        if door.get_parent() != $"Doors":
            $"Doors".add_child(door)
            door.id = &""
            door.name = "Door_NOID"
            if Engine.is_editor_hint():
                door.owner = get_tree().edited_scene_root

func _handle_door_id_changed(old_id: StringName, door: Door) -> void:
    if door.id == &"":
        return
    if old_id in _doors:
        _doors[door.id] = _doors[old_id]
        _doors.erase(old_id)
    else:
        _doors[door.id] = door

func add_entity(node: Node2D) -> bool:
    var entity_node := get_entity_node()
    if node.get_parent() == entity_node:
        return false
    node.call_deferred("reparent", entity_node)
    return true

func get_entity_node() -> Node2D:
    return $"Entities"

func get_room_area() -> Area2D:
    return $"RoomArea" as Area2D

func get_floor_tiles() -> TileMapLayer:
    return $"FloorTiles" as TileMapLayer

func get_wall_tiles() -> TileMapLayer:
    return $"WallTiles" as TileMapLayer

func get_door_tiles() -> TileMapLayer:
    return $"DoorTiles" as TileMapLayer

func get_edge_tiles() -> TileMapLayer:
    return $"EdgeTiles" as TileMapLayer

func get_lightcast_tiles() -> TileMapLayer:
    return $"LightcastTiles" as TileMapLayer

func get_all_door_ids() -> Array[StringName]:
    var ids: Array[StringName] = []
    for child: Door in $"Doors".get_children():
        ids.append(child.id)
    return ids

func _get_edge_autotile(coords: Vector2i, map: TileMapLayer) -> Vector2i:
    var tl := map.get_cell_tile_data(coords + Vector2i(-1, -1)) != null
    var tr := map.get_cell_tile_data(coords + Vector2i(1, -1)) != null
    var bl := map.get_cell_tile_data(coords + Vector2i(-1, 1)) != null
    var br := map.get_cell_tile_data(coords + Vector2i(1, 1)) != null

    var t := map.get_cell_tile_data(coords + Vector2i(0, -1)) != null
    var l := map.get_cell_tile_data(coords + Vector2i(-1, 0)) != null
    var b := map.get_cell_tile_data(coords + Vector2i(0, 1)) != null
    var r := map.get_cell_tile_data(coords + Vector2i(1, 0)) != null

    var atlas_coords: Vector2i
    if t and l and b and r and tl and br and bl and br: # Center (all neighbors)
        atlas_coords = Vector2i(1, 1)
    elif t and l and b and not r: # Right edge
        atlas_coords = Vector2i(2, 1)
    elif t and not l and b and r: # Left edge
        atlas_coords = Vector2i(0, 1)
    elif not t and l and b and r: # Top edge
        atlas_coords = Vector2i(1, 0)
    elif t and l and not b and r: # Bottom edge
        atlas_coords = Vector2i(1, 2)
    elif t and l and not b and not r: # Bottom-right corner
        atlas_coords = Vector2i(2, 2)
    elif t and not l and not b and r: # Bottom-left corner
        atlas_coords = Vector2i(0, 2)
    elif not t and l and b and not r: # Top-right corner
        atlas_coords = Vector2i(2, 0)
    elif not t and not l and b and r: # Top-left corner
        atlas_coords = Vector2i(0, 0)
    # Inner Corners: Check diagonals and cardinals
    elif t and l and b and r and not tl: # Top-left inner corner
        atlas_coords = Vector2i(4, 1)
    elif t and l and b and r and not tr: # Top-right inner corner
        atlas_coords = Vector2i(3, 1)
    elif t and l and b and r and not bl: # Bottom-left inner corner
        atlas_coords = Vector2i(4, 0)
    elif t and l and b and r and not br: # Bottom-right inner corner
        atlas_coords = Vector2i(3, 0)
    else:
        atlas_coords = Vector2(0, 0)
    
    return atlas_coords

#region Neighbourood Tracing Helpers

func _trace_tilemap_outline(map: TileMapLayer, start: Vector2i, enter: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = [start]
    var pivot := start
    var current := enter
    var previous := start
    var step := 0

    while step == 0 or pivot != start and step < 400:
        step += 1
        var n := _get_neighbourhood(current - pivot)
        for off in n:
            previous = current
            current = pivot + off
            if map.get_cell_tile_data(current):
                path.append(current)
                pivot = current
                current = previous
                break
    return path

# TODO(calco): this needs MASSIVE improvement lol
func _get_neighbourhood(diff: Vector2i) -> Array[Vector2i]:
    var a: Array[Vector2i] = [
        Vector2i(-1, -1),
        Vector2i(0, -1),
        Vector2i(1, -1),
        Vector2i(1, 0),
        Vector2i(1, 1),
        Vector2i(0, 1),
        Vector2i(-1, 1),
        Vector2i(-1, 0),
    ]

    var idx := a.find(diff)
    assert(idx != -1, "what the fuck. ( " + str(diff) + ") ")
    var b: Array[Vector2i] = []

    b.append_array(a.slice(idx + 1))
    b.append_array(a.slice(0, idx))
    return b

#endregion