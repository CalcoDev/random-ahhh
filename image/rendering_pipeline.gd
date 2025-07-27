extends Node

@export var wall_map: TextureRect

@export var vp_seed: SubViewport
var tex_seed: ShaderMaterial

@export var vp_jfa_pass: SubViewport
# @export var jfa_pass_cnt: int = 8

@export var vp_distance_pass: SubViewport

@export var debug_subviewport_container: SubViewportContainer

var jfa_passes: Array[SubViewport] = []

func _ready() -> void:
    vp_seed.get_child(0).texture = ImageTexture.create_from_image(Image.create_empty(240, 240, false, Image.FORMAT_RGBAF))
    tex_seed = vp_seed.get_child(0).material as ShaderMaterial

    vp_jfa_pass.get_child(0).texture = ImageTexture.create_from_image(Image.create_empty(240, 240, false, Image.FORMAT_RGBAF))
    vp_distance_pass.get_child(0).texture = ImageTexture.create_from_image(Image.create_empty(240, 240, false, Image.FORMAT_RGBAF))

    var passes = ceil(log(240.0) / log(2.0))
    for i in passes:
        var offset := pow(2, passes - i - 1)
        var render_pass: SubViewport
        if i == 0:
            render_pass = vp_jfa_pass
        else:
            render_pass = vp_jfa_pass.duplicate()
            add_child(render_pass)
        
        render_pass.get_child(0).material = render_pass.get_child(0).material.duplicate(0)
        jfa_passes.append(render_pass)

        # var input_texture := vp_seed.get_texture()
        var input_texture: Texture2D
        if i == 0:
            input_texture = vp_seed.get_texture()
        else:
            input_texture = jfa_passes[i - 1].get_texture()
        
        # set size and shader uniforms for this pass.
        # render_pass.set_size(240.0)
        render_pass.get_child(0).material.set_shader_parameter("u_level", i)
        render_pass.get_child(0).material.set_shader_parameter("u_max_steps", passes)
        render_pass.get_child(0).material.set_shader_parameter("u_offset", offset)
        render_pass.get_child(0).material.set_shader_parameter("u_input_tex", input_texture)
    
    var last_pass := jfa_passes[jfa_passes.size() - 1]
    # last_pass.get_parent().remove_child(last_pass)
    # last_pass.reparent(debug_subviewport_container)

    vp_distance_pass.get_child(0).material.set_shader_parameter("u_input_tex", last_pass.get_texture())
    
    # last_pass.reparent(debug_subviewport_container)
    vp_distance_pass.call_deferred("reparent", debug_subviewport_container)

func _process(_delta: float) -> void:
    tex_seed.set_shader_parameter("u_input_tex", wall_map.texture)