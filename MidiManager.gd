# MidiManager.gd
extends Node
class_name MidiManager

var midi_out = MidiOut.new()
var current_port_index = -1
var desired_port_name = ""
var check_timer: Timer
var last_port_list: PackedStringArray = PackedStringArray([])
signal midi_message_received(message)
signal ports_changed(ports: PackedStringArray)
signal port_disconnected
signal port_connected(port_name: String)

func _ready():
	check_timer = Timer.new()
	add_child(check_timer)
	check_timer.wait_time = 1.0
	check_timer.timeout.connect(_check_ports)
	check_timer.start()
	last_port_list = MidiOut.get_port_names()

func _init():
	print("Available MIDI Output Ports:")
	for i in range(MidiOut.get_port_count()):
		print("%d: %s" % [i, MidiOut.get_port_name(i)])

func _check_ports():
#	print("Checking ports...")
	# Recreate MidiOut instance to get fresh port list
	midi_out = MidiOut.new()
	var current_ports = MidiOut.get_port_names()
#	print("Current ports: ", current_ports)

	# Check for changes in port list
	if current_ports != last_port_list:
		print("Port list changed!")
		emit_signal("ports_changed", current_ports)

		# Check for new ports
		for port in current_ports:
			if not port in last_port_list:
				print("New port found: ", port)
				emit_signal("port_connected", port)

	last_port_list = current_ports

	if desired_port_name != "":
		for i in range(current_ports.size()):
			if current_ports[i] == desired_port_name and current_port_index != i:
				open_port(i)
				return

	if current_port_index >= 0:
		if current_port_index >= current_ports.size() or not midi_out.is_port_open():
			midi_out.close_port()
			current_port_index = -1
			emit_signal("port_disconnected")

func open_port(port_index: int) -> bool:
	if midi_out.is_port_open():
		midi_out.close_port()

	if port_index >= 0 and port_index < MidiOut.get_port_count():
		midi_out.open_port(port_index)
		current_port_index = port_index
		desired_port_name = MidiOut.get_port_name(port_index)
		print("Opened MIDI port: ", MidiOut.get_port_name(port_index))
		return true
	return false

func close_port():
	if midi_out.is_port_open():
		midi_out.close_port()
		current_port_index = -1

func send_message(message: PackedByteArray):
	if midi_out.is_port_open():
		midi_out.send_message(message)
		return true
	return false

func get_port_names() -> PackedStringArray:
	return MidiOut.get_port_names()
