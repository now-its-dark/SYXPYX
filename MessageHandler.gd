# MessageHandler.gd
extends Node
class_name MessageHandler

enum TransmitMode { MANUAL, PREVIEW, ANIM_PREVIEW }

var current_transmit_mode = TransmitMode.MANUAL
var midi_manager = MidiManager.new()
var current_standard = BitmapFormatter.get_available_standards().values()[0]
var pixel_canvas: Node

func _ready():
	pixel_canvas = get_node("../PixelCanvas")
	pixel_canvas.pixel_states_changed.connect(_on_pixel_states_changed)

func _on_pixel_states_changed(states: Array):
	if (current_transmit_mode == TransmitMode.PREVIEW) or (current_transmit_mode == TransmitMode.ANIM_PREVIEW and pixel_canvas.is_playing):
		send_message(states)

func set_mode(mode: TransmitMode):
	current_transmit_mode = mode
	print("Set to " + ("Manual" if mode == TransmitMode.MANUAL else "Preview") + " transmission mode")

func send_message(pixel_states: Array):
	var message = current_standard.create_message(pixel_states)
	if midi_manager.send_message(message):
		print("Successfully sent MIDI message")
	else:
		print("Failed to send message - no MIDI port open")

func toggle_preview():
	current_transmit_mode = TransmitMode.PREVIEW if current_transmit_mode != TransmitMode.PREVIEW else TransmitMode.MANUAL
	print("Preview mode " + ("enabled" if current_transmit_mode == TransmitMode.PREVIEW else "disabled"))

func toggle_anim_preview():
	current_transmit_mode = TransmitMode.ANIM_PREVIEW if current_transmit_mode != TransmitMode.ANIM_PREVIEW else TransmitMode.MANUAL
	print("Animation preview " + ("enabled" if current_transmit_mode == TransmitMode.ANIM_PREVIEW else "disabled"))

func set_port(port_index: int) -> bool:
	return midi_manager.open_port(port_index)

func set_standard(standard):
	current_standard = standard
