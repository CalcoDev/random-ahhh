@tool
extends Node

@export var tilemap_vp: SubViewport
@export var polygon_vp: SubViewport
@export var polygon_cutout_vp: SubViewport

@export var polygon_cutout: ColorRect
@export var tilemap_polygon_csg: ColorRect

@export var set_world: bool = false:
    set(value):
        set_world = false
        var world = get_parent().get_world_2d()
        polygon_vp.world_2d = world
        tilemap_vp.world_2d = world

@export var reset_world: bool = false:
    set(value):
        reset_world = false
        polygon_vp.world_2d = World2D.new()
        tilemap_vp.world_2d = World2D.new()

@export var set_materials: bool = false:
    set(value):
        set_materials = false
        if true:
            var mat := polygon_cutout.material as ShaderMaterial
            mat.set_shader_parameter("u_polygon_tex", polygon_vp.get_texture())
        
        if true:
            var mat := tilemap_polygon_csg.material as ShaderMaterial
            mat.set_shader_parameter("u_polygon_tex", polygon_cutout_vp.get_texture())
            mat.set_shader_parameter("u_tilemap_tex", tilemap_vp.get_texture())
        
        # if true:
        #     var mat := tilemap_inside_polygon.material as ShaderMaterial
        #     mat.set_shader_parameter("u_polygon_tex", polygon_vp.get_texture())
        #     mat.set_shader_parameter("u_tilemap_tex", tilemap_vp.get_texture())
        #     mat.set_shader_parameter("u_csg_tex", csg_vp.get_texture())