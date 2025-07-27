extends Polygon2D

func _ready() -> void:
    # var things := Geometry2D.offset_polygon(polygon.duplicate(), 10)
    var things := Geometry2D.convex_hull(polygon)
    # for thing in things:
    var a := Geometry2D.clip_polygons(things.duplicate(), polygon)
    # var b := Geometry2D.clip_polygons(things.duplicate(), a)
    polygons
    # for t in a:
    #     var p := Polygon2D.new()
    #     p.polygon = t
    #     add_child(p)
    #     p.color = Color.from_rgba8(255, 0, 0, 255)
