class_name IKey

# pressed this frame
var pressed := false
# released this frame
var released := false
var held := false

var held_time := 0.0
var released_time := 0.0

func update_from_input(name: StringName, delta: float) -> void:
    if self.pressed:
        self.held_time += delta
    else:
        self.held_time = 0.0
    
    if self.released:
        self.released_time += delta
    else:
        self.released_time = 0.0
    
    self.pressed = Input.is_action_just_pressed(name)
    self.released = Input.is_action_just_released(name)
    self.held = Input.is_action_pressed(name)