@tool
extends Node

@export var word: String
@export var template_lbl: RichTextLabel
@export var parent: Node

@export var gen_word := false:
    set(value):
        for child in parent.get_children():
            parent.remove_child(child)
            child.queue_free()
        gen_word = false
        for c in word:
            var l := template_lbl.duplicate() as RichTextLabel
            l.name = "[" + word + "] " + c
            l.text = c
            parent.add_child(l)
            if Engine.is_editor_hint():
                l.owner = get_tree().edited_scene_root
