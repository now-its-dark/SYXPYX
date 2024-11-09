extends ColorRect

var message_handler: Node  # Changed to Node for now
var port_selector: OptionButton
var standard_selector: OptionButton

func _ready():
	color = Color(0, 0, 0, 0.8)
	hide()

	message_handler = get_node("../MessageHandler")
	port_selector = $"Menu Container/Port Selection/Port Selector"
	standard_selector = $"Menu Container/Device Selection/Device Selector"

	if port_selector:
		port_selector.clear()
		port_selector.add_item("Select MIDI Port")
		var port_names = MidiOut.get_port_names()
		for i in range(port_names.size()):
			port_selector.add_item(port_names[i], i + 1)

		port_selector.item_selected.connect(_on_port_selector_item_selected)

	if standard_selector:
		# Setup standard selector
		standard_selector.clear()
		standard_selector.add_item("Select Device Type")
		var standards = BitmapFormatter.get_available_standards()
		var index = 1
		for standard_name in standards:
			standard_selector.add_item(standard_name, index)
			index += 1

		standard_selector.item_selected.connect(_on_standard_selected)

	# Connect to MidiManager signals
	message_handler.midi_manager.ports_changed.connect(_on_ports_changed)
	message_handler.midi_manager.port_disconnected.connect(_on_port_disconnected)
	message_handler.midi_manager.port_connected.connect(_on_port_connected)

func _update_port_list():
	if not port_selector:
		return

	var currently_selected = port_selector.get_selected_id()
	var current_ports = MidiOut.get_port_names()

	port_selector.clear()
	port_selector.add_item("Select MIDI Port")

	for i in range(current_ports.size()):
		port_selector.add_item(current_ports[i], i + 1)

	# Try to restore previous selection if it still exists
	if currently_selected > 0:
		for i in range(port_selector.item_count):
			if port_selector.get_item_id(i) == currently_selected:
				port_selector.select(i)
				break

func _on_ports_changed(_ports: PackedStringArray):
	print("Received ports_changed signal")  # Debug
	_update_port_list()

func _on_port_disconnected():
	_update_port_list()
	print("MIDI port disconnected")

func _on_port_connected(port_name: String):
	_update_port_list()
	print("New MIDI port connected: ", port_name)

func _on_port_selector_item_selected(index: int):
	if index > 0:  # Skip the "Select MIDI Port" option
		if message_handler.midi_manager.open_port(index - 1):
			print("Connected to MIDI port: ", MidiOut.get_port_name(index - 1))

func _on_standard_selected(index: int):
	if index > 0:
		var standards = BitmapFormatter.get_available_standards()
		var standard_name = standard_selector.get_item_text(index)
		if standard_name in standards:
			message_handler.set_standard(standards[standard_name])
			print("Changed to " + standard_name + " format")

func toggle():
	visible = !visible
