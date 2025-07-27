@tool
extends Node

@export var map: TileMapLayer
@export var line_child: Node
@export var line_child2: Node

@export var zones: Array[Marker2D]

# @export var do_the_wobble

@export var generate_zones: bool = false:
    set(value):
        generate_zones = false
        _generate_zones()

func _process(delta: float) -> void:
    pass

func _generate_zones() -> void:
    for child in line_child.get_children():
        line_child.remove_child(child)
    for child in line_child2.get_children():
        line_child2.remove_child(child)
    
    # proper space partitioning
    var cells := map.get_used_cells()
    var checked := {}

    var partitions := {}
    var partition_idx := -1
    var cell_to_partition := {}

    while cells.size() > 0:
        var cell: Vector2i = cells.pop_back()
        var to_check := [cell]
        partition_idx += 1
        partitions[partition_idx] = {}

        while to_check.size() > 0:
            var tile_pos: Vector2i = to_check.pop_back()
            if tile_pos in checked or map.get_cell_tile_data(tile_pos) == null:
                continue
            checked[tile_pos] = true
            cells.erase(tile_pos)

            partitions[partition_idx][tile_pos] = true
            cell_to_partition[tile_pos] = partition_idx

            to_check.append(tile_pos + Vector2i(-1, 0))
            to_check.append(tile_pos + Vector2i(1, 0))
            to_check.append(tile_pos + Vector2i(0, 1))
            to_check.append(tile_pos + Vector2i(0, -1))
    
    var colors = []
    colors.resize(partition_idx + 1)
    for i in partition_idx + 1:
        colors[i] = Color.from_rgba8(randi() % 255, randi() % 255, randi() % 255, 255)

    for marker in zones:
        var touched_partitions := _get_partitions_touched_by_free_zone(marker.global_position, cell_to_partition)

        for touched_partition in touched_partitions:
            var color = colors[touched_partition]
            var start_pos: Vector2i = touched_partitions[touched_partition][0]
            var enter_pos: Vector2i = touched_partitions[touched_partition][1]

            var outline := _trace(start_pos, enter_pos)
            for cell in outline:
                var line = _spawn_line(line_child, 16.0, color)
                var pos := map.to_global(map.map_to_local(cell))
                line.add_point(pos - Vector2.RIGHT * 8.0)
                line.add_point(pos + Vector2.RIGHT * 8.0)


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
            if _is_solid(current):
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


func _get_edge_contour() -> void:
    pass

func _is_solid(pos: Vector2i) -> bool:
    return map.get_cell_tile_data(pos) != null

func _get_outline_outer_normal(tile_pos: Vector2i) -> Vector2i:
    var normal := Vector2i.ZERO
    if map.get_cell_tile_data(tile_pos + Vector2i.LEFT):
        normal += Vector2i.LEFT
    if map.get_cell_tile_data(tile_pos + Vector2i.RIGHT):
        normal += Vector2i.RIGHT
    if map.get_cell_tile_data(tile_pos + Vector2i.UP):
        normal += Vector2i.UP
    if map.get_cell_tile_data(tile_pos + Vector2i.DOWN):
        normal += Vector2i.DOWN
    return normal

func _get_partitions_touched_by_free_zone(pos: Vector2, cell_to_partition: Dictionary) -> Dictionary:
    var tile_pos := map.local_to_map(map.to_local(pos))

    var partitions := {}
    var to_check := [[tile_pos, tile_pos]]
    var checked := {}

    while to_check.size() > 0:
        var t = to_check.pop_back()
        var curr_tile_pos: Vector2i = t[0]
        if curr_tile_pos in checked:
            continue
        checked[curr_tile_pos] = true

        var tile_data := map.get_cell_tile_data(curr_tile_pos)
        if tile_data:
            partitions[cell_to_partition[curr_tile_pos]] = [curr_tile_pos, t[1]]
            continue

        to_check.append([curr_tile_pos + Vector2i(-1, 0), curr_tile_pos])
        to_check.append([curr_tile_pos + Vector2i(1, 0), curr_tile_pos])
        to_check.append([curr_tile_pos + Vector2i(0, 1), curr_tile_pos])
        to_check.append([curr_tile_pos + Vector2i(0, -1), curr_tile_pos])

    return partitions

func _draw_tile(tile_pos: Vector2i, color: Color) -> void:
    var line := _spawn_line(line_child, 16.0, color)
    var p := map.to_global(map.map_to_local(tile_pos))
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