extends Node2D

@export var polygon: Polygon2D

func _ready() -> void:
    var points := polygon.polygon
    # print(points)
    var decomp := Geometry2D.decompose_polygon_in_convex(points)
    print(decomp)

    for poly in decomp:
        var p := Polygon2D.new()
        p.polygon = poly
        add_child(p)
        p.color = Color.from_rgba8(255, 0, 0, 255)