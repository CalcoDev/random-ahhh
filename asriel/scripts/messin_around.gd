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

@export var polygon_shader: Shader

@export_group("References")
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

var _partitions: Dictionary[int, Dictionary] = {}
var _cell_to_partition: Dictionary[Vector2i, int] = {}

func _notification(what: int) -> void:
    if what == NOTIFICATION_ENTER_TREE:
        obliterate_children = true

func _ready() -> void:
    # return
    if Engine.is_editor_hint():
        return
    _generate_zones()

func _process(delta: float) -> void:
    # return
    if not Engine.is_editor_hint() or (Engine.is_editor_hint() and update_stuff):
        for line in _lines.get_children():
            line._process_wobblyness(delta)
        for polygon_idx in _polygons.get_child_count():
            var poly: Polygon2D = _polygons.get_child(polygon_idx)
            var line: WobblyLine2D = _lines.get_child(polygon_idx * lines_per_partition)
            var s := poly.polygon.size() - 1
            for j in s+1:
                var diff: Vector2 = line._info[j % s]["base_pos"] - line.points[j]
                var encoded := _poly_col_buf(diff)
                poly.vertex_colors[j].b = encoded.r
                poly.vertex_colors[j].a = encoded.g

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

            line.width = line_thickness
            line.modulate = Color.RED
            line.normal_pushback_range = normal_pushback_range
            line.point_wander_range = point_wander_range
            line.point_wander_time_range = point_wander_time_range
            line.point_wander_speed_range = point_wander_speed_range
            line._info = []

            var polygon_colour_buffer := PackedColorArray()

            var idx := 0
            for cell in outline:
                var cell_world_pos := _map.to_global(_map.map_to_local(cell))
                var neighbour_count := 0
                var normal := Vector2i.ZERO
                var horizontal := false

                if _map.get_cell_tile_data(cell + Vector2i.LEFT):
                    neighbour_count += 1
                    normal += Vector2i.LEFT
                    horizontal = true
                if _map.get_cell_tile_data(cell + Vector2i.RIGHT):
                    neighbour_count += 1
                    normal += Vector2i.RIGHT
                    horizontal = true
                if _map.get_cell_tile_data(cell + Vector2i.UP):
                    neighbour_count += 1
                    normal += Vector2i.UP
                if _map.get_cell_tile_data(cell + Vector2i.DOWN):
                    neighbour_count += 1
                    normal += Vector2i.DOWN
                normal *= -1
                
                if neighbour_count == 1:
                    var nn := Vector2i(Vector2(normal).rotated(PI/2).round())
                    line._info.append({"base_pos": cell_world_pos, "normal": nn})
                    polygon_colour_buffer.append(_poly_col_buf(-nn))
                    idx += 1
                    line._info.append({"base_pos": cell_world_pos, "normal": -normal})
                    polygon_colour_buffer.append(_poly_col_buf(normal))
                    idx += 1
                    line._info.append({"base_pos": cell_world_pos, "normal": -nn})
                    polygon_colour_buffer.append(_poly_col_buf(nn))
                    idx += 1
                elif neighbour_count == 2 and normal == Vector2i.ZERO:
                    if not horizontal:
                        var diff = (cell_world_pos - line._info[idx - 1]["base_pos"]).normalized().round()
                        var nn := Vector2i.LEFT if diff.y > 0 else Vector2i.RIGHT
                        line._info.append({"base_pos": cell_world_pos, "normal": nn})
                        polygon_colour_buffer.append(_poly_col_buf(-nn))
                        idx += 1
                    else:
                        var diff = (cell_world_pos - line._info[idx - 1]["base_pos"]).normalized().round()
                        var nn := Vector2i.DOWN if diff.x > 0 else Vector2i.UP
                        line._info.append({"base_pos": cell_world_pos, "normal": nn})
                        polygon_colour_buffer.append(_poly_col_buf(-nn))
                        idx += 1
                else:
                    line._info.append({"base_pos": cell_world_pos, "normal": normal})
                    polygon_colour_buffer.append(_poly_col_buf(normal))
                    idx += 1
        

            if i == 0:
                polygon_colour_buffer.append(polygon_colour_buffer[0])
                line.init_wobblyness(false)
                var polygon := Polygon2D.new()
                _polygons.add_child(polygon)
                if Engine.is_editor_hint():
                    polygon.owner = get_tree().edited_scene_root

                polygon.polygon = line.points
                polygon.vertex_colors = polygon_colour_buffer
                polygon.color = Color.from_rgba8(255, 0, 0, 1)
                var mat := ShaderMaterial.new()
                mat.shader = polygon_shader
                polygon.material = mat
            
            line.init_wobblyness(true)


func _poly_col_buf(normal: Vector2i) -> Color:
    var unorm := Vector2(normal).normalized()
    # unorm.y *= -1.0
    unorm = (unorm + Vector2.ONE) * 0.5
    return Color(unorm.x, unorm.y, 0.0, 0.0)


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