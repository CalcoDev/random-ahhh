@tool
extends Node

@export var update_stuff: bool = false
@export var generate_zones: bool = false:
    set(value):
        generate_zones = false
        _generate_zones()

@export var obliterate_children: bool = false:
    set(value):
        obliterate_children = false
        for child in _lines.get_children():
            _lines.remove_child(child)
        for child in _polygons.get_children():
            _polygons.remove_child(child)

@export var aaaaa: bool = false:
    set(value):
        aaaaa = false
        var polygon := _polygons.get_child(0)
        print(polygon)

@export_group("References")
@export var rendering: Node

@export var _map: TileMapLayer
@export var _lines: Node
@export var _polygons: Node
@export var _zone: Marker2D

@export_group("View Options")
@export var lines_per_partition: int = 3
@export var line_thickness: float = 1.0

@export var normal_pushback_range: Vector2 = Vector2(4.0, 16.0)
@export var point_wander_range: Vector2 = Vector2(4.0, 12.0)
@export var point_wander_time_range: Vector2 = Vector2(0.5, 3.0)
@export var point_wander_speed_range: Vector2 = Vector2(1.0, 4.0)

# var partitions: Dictionary[int, set] = {}
var _partitions: Dictionary[int, Dictionary] = {}
var _cell_to_partition: Dictionary[Vector2i, int] = {}

func _ready() -> void:
    # return
    if Engine.is_editor_hint():
        return
    _generate_zones()
    rendering.set_materials = true

func _process(delta: float) -> void:
    # return
    if not Engine.is_editor_hint() or (Engine.is_editor_hint() and update_stuff):
        var idx := -1
        for child in _lines.get_children():
            idx += 1
            if child is WobblyLine2D:
                child._process_wobblyness(delta)
                # var paaaa = child.points.duplicate()
                # paaaa.reverse()
                # var is_clock := Geometry2D.is_polygon_clockwise(child.points.duplicate()) or Geometry2D.is_polygon_clockwise(paaaa)
                # if is_clock:
#                 var arr := Array(child.points)
#                 arr.sort_custom(_custom_sort)
                _polygons.get_child(idx).polygon = child.points

# func _custom_sort(a, b):
#     return a.angle() < b.angle()

func _generate_zones() -> void:
    for child in _lines.get_children():
        _lines.remove_child(child)
    for child in _polygons.get_children():
        _polygons.remove_child(child)

    
    _partitions = {}
    _cell_to_partition = {}
    _partition_map(_map, _partitions, _cell_to_partition)

    var touched_partitions := _get_adjacent_partitions(_zone.global_position, _cell_to_partition)

    for touched_partition in touched_partitions:
        var start_pos: Vector2i = touched_partitions[touched_partition][0]
        var enter_pos: Vector2i = touched_partitions[touched_partition][1]

        var outline := _trace(start_pos, enter_pos)
        for i in lines_per_partition:
            var line := WobblyLine2D.new()
            _lines.add_child(line)
            if Engine.is_editor_hint():
                line.owner = get_tree().edited_scene_root

            # Geometry2D

            line.width = line_thickness
            line.modulate = Color.RED
            line.normal_pushback_range = normal_pushback_range
            line.point_wander_range = point_wander_range
            line.point_wander_time_range = point_wander_time_range
            line.point_wander_speed_range = point_wander_speed_range
            line._info = []
            line._info.resize(outline.size())

            var idx := -1
            for cell in outline:
                idx += 1
                var cell_world_pos := _map.to_global(_map.map_to_local(cell))
                line._info[idx] = {"base_pos": cell_world_pos, "normal": _get_outline_outer_normal(cell)}
        
            line.init_wobblyness()

            var polygon := Polygon2D.new()
            polygon.polygon = line.points
            _polygons.add_child(polygon)
            if Engine.is_editor_hint():
                polygon.owner = get_tree().edited_scene_root
            polygon.color = Color.from_rgba8(255, 0, 0, 1)
            # var pp := line.points.duplicate()
            # var hull := Geometry2D.convex_hull(pp)
            # # hull = Geometry2D.offset_polygon(hull.duplicate(), 40.0)[0]
            # var ahull = Geometry2D.offset_polygon(hull.duplicate(), 400.0)
            # print(ahull.size())
            # hull = ahull[0]
            # var bb := Geometry2D.clip_polygons(hull, pp)
            # # var bb := Geometry2D.clip_polygons(pp, hull)
            # for b in bb:
            #     var polygon := Polygon2D.new()
            #     polygon.polygon = b
            #     _polygons.add_child(polygon)
            #     if Engine.is_editor_hint():
            #         polygon.owner = get_tree().edited_scene_root
            #     polygon.color = Color.from_rgba8(0, 0, 255, 53)



func _get_outline_outer_normal(tile_pos: Vector2i) -> Vector2i:
    var normal := Vector2i.ZERO
    if _map.get_cell_tile_data(tile_pos + Vector2i.LEFT):
        normal += Vector2i.LEFT
    if _map.get_cell_tile_data(tile_pos + Vector2i.RIGHT):
        normal += Vector2i.RIGHT
    if _map.get_cell_tile_data(tile_pos + Vector2i.UP):
        normal += Vector2i.UP
    if _map.get_cell_tile_data(tile_pos + Vector2i.DOWN):
        normal += Vector2i.DOWN
    return normal

#region Neighbourood Tracing Helpers

func _trace(start: Vector2i, enter: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = [start]
    var pivot := start
    var current := enter
    var previous := start
    var step := 0
    while step == 0 or pivot != start:
        step += 1
        var n := _get_neighbourhood(current - pivot)
        for off in n:
            previous = current
            current = pivot + off
            if _map.get_cell_tile_data(current):
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
    assert(idx != -1, "what the fuck.")
    var b: Array[Vector2i] = []

    b.append_array(a.slice(idx + 1))
    b.append_array(a.slice(0, idx))
    return b

#endregion

#region Parition Helpers

func _partition_map(tile_map: TileMapLayer, partitions: Dictionary[int, Dictionary], cell_to_partition: Dictionary[Vector2i, int]) -> void:
    var cells := tile_map.get_used_cells()
    var checked := {}

    var partition_idx := -1
    while cells.size() > 0:
        var cell: Vector2i = cells.pop_back()
        var to_check := [cell]
        partition_idx += 1
        partitions[partition_idx] = {}

        while to_check.size() > 0:
            var tile_pos: Vector2i = to_check.pop_back()
            if tile_pos in checked or tile_map.get_cell_tile_data(tile_pos) == null:
                continue
            checked[tile_pos] = true
            cells.erase(tile_pos)

            partitions[partition_idx][tile_pos] = true
            cell_to_partition[tile_pos] = partition_idx

            to_check.append(tile_pos + Vector2i(-1, 0))
            to_check.append(tile_pos + Vector2i(1, 0))
            to_check.append(tile_pos + Vector2i(0, 1))
            to_check.append(tile_pos + Vector2i(0, -1))

func _get_adjacent_partitions(pos: Vector2, cell_to_partition: Dictionary) -> Dictionary:
    var tile_pos := _map.local_to_map(_map.to_local(pos))

    var partitions := {}
    var to_check := [[tile_pos, tile_pos]]
    var checked := {}

    while to_check.size() > 0:
        var t = to_check.pop_back()
        var curr_tile_pos: Vector2i = t[0]
        if curr_tile_pos in checked:
            continue
        checked[curr_tile_pos] = true

        var tile_data := _map.get_cell_tile_data(curr_tile_pos)
        if tile_data:
            partitions[cell_to_partition[curr_tile_pos]] = [curr_tile_pos, t[1]]
            continue

        to_check.append([curr_tile_pos + Vector2i(-1, 0), curr_tile_pos])
        to_check.append([curr_tile_pos + Vector2i(1, 0), curr_tile_pos])
        to_check.append([curr_tile_pos + Vector2i(0, 1), curr_tile_pos])
        to_check.append([curr_tile_pos + Vector2i(0, -1), curr_tile_pos])

    return partitions

#endregion

#region Drawing Helpers

func _draw_tile(tile_pos: Vector2i, color: Color) -> void:
    var line := _spawn_line(_lines, 16.0, color)
    var p := _map.to_global(_map.map_to_local(tile_pos))
    line.add_point(p - Vector2.RIGHT * 8)
    line.add_point(p + Vector2.RIGHT * 8)

func _spawn_line(parent: Node, width: float, color: Color) -> Line2D:
    var line := Line2D.new()
    parent.add_child(line)
    if Engine.is_editor_hint():
        line.owner = get_tree().edited_scene_root
    line.width = width
    line.modulate = color
    return line

#endregion