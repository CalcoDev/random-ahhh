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

    # for marker in zones:
    #     var outline := _generate_zone_outline(marker.global_position)
    #     var start_pos: Vector2i = outline.keys().pick_random()

    #     var ordered_outline = _generate_ordered_outline(outline, start_pos)

    #     for _i in 4:
    #         var line := _spawn_line(line_child2, 1.0, Color.BLACK)
    #         for i in ordered_outline.size():
    #             var tile_pos: Vector2i = ordered_outline[i]
    #             var global_pos := map.to_global(map.map_to_local(tile_pos))
    #             var normal_dir := _get_outline_outer_normal(tile_pos)
    #             line.add_point(global_pos + normal_dir * randf_range(1.0, 8.0))
    #         line.add_point(line.points[0])

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

func _generate_ordered_outline(outline: Dictionary, start_pos: Vector2i) -> Array:
    var tiles := []

    var og_start := start_pos

    var failed_count := 0
    while failed_count < 4:
        failed_count = 0
        for d in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
            og_start = start_pos
            start_pos = _ordered_outline_4d_yeet(tiles, outline, start_pos, d)
            failed_count += int(start_pos == og_start)

    if tiles.size() == 0 and og_start == start_pos:
        tiles.append(start_pos)
        outline.erase(start_pos)
    
    _ordered_outline_8d_yeet(tiles, outline, start_pos, Vector2i.LEFT + Vector2i.UP)
    _ordered_outline_8d_yeet(tiles, outline, start_pos, Vector2i.LEFT + Vector2i.DOWN)
    _ordered_outline_8d_yeet(tiles, outline, start_pos, Vector2i.RIGHT + Vector2i.UP)
    _ordered_outline_8d_yeet(tiles, outline, start_pos, Vector2i.RIGHT + Vector2i.DOWN)
    
    return tiles

func _ordered_outline_4d_yeet(tiles: Array, outline: Dictionary, start_pos: Vector2i, dir: Vector2i) -> Vector2i:
    if start_pos + dir in outline:
        # print("Marking ", start_pos)
        tiles.append(start_pos)
        outline.erase(start_pos)
        while start_pos + dir in outline:
            start_pos += dir
            # print("Marking ", start_pos)
            tiles.append(start_pos)
            outline.erase(start_pos)
    return start_pos

func _ordered_outline_8d_yeet(tiles: Array, outline: Dictionary, start_pos: Vector2i, dir: Vector2i) -> void:
    if start_pos + dir in outline:
        var gen_outline := _generate_ordered_outline(outline, start_pos + dir)
        tiles.append_array(gen_outline)

func _generate_zone_outline(seed_pos: Vector2) -> Dictionary:
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