extends HBoxContainer

@export var freq := 5.0
@export var ampl := 10.0
@export var phase_offset := 0.5

func _process(_delta: float) -> void:
    var total := get_child_count()
    for i in total:
        var child := get_child(i) as Control
        child.position.y = sin(Time.get_ticks_msec() / 1000.0 * freq + i * phase_offset) * ampl