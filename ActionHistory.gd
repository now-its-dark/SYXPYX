class_name ActionHistory

enum ActionType {
	DRAW,
	ERASE,
	CLEAR,
	DELETE,
	PASTE,
	DUPLICATE,
}

class Action:
	var type: ActionType
	var data: Array[Dictionary]
	var frame_index: int

	func _init(action_type: ActionType, action_data: Array[Dictionary], frame_idx: int):
		type = action_type
		data = action_data
		frame_index = frame_idx

var history: Array[Action] = []
var current_index: int = -1

func add_action(action_type: ActionType, action_data: Array[Dictionary], frame_idx: int):
	if current_index < history.size() - 1:
		history = history.slice(0, current_index + 1)

	history.append(Action.new(action_type, action_data, frame_idx))
	current_index += 1

func can_undo() -> bool:
	print("Can undo check - Current index:", current_index)
	return current_index >= 0

func can_redo() -> bool:
	return current_index < history.size() - 1

func undo() -> Action:
	print("Undo attempted - Current index before:", current_index)
	if can_undo():
		current_index -= 1
		print("Undo successful - New current index:", current_index)
		return history[current_index + 1]
	print("Undo failed - History empty or at beginning")
	return null

func redo() -> Action:
	if can_redo():
		current_index += 1
		return history[current_index]
	return null

func clear():
	history.clear()
	current_index = -1
