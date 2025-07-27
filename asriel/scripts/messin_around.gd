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
    # for cell in cell_to_partition:
    #     var partition: int = cell_to_partition[cell]
    #     var line = _spawn_line(line_child, 16.0, colors[partition])
    #     var pos := map.to_global(map.map_to_local(cell))
    #     line.add_point(pos - Vector2.RIGHT * 8.0)
    #     line.add_point(pos + Vector2.RIGHT * 8.0)

    for marker in zones:
        var outline_partitions := {}
        var outline := _generate_zone_outline(marker.global_position, outline_partitions, cell_to_partition)

        # for cell in outline:
        #     var line = _spawn_line(line_child, 16.0, colors[cell_to_partition[cell]])
        #     var pos := map.to_global(map.map_to_local(cell))
        #     line.add_point(pos - Vector2.RIGHT * 8.0)
        #     line.add_point(pos + Vector2.RIGHT * 8.0)

        for partition in outline_partitions:
            var start_pos: Vector2i = outline_partitions[partition]
            var ordered_outline = _generate_ordered_outline(outline, start_pos, cell_to_partition)

            for cell in ordered_outline:
                var line = _spawn_line(line_child, 16.0, colors[partition])
                var pos := map.to_global(map.map_to_local(cell))
                line.add_point(pos - Vector2.RIGHT * 8.0)
                line.add_point(pos + Vector2.RIGHT * 8.0)

            # for _i in 4:
            #     var line := _spawn_line(line_child2, 1.0, Color.BLACK)
            #     for i in ordered_outline.size():
            #         var tile_pos: Vector2i = ordered_outline[i]
            #         var global_pos := map.to_global(map.map_to_local(tile_pos))
            #         var normal_dir := _get_outline_outer_normal(tile_pos)
            #         line.add_point(global_pos + normal_dir * randf_range(1.0, 8.0))
            #     line.add_point(line.points[0])

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

func _generate_ordered_outline(outline: Dictionary, start_pos: Vector2i, cell_to_partition: Dictionary) -> Array:
    var tiles := []

    var og_start := start_pos

    var yes := [start_pos, start_pos + Vector2i.DOWN, start_pos + Vector2i.LEFT + Vector2i.DOWN]
    # if map.get_cell_tile_data(start_pos) and map.get_cell_tile_data(

    var failed_count := 0
    while failed_count < 4:
        failed_count = 0
        for d in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
            og_start = start_pos
            # print("DIR ", d, " START ", start_pos)
            start_pos = _ordered_outline_4d_yeet(tiles, outline, start_pos, d)
            failed_count += int(start_pos == og_start)
            # print(" -=-=- ")

    if tiles.size() == 0 and og_start == start_pos:
        tiles.append(start_pos)
        outline.erase(start_pos)
        # print("Erasing aaa", start_pos)
    
    _ordered_outline_8d_yeet(tiles, outline, start_pos, Vector2i.LEFT + Vector2i.UP, cell_to_partition)
    _ordered_outline_8d_yeet(tiles, outline, start_pos, Vector2i.LEFT + Vector2i.DOWN, cell_to_partition)
    _ordered_outline_8d_yeet(tiles, outline, start_pos, Vector2i.RIGHT + Vector2i.UP, cell_to_partition)
    _ordered_outline_8d_yeet(tiles, outline, start_pos, Vector2i.RIGHT + Vector2i.DOWN, cell_to_partition)
    
    return tiles

func _ordered_outline_4d_yeet(tiles: Array, outline: Dictionary, start_pos: Vector2i, dir: Vector2i) -> Vector2i:
    if start_pos + dir in outline:
        tiles.append(start_pos)
        outline.erase(start_pos)
        # print("Erasing bbb", start_pos)
        while start_pos + dir in outline:
            start_pos += dir
            tiles.append(start_pos)
            outline.erase(start_pos)
            # print("Erasing ccc", start_pos)
    return start_pos

func _ordered_outline_8d_yeet(tiles: Array, outline: Dictionary, start_pos: Vector2i, dir: Vector2i, cell_to_partition: Dictionary) -> void:
    if start_pos + dir in outline and cell_to_partition[start_pos] == cell_to_partition[start_pos + dir]:
        var gen_outline := _generate_ordered_outline(outline, start_pos + dir, cell_to_partition)
        tiles.append_array(gen_outline)

func _generate_zone_outline(seed_pos: Vector2, partitions: Dictionary, cell_to_partition: Dictionary) -> Dictionary:
    var seed_tile_pos := map.local_to_map(map.to_local(seed_pos))

    var outline := {}

    var to_check := [seed_tile_pos]
    var checked := {}

    while to_check.size() > 0:
        var tile_pos: Vector2i = to_check.pop_back()
        if tile_pos in checked:
            continue
        checked[tile_pos] = true

        var tile_data := map.get_cell_tile_data(tile_pos)
        if tile_data:
            outline[tile_pos] = {}
            partitions[cell_to_partition[tile_pos]] = tile_pos
            continue

        to_check.append(tile_pos + Vector2i(-1, 0))
        to_check.append(tile_pos + Vector2i(1, 0))
        to_check.append(tile_pos + Vector2i(0, 1))
        to_check.append(tile_pos + Vector2i(0, -1))

    return outline

func _spawn_line(parent: Node, width: float, color: Color) -> Line2D:
    var line := Line2D.new()
    parent.add_child(line)
    if Engine.is_editor_hint():
        line.owner = get_tree().edited_scene_root
    line.width = width
    line.modulate = color
    return line