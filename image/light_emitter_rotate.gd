extends ColorRect

@export var distance_field_vp: SubViewport

@export var rot_speed: float = 4.0
@export var rot_place: float = 1.0

@export var anim_speed: float = 1.0

@export var intensity: Curve
@export var falloff: Curve
@export var falloff_steps: Curve

var t := 0.0
var sign := 1.0

var angle := 0.0

func _ready() -> void:
    (self.material as ShaderMaterial).set_shader_parameter("u_distance_field_tex", distance_field_vp.get_texture())

func _process(delta: float) -> void:
    t += delta * sign * anim_speed
    if t > 1.0:
        sign = -1.0
        t = 1.0
    if t < 0.0:
        sign = 1.0
        t = 0.0

    angle += delta * rot_speed
    # var c := Vector2(0.5, 0.5)
    var c := Vector2(0, 0)
    var p := Vector2(cos(angle), sin(angle)) * rot_place

    var m := (self.material as ShaderMaterial)
    # m.set_shader_parameter("u_pos", c + p)
    # m.set_shader_parameter("u_intensity", intensity.sample(t))
    # m.set_shader_parameter("u_radial_falloff", falloff.sample(t))
    # m.set_shader_parameter("u_radial_falloff_steps", roundf(falloff_steps.sample(t)))