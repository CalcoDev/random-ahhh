@tool
class_name RoomManager
extends Node

@export var player: Node2D

# TODO(calco): obv will add support for more lights in the future, but for now, haha
@export var preview_lightcaster: PointLight2D

@export var rooms: Array[Room] = []

var _active: Room = null

const GROUP := &"room_manager_group"

func _notification(what: int) -> void:
    if what == NOTIFICATION_ENTER_TREE:
        add_to_group(GROUP)

static func get_instance(node: Node) -> RoomManager:
    return node.get_tree().get_first_node_in_group(GROUP)

func set_active_room(room: Room) -> void:
    assert(room in rooms, "Tried setting a nonexistent room to active!")
    print("Setting ", room.name, " to active!")
    if _active:
        # handle unactivating a room
        pass
    _active = room
    # handle activating a room

func _process(_delta: float) -> void:
    for lightcaster_data in _preview_lightcasters:
        var lightcaster := lightcaster_data["lightcaster"] as Node2D
        var door := lightcaster_data["door"] as Door
        lightcaster.position = door.get_door_to().get_room_position() + (preview_lightcaster.global_position - door.get_room_position())

    if not _active:
        return
    
    var kcam := KCamera.get_instance(self)
    var half_screen_size := get_viewport().get_visible_rect().size / kcam.zoom * 0.5
    var raycast := _active.get_raycast()
    for door_id in _active._doors:
        var door := _active._doors[door_id]

        door.disable_preview()

        if abs(player.global_position.y - door.position.y) > half_screen_size.y:
            continue
        if abs(player.global_position.x - door.position.x) > half_screen_size.x:
            continue

        raycast.global_position = player.global_position
        raycast.target_position = (door.get_room_position() - player.global_position)
        raycast.force_update_transform()
        raycast.force_raycast_update()
        if raycast.is_colliding():
            continue
        
        door.enable_preview()

        # Should render preview for this room
        var door_to := door.get_door_to()

        var preview_room_rect_size := door.to_room.get_room_rect_size()

        var preview_rect := door.get_room_preview_rect()
        preview_rect.position = -door_to.position + door.get_facing_dir_offset()
        preview_rect.size = preview_room_rect_size

        var preview_mat := preview_rect.material as ShaderMaterial
        preview_mat.set_shader_parameter("u_room_color_tex", door.to_room.get_color_vp().get_texture())
        preview_mat.set_shader_parameter("u_room_lightmask_tex", door.to_room.get_lightmask_vp().get_texture())

        var tex: Texture2D
        var lightmask_vp := _get_preview_lightmask_vp(_active, door)
        if lightmask_vp:
            tex = lightmask_vp.get_texture()
        else:
            _make_preview_lightmask_vp(_active, door)

            var img := Image.create_empty(roundi(preview_rect.size.x), roundi(preview_rect.size.y), false, Image.FORMAT_RGBA8)
            tex = ImageTexture.create_from_image(img)

        preview_mat.set_shader_parameter("u_preview_lightmask_tex", tex)

var _preview_lightmask_map: Dictionary[Door, SubViewport] = {}
var _preview_lightcasters := []

func _get_preview_lightmask_vp(_from_room: Room, door: Door) -> SubViewport:
    return _preview_lightmask_map.get(door, null)

func _make_preview_lightmask_vp(from_room: Room, door: Door) -> void:
    var vp := SubViewport.new()
    _preview_lightmask_map[door] = vp
    vp.size = door.to_room.get_room_rect_size()
    vp.disable_3d = true
    vp.transparent_bg = true
    vp.handle_input_locally = false
    vp.snap_2d_transforms_to_pixel = true
    vp.snap_2d_vertices_to_pixel = true
    vp.canvas_cull_mask = 1 << 19
    vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
    add_child(vp)
    vp.name = from_room.name + "_to_" + door.to_room.name + "_via_" + door.id + "_viewport"
    if Engine.is_editor_hint():
        vp.owner = get_tree().edited_scene_root
    
    # Copy to_room to visible viewport position
    for child in door.to_room.get_color_vp().get_children():
        if not child.is_in_group(Room.ROOM_PREVIEW_LIGHTMASK_COPY_GROUP):
            continue
        var clone := child.duplicate(0)
        vp.add_child(clone)
        clone.name = door.to_room.name + "_" + child.name
        if child is Node2D:
            child.position = Vector2.ZERO
    
    # Copy from_room according to door position
    for child in from_room.get_color_vp().get_children():
        if not child.is_in_group(Room.ROOM_PREVIEW_LIGHTMASK_COPY_GROUP):
            continue
        var clone := child.duplicate(0)
        vp.add_child(clone)
        clone.name = from_room.name + "_" + child.name
        if child is Node2D:
            clone.position = door.get_door_to().get_room_position() + (child.global_position - door.get_room_position())
        
    # copy all light casters
    var preview_light := preview_lightcaster.duplicate(0) as Node2D
    vp.add_child(preview_light)
    preview_light.name = "PreviewLightcaster"
    preview_light.position = door.get_door_to().get_room_position() + (preview_lightcaster.global_position - door.get_room_position())

    _preview_lightcasters.append({
        "lightcaster": preview_light,
        "door": door,
    })