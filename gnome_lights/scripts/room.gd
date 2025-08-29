@tool
class_name Room
extends Node2D

@export_tool_button("Generate Outline", "Callable") var generate_outline_action = _generate_outline

@export_tool_button("Viewports Editing Mode", "Callable") var setup_vp_edit_action = _setup_vp_edit
@export_tool_button("Viewports Preview Mode", "Callable") var setup_vp_preview_action = _setup_vp_preview

const ROOM_DONT_MOVE_GROUP := &"room_dont_move"
const ROOM_PREVIEW_LIGHTMASK_COPY_GROUP := &"room_preview_lightmask_copy"

enum VpSetupMode {
    EDIT,
    PREVIEW
}

var _vp_setup_mode := VpSetupMode.EDIT
# var _vp_preview_offset := Vector2.ZERO
var _vp_setup_data := {}

func _setup_vp_edit() -> void:
    var color_vp := get_color_vp()

    for child in color_vp.get_children():
        if child.is_in_group(ROOM_DONT_MOVE_GROUP):
            continue
        child.reparent(self)
        if child is Node2D:
            child.position = Vector2.ZERO
    _vp_setup_mode = VpSetupMode.EDIT
    
    get_lightcast_tiles().visible = _vp_setup_data.get("lightmask_visible", false)

func _setup_vp_preview() -> void:
    var color_vp := get_color_vp()
    var lightmask_vp := get_lightmask_vp()

    var rect_size := get_room_rect_size()
    color_vp.size = rect_size
    lightmask_vp.size = rect_size

    for child in get_children():
        if child.is_in_group(ROOM_DONT_MOVE_GROUP):
            continue
        child.reparent(color_vp)
        if child is Node2D:
            child.position = Vector2.ZERO
    _vp_setup_mode = VpSetupMode.PREVIEW
    
    lightmask_vp.world_2d = color_vp.world_2d

    get_color_tex().texture = color_vp.get_texture()
    get_lightmask_tex().texture = lightmask_vp.get_texture()

    var lightcast := get_lightcast_tiles()
    _vp_setup_data["lightmask_visible"] = lightcast.visible
    lightcast.visible = true

func get_room_rect_size() -> Vector2:
    var polygon := get_room_area_polygon()
    var aabb := _get_polygon_aabb(polygon)
    return aabb.size

var _doors: Dictionary[StringName, Door] = {}

func get_door(id: StringName) -> Door:
    return _doors.get(id, null)

func _ready() -> void:
    for child: Door in $"Doors".get_children():
        if child.id != &"":
            _doors[child.id] = child
        child.on_id_changed.connect(_handle_door_id_changed)
    
    if not Engine.is_editor_hint():
        _setup_vp_preview()
    
    for door: Door in _doors.values():
        door.setup_collision_polygon()

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
                    previous_ids[local_door_pos].facing_dir = _tilemap_door_data_to_door_facing_dir(door_data)
                    previous_ids[local_door_pos].setup_collision_polygon()
                else:
                    var door := preload("uid://5ej57o3nrqq2").instantiate() as Door
                    door.facing_dir = _tilemap_door_data_to_door_facing_dir(door_data)
                    door.setup_collision_polygon()
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

func _tilemap_door_data_to_door_facing_dir(data: StringName) -> Door.DoorFacingDir:
    if data == &"bottom":
        return Door.DoorFacingDir.BOTTOM
    if data == &"top" or data == &"top_bottom":
        return Door.DoorFacingDir.TOP
    if data == &"left":
        return Door.DoorFacingDir.LEFT
    if data == &"right":
        return Door.DoorFacingDir.RIGHT
    return Door.DoorFacingDir.BOTTOM

func _handle_door_id_changed(old_id: StringName, door: Door) -> void:
    if door.id == &"":
        return
    if old_id in _doors:
        _doors[door.id] = _doors[old_id]
        _doors.erase(old_id)
    else:
        _doors[door.id] = door

func add_entity(node: Node2D, curr_room_offset: Vector2) -> bool:
    var entity_node := get_entity_node()
    if node.get_parent() == entity_node:
        return false
    var offset := to_local(node.global_position + curr_room_offset)
    node.tree_entered.connect(_set_entity_pos.bind(node, offset))
    node.call_deferred("reparent", entity_node)
    return true

func _set_entity_pos(entity: Node2D, offset: Vector2) -> void:
    entity.tree_entered.disconnect(_set_entity_pos.bind(entity, offset))
    await get_tree().process_frame
    entity.global_position = offset

func get_raycast() -> RayCast2D:
    return $"ColorViewport/RayCast2D"

func get_color_tex() -> TextureRect:
    return $"ColorTexture"

func get_lightmask_tex() -> TextureRect:
    return $"LightMaskTexture"

func get_color_vp() -> SubViewport:
    return $"ColorViewport"

func get_lightmask_vp() -> SubViewport:
    return $"LightMaskViewport"

func get_entity_node() -> Node2D:
    return ($"ColorViewport/Entities" if _vp_setup_mode == VpSetupMode.PREVIEW else $"Entities")

func get_room_area() -> Area2D:
    # return ($"ColorViewport/RoomAreaa" if _vp_setup_mode == VpSetupMode.Preview else $"RoomArea") as Area2D
    return $"RoomArea"

func get_room_area_polygon() -> PackedVector2Array:
    # return ($"ColorViewport/RoomArea/CollisionPolygon2D" if _vp_setup_mode == VpSetupMode.Preview else $"RoomArea/CollisionPolygon2D").polygon
    return get_room_area().get_child(0).polygon

func get_floor_tiles() -> TileMapLayer:
    return ($"ColorViewport/FloorTiles" if _vp_setup_mode == VpSetupMode.PREVIEW else $"FloorTiles")

func get_wall_tiles() -> TileMapLayer:
    return ($"ColorViewport/WallTiles" if _vp_setup_mode == VpSetupMode.PREVIEW else $"WallTiles")

func get_door_tiles() -> TileMapLayer:
    return ($"ColorViewport/DoorTiles" if _vp_setup_mode == VpSetupMode.PREVIEW else $"DoorTiles")

func get_edge_tiles() -> TileMapLayer:
    return ($"ColorViewport/EdgeTiles" if _vp_setup_mode == VpSetupMode.PREVIEW else $"EdgeTiles")

func get_lightcast_tiles() -> TileMapLayer:
    return ($"ColorViewport/LightcastTiles" if _vp_setup_mode == VpSetupMode.PREVIEW else $"LightcastTiles")

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

func _get_polygon_aabb(polygon: PackedVector2Array) -> Rect2:
    if polygon.size() == 0:
        return Rect2(0, 0, 0, 0)
    
    var min_x = polygon[0].x
    var max_x = polygon[0].x
    var min_y = polygon[0].y
    var max_y = polygon[0].y
    
    for vertex in polygon:
        min_x = min(min_x, vertex.x)
        max_x = max(max_x, vertex.x)
        min_y = min(min_y, vertex.y)
        max_y = max(max_y, vertex.y)
    
    return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

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