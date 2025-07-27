@tool
extends Node

@export var map: TileMapLayer
@export var line_child: Node
@export var line_child2: Node

@export var zones: Array[Marker2D]

@export var generate_zones: bool = false:
    set(value):
        generate_zones = false
        _generate_zones()

func _generate_path(cell: Vector2i, outline: Dictionary, points: Array) -> void:
    var dirs_to_index: Dictionary[String, int] = {"left": 0, "right": 1, "down": 2, "up": 3}
    var dirs: Array[String] = ["left", "right", "down", "up"]
    var normals: Array[Vector2i] = [
        Vector2i(-1, 0), Vector2i(1, 0),
        Vector2i(0, 1), Vector2i(0, -1), 
    ]
    var order = {
        "up": "right",
        "right": "down",
        "down": "left",
        "left": "up"
    }

    print("gen path: ", cell)
    var ogcell := cell
    for i in 4:
        var dir := dirs[i]
        if cell in outline and outline[cell][dir]:
            var go_dir_str: String = order[dir]
            var go_dir := normals[dirs_to_index[go_dir_str]]
            while cell + go_dir in outline:
                points.append(cell)
                outline.erase(cell)
                cell += go_dir
            outline[cell][dir] = false
            _generate_path(cell, outline, points)
    outline.erase(ogcell)

func _generate_zones() -> void:
    for child in line_child.get_children():
        line_child.remove_child(child)
    for child in line_child2.get_children():
        line_child2.remove_child(child)

    for marker in zones:
        var outlines := _fill_zone(marker.global_position)

        var dirs_to_index: Dictionary[String, int] = {"left": 0, "right": 1, "down": 2, "up": 3}
        var dirs: Array[String] = ["left", "right", "down", "up"]
        var normals: Array[Vector2i] = [
            Vector2i(-1, 0), Vector2i(1, 0),
            Vector2i(0, 1), Vector2i(0, -1), 
        ]
        var parallels: Array[Vector2i] = [
            Vector2i(0, 1), Vector2i(0, 1),
            Vector2(1, 0), Vector2i(1, 0)
        ]

        var order = {
            "up": "right",
            "right": "down",
            "down": "left",
            "left": "up"
        }

        var points := []
        if true:
            var o := outlines.duplicate()
            var cell: Vector2i = o.keys()[0]
            _generate_path(cell, o, points)
            print(points)
            # while true:
            #     for i in 4:
            #         var dir := dirs[i]
            #         if cell in o and o[cell][dir]:
            #             var go_dir_str: String = order[dir]
            #             var go_dir := normals[dirs_to_index[go_dir_str]]
            #             while cell + go_dir in o:
            #                 cell += go_dir


        # generate normal lines ahhh
        for cell in outlines:
            for i in 4:
                var dir := dirs[i]
                if outlines[cell][dir]:
                    var line := Line2D.new()
                    line_child.add_child(line)
                    line.width = 1.0
                    line.modulate = Color.RED
                    if Engine.is_editor_hint():
                        line.owner = get_tree().edited_scene_root
                    var global_cell_pos := map.to_global(map.map_to_local(cell))
                    var normal_dir := normals[i]
                    line.add_point(global_cell_pos + normal_dir * 16.0)
                    line.add_point(global_cell_pos + normal_dir * 1.0)

                    # points[global_cell_pos + normal_dir * 16.0] = true
        
        # var cell: Vector2i = outlines.keys()[0]


        # var line := Line2D.new()
        # line_child2.add_child(line)
        # line.width = 1.0
        # line.modulate = Color.DARK_BLUE
        # if Engine.is_editor_hint():
        #     line.owner = get_tree().edited_scene_root
        # for point in points:
        #     line.add_point(point)

        # generate big fricking bara transversala
        # var steps := 0
        # while outlines.size() > 0 and steps < 400:
        #     steps += 1
        #     var cell: Vector2i = outlines.keys().pick_random()

        #     # var ddirs := dirs.duplicate()
        #     # var dir := ""
        #     # while ddirs.size() > 0:
        #     #     dir = ddirs.pop_back()
        #     #     if not outlines[cell][dir]:
        #     #         continue
        #     for dir in dirs:
        #         if cell in outlines and outlines[cell][dir]:
        #             var perp_dir := parallels[dirs_to_index[dir]]

        #             var start := cell
        #             var end := start
        #             while (end + perp_dir) in outlines:
        #                 outlines[end + perp_dir]["sum"] -= 1
        #                 if outlines[end + perp_dir]["sum"] <= 0:
        #                     outlines.erase(end + perp_dir)
        #                 end += perp_dir
        #             # outlines[end]["sum"] -= 1
        #             # if outlines[end]["sum"] <= 0:
        #             #     outlines.erase(end)
        #             while (start - perp_dir) in outlines:
        #                 outlines[start - perp_dir]["sum"] -= 1
        #                 if outlines[start - perp_dir]["sum"] <= 0:
        #                     outlines.erase(start - perp_dir)
        #                 start -= perp_dir
        #             # outlines[start]["sum"] -= 1
        #             # if outlines[start]["sum"] <= 0:
        #             #     outlines.erase(start)
        #             print(cell, " ", dir, " Line finished: ", start, " ", end)

        #             var normal_dir := normals[dirs_to_index[dir]]

        #             var line := Line2D.new()
        #             line_child2.add_child(line)
        #             line.width = 1.0
        #             line.modulate = Color.BLACK
        #             if Engine.is_editor_hint():
        #                 line.owner = get_tree().edited_scene_root
                    
        #             start = map.to_global(map.map_to_local(start)) + normal_dir * 12.0
        #             end = map.to_global(map.map_to_local(end)) + normal_dir * 12.0

        #             line.add_point(start)
        #             line.add_point(end)

        #     outlines[cell]["sum"] -= 1
        #     if outlines[cell]["sum"] <= 0:
        #         outlines.erase(cell)


func _fill_zone(global_pos: Vector2) -> Dictionary:
    var local_pos := map.to_local(global_pos)
    var tile_pos := map.local_to_map(local_pos)
    var tiles: Array[Vector2i] = [tile_pos]

    var outlines: Dictionary = {}
    var checked: Dictionary[Vector2i, bool] = {}

    while tiles.size() > 0:
        var tpos: Vector2i = tiles.pop_back()
        var tile_data := map.get_cell_tile_data(tpos)
        if tile_data  != null or tpos in checked:
            continue
        checked[tpos] = true
        var ttpos := Vector2i.ZERO 
        var left := false
        var right := false
        var up := false
        var down := false
        ttpos = tpos + Vector2i(-1, 0)
        if map.get_cell_tile_data(ttpos) != null:
            left = true
        else:
            tiles.append(ttpos)
        ttpos = tpos + Vector2i(1, 0)
        if map.get_cell_tile_data(ttpos) != null:
            right = true
        else:
            tiles.append(ttpos)
        ttpos = tpos + Vector2i(0, -1)
        if map.get_cell_tile_data(ttpos) != null:
            up = true
        else:
            tiles.append(ttpos)
        ttpos = tpos + Vector2i(0, 1)
        if map.get_cell_tile_data(ttpos) != null:
            down = true
        else:
            tiles.append(ttpos)
        if left or right or up or down:
            var sum := int(left) + int(right) + int(up) + int(down)
            outlines[tpos] = {"left": left, "right": right, "down": down, "up": up, "sum": sum}
        
    return outlines