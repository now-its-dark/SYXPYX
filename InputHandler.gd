extends Node
class_name InputHandler

enum UIState {
	DRAWING,    # Normal canvas interaction
	MENU_OPEN,  # Menu overlay active
	PLAYBACK,   # Animation playing
	MIDI_CONTROLLED  # For MIDI-triggered actions
}

var pixel_canvas: Node  # Add type hint
var current_state = UIState.DRAWING
var drawing_enabled_states = [UIState.DRAWING]

class Commands:
	var nodes

	func _init(n):
		nodes = n
		nodes.midi_manager.midi_message_received.connect(_on_midi_message)

	func toggle_menu():
		nodes.menu_overlay.toggle()
		nodes.input_handler.current_state = UIState.MENU_OPEN if nodes.menu_overlay.visible else UIState.DRAWING

	func _on_midi_message(message):
		if nodes.input_handler.current_state == UIState.MIDI_CONTROLLED:
			# Handle MIDI-triggered state changes
			pass

	func switch_tool():
		if nodes.pixel_canvas.current_tool == nodes.pixel_canvas.Tool.DRAW:
			nodes.pixel_canvas.current_tool = nodes.pixel_canvas.Tool.ERASE
		else:
			nodes.pixel_canvas.current_tool = nodes.pixel_canvas.Tool.DRAW
		nodes.pixel_canvas.queue_redraw()

	func undo():
		nodes.pixel_canvas.undo()

	func redo():
		nodes.pixel_canvas.redo()

	func copy_frame():
		nodes.pixel_canvas.copy_current_frame()

	func paste_frame():
		if not nodes.pixel_canvas.is_playing:
			nodes.pixel_canvas.paste_to_current_frame()

	func duplicate_frame():
		if not nodes.pixel_canvas.is_playing:
			nodes.pixel_canvas.duplicate_current_frame()

	func new_frame():
		nodes.pixel_canvas.add_new_frame(false)

	func new_frame_at_end():
		nodes.pixel_canvas.add_new_frame(true)

	func delete_frame():
		if not nodes.pixel_canvas.is_playing:
			nodes.pixel_canvas.delete_current_frame()

	func clear_pixels():
		if not nodes.pixel_canvas.is_playing:
			nodes.pixel_canvas.clear_all_pixels()

	func prev_frame():
		nodes.pixel_canvas.handle_frame_change(-1)

	func next_frame():
		nodes.pixel_canvas.handle_frame_change(1)

	func toggle_playback():
		nodes.pixel_canvas.is_playing = !nodes.pixel_canvas.is_playing
		nodes.pixel_canvas.playback_timer = 0.0
		nodes.input_handler.current_state = UIState.PLAYBACK if nodes.pixel_canvas.is_playing else UIState.DRAWING

	func send_message():
		nodes.message_handler.send_message(nodes.pixel_canvas.pixel_states)

	func toggle_preview():
		nodes.message_handler.toggle_preview()

	func toggle_anim_preview():
		nodes.message_handler.toggle_anim_preview()

var commands: Commands
var menu_overlay: Node
var message_handler: Node
var midi_manager: Node

var command_labels = [
	"Toggle Menu",
	"Switch Drawing Tool",
	"Toggle Preview Mode",
	"Undo",
	"Redo",
	"Copy Frame",
	"Paste Frame",
	"Duplicate Frame",
	"New Frame",
	"New Frame at End",
	"Delete Frame",
	"Clear Pixels",
	"Previous Frame",
	"Next Frame",
	"Toggle Playback",
	"Toggle Animation Preview",
	"Send MIDI Message",
]

var command_map = {
	"Toggle Menu": "toggle_menu",
	"Switch Drawing Tool": "switch_tool",
	"Toggle Preview Mode": "toggle_preview",
	"Undo": "undo",
	"Redo": "redo",
	"Copy Frame": "copy_frame",
	"Paste Frame": "paste_frame",
	"Duplicate Frame": "duplicate_frame",
	"New Frame": "new_frame",
	"New Frame at End": "new_frame_at_end",
	"Delete Frame": "delete_frame",
	"Clear Pixels": "clear_pixels",
	"Previous Frame": "prev_frame",
	"Next Frame": "next_frame",
	"Toggle Playback": "toggle_playback",
	"Toggle Animation Preview": "toggle_anim_preview",
	"Send MIDI Message": "send_message"
}

var input_map = {
	"Toggle Menu": {
		"commands": ["toggle_menu"],
		"valid_states": [UIState.DRAWING, UIState.MENU_OPEN]
	},
	"Switch Drawing Tool": {
		"commands": ["switch_tool"],
		"valid_states": [UIState.DRAWING]
	},
	"Undo": {
		"commands": ["undo"],
		"valid_states": [UIState.DRAWING]
	},
	"Redo": {
		"commands": ["redo"],
		"valid_states": [UIState.DRAWING]
	},
	"Copy Frame": {
		"commands": ["copy_frame"],
		"valid_states": [UIState.DRAWING, UIState.PLAYBACK]
	},
	"Paste Frame": {
		"commands": ["paste_frame"],
		"valid_states": [UIState.DRAWING]
	},
	"Duplicate Frame": {
		"commands": ["duplicate_frame"],
		"valid_states": [UIState.DRAWING]
	},
	"New Frame": {
		"commands": ["new_frame"],
		"valid_states": [UIState.DRAWING]
	},
	"New Frame at End": {
		"commands": ["new_frame_at_end"],
		"valid_states": [UIState.DRAWING]
	},
	"Delete Frame": {
		"commands": ["delete_frame"],
		"valid_states": [UIState.DRAWING]
	},
	"Clear Pixels": {
		"commands": ["clear_pixels"],
		"valid_states": [UIState.DRAWING]
	},
	"Previous Frame": {
		"commands": ["prev_frame"],
		"valid_states": [UIState.DRAWING, UIState.PLAYBACK]
	},
	"Next Frame": {
		"commands": ["next_frame"],
		"valid_states": [UIState.DRAWING, UIState.PLAYBACK]
	},
	"Toggle Playback": {
		"commands": ["toggle_playback"],
		"valid_states": [UIState.DRAWING, UIState.PLAYBACK]
	},
	"Toggle Animation Preview": {
		"commands": ["toggle_anim_preview"],
		"valid_states": [UIState.DRAWING, UIState.PLAYBACK]
	},
	"Send MIDI Message": {
		"commands": ["send_message"],
		"valid_states": [UIState.DRAWING, UIState.PLAYBACK]
	},
	"Toggle Preview Mode": {
		"commands": ["toggle_preview"],
		"valid_states": [UIState.DRAWING, UIState.PLAYBACK]
	}

}

func _ready():
	pixel_canvas = get_node("../PixelCanvas")
	menu_overlay = get_node("../MenuOverlay")
	message_handler = get_node("../MessageHandler")
	midi_manager = get_node("../MidiManager")

	commands = Commands.new({
		"pixel_canvas": pixel_canvas,
		"menu_overlay": menu_overlay,
		"message_handler": message_handler,
		"midi_manager": midi_manager,
		"input_handler": self
	})

	# Add commands to Input Map with default bindings
	var default_bindings = {
		"Toggle Menu": KEY_ESCAPE,
		"Switch Drawing Tool": KEY_E,
		"Undo": [KEY_Z, KEY_CTRL],
		"Redo": [KEY_Y, KEY_CTRL],
		"Copy Frame": [KEY_C, KEY_CTRL],
		"Paste Frame": [KEY_V, KEY_CTRL],
		"Duplicate Frame": [KEY_D, KEY_CTRL],
		"New Frame": KEY_N,
		"New Frame at End": [KEY_N, KEY_SHIFT],
		"Delete Frame": [KEY_DELETE, KEY_SHIFT],
		"Clear Pixels": KEY_DELETE,
		"Previous Frame": KEY_LEFT,
		"Next Frame": KEY_RIGHT,
		"Toggle Playback": KEY_SPACE,
		"Toggle Animation Preview": [KEY_SPACE, KEY_SHIFT],
		"Send MIDI Message": KEY_ENTER,
		"Toggle Preview Mode": [KEY_ENTER, KEY_SHIFT],
	}

	for label in command_labels:
		if not InputMap.has_action(label):
			InputMap.add_action(label)
			if label in default_bindings:
				var event = InputEventKey.new()
				if default_bindings[label] is Array:
					event.keycode = default_bindings[label][0]
					event.shift_pressed = KEY_SHIFT in default_bindings[label]
					event.ctrl_pressed = KEY_CTRL in default_bindings[label]
				else:
					event.keycode = default_bindings[label]
				InputMap.action_add_event(label, event)

func _input(event):
				# Keyboard input handling
				for action in input_map.keys():
								if event.is_action_pressed(action):
												var mapping = input_map[action]
												if current_state in mapping.valid_states:
																for command in mapping.commands:
																				commands.call(command)

				# Mouse input handling - check against allowed states
				if current_state in drawing_enabled_states:
								if event is InputEventMouseButton or event is InputEventMouseMotion:
												pixel_canvas._input(event)
