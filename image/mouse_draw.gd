extends TextureRect

var WALL_COLOR := Color.hex(0x111111ff)

func _ready() -> void:
    var img := Image.create_empty(240, 240, false, Image.FORMAT_RGBAF)

    _bergen_circle(img, img.get_size() / 2.0, 105, true)
    _bergen_circle(img, Vector2(80, 30), 15)
    _bergen_circle(img, Vector2(47, 89), 30)
    _bergen_circle(img, Vector2(15, 149), 15)
    _bergen_circle(img, Vector2(240 - 80, 240 - 30), 15)
    _bergen_circle(img, Vector2(240 - 47, 240 - 89), 30)
    _bergen_circle(img, Vector2(240 - 15, 240 - 149), 15)
    _bergen_circle(img, Vector2(120, 120), 27)

    self.texture = ImageTexture.create_from_image(img)


var brush_size := 20.0

var prev_mouse := Vector2.ZERO
func _process(_delta: float) -> void:
    var place_or_unplace := Input.get_axis("undraw", "draw")

    var dsize := \
        (1 if Input.is_action_just_released("size_up") else 0) - \
        (1 if Input.is_action_just_released("size_down") else 0)
    brush_size += dsize
    brush_size = clampf(brush_size, 5, 100)

    if abs(place_or_unplace) > 0.01:
        var colour := WALL_COLOR if place_or_unplace > 0.0 else Color.TRANSPARENT
        var mouse := get_global_mouse_position()

        var img := self.texture.get_image()
        for y in brush_size:
            for x in brush_size:
                var off := Vector2(x - brush_size / 2.0, y - brush_size / 2.0)
                if off.length_squared() < brush_size * brush_size / 4.0:
                    var xx := roundi(mouse.x + off.x)
                    var yy := roundi(mouse.y + off.y)
                    if xx >= 0 and yy >= 0 and xx < 240 and yy < 240:
                        img.set_pixel(xx, yy, colour)
        
        self.texture = ImageTexture.create_from_image(img)
        prev_mouse = mouse

func _bergen_circle(img: Image, c: Vector2, d: float, invert: bool = false) -> void:
    for y in img.get_height():
        for x in img.get_width():
            if Vector2(x, y).distance_squared_to(c) <= d * d:
                if not invert:
                    img.set_pixel(x, y, WALL_COLOR)
            else:
                if invert:
                    img.set_pixel(x, y, WALL_COLOR)