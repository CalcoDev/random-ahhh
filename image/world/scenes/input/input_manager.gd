extends Node2D
class_name Inp_manager_hidden

class Data:
	var move_vec := Vector2.ZERO
	var last_nonzero_move_vec := Vector2.ZERO

	var mouse_pos := Vector2.ZERO

	# var interact := IKey.new()
	var dash := IKey.new()
	var fire_weapon := IKey.new()

func _update(delta: float) -> void:
	self.data.move_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if self.data.move_vec.length_squared() > 0.01:
		self.data.last_nonzero_move_vec = self.data.move_vec
	self.data.mouse_pos = get_global_mouse_position()
	self.data.dash.update_from_input("dash", delta)
	self.data.fire_weapon.update_from_input("fire_weapon", delta)
	# self.data.split.update_from_input("split", delta)
	# self.data.swap_body_control.update_from_input("swap_body_control", delta)
	# self.data.interact.update_from_input("interact", delta)


# internal stuff after this

var data := Data.new()

var update_process := true:
	set(value):
		update_process = value
		update_self = update_self
var update_self := true:
	set(value):
		update_self = value
		if update_self:
			if update_process:
				set_process(true)
			else:
				set_physics_process(true)
		else:
			set_process(false)
			set_physics_process(false)

func _enter_tree() -> void:
	# trigger updates
	self.update_process = true
	self.update_self = true

# todo: do this by instantiating order instead
func _ready() -> void:
	self.process_priority = -999

func _process(delta: float) -> void:
	self._update(delta)

func _physics_process(delta: float) -> void:
	self._update(delta)