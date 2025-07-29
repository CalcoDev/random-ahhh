@tool
extends Node2D

@export var spawn_parts := false:
    set(value):
        spawn_parts = false
        do_stuff()

@export var update_stuff := false

@export var sparks_renderer: SparksRenderer

func do_stuff() -> void:
    for i in 1:
        sparks_renderer.spawn_spark(global_position, Vector2(4, 4), randf() - 0.5 + PI, 0.5)


func _process(delta: float) -> void:
    if Engine.is_editor_hint() and update_stuff:
        sparks_renderer.process_sparks(delta)