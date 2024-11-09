# pyxels2Syxels.gd
class_name BitmapFormatter

# Static helper function for Roland-style checksum
static func calculate_roland_checksum(data: Array) -> int:
	var sum = 0
	for byte in data:
		sum += byte
	sum = sum & 0x7F  # Take least significant 7 bits
	return 128 - sum  # Roland-style checksum

static func get_available_standards() -> Dictionary:
	return {
		"Yamaha XG": YamahaXG.new(),
		"Yamaha TG300": YamahaTG300.new(),  # mostly the same as XG, but uses Roland Checksum
		"Roland SC-55": RolandSC55.new(),  # mostly the same as XG
		# "Roland GS": RolandGS.new(),  # For when we add this
		# Add more standards here as they're created
	}

# Base class for different bitmap standards
class BitmapStandard:
	func create_message(_pixels: Array) -> PackedByteArray:
		return PackedByteArray()  # Override in child classes

	static func calculate_roland_checksum(data: Array) -> int:
		var sum = 0
		for byte in data:
			sum += byte
		sum = sum & 0x7F  # Take least significant 7 bits
		return 128 - sum  # Roland-style checksum

class YamahaXG extends BitmapStandard:
	const SYSEX_START = 0xF0
	const MANUFACTURER_ID = 0x43
	const DEVICE_NUM = 0x10
	const MODEL_ID = 0x4C
	const DISPLAY_ADDR_HIGH = 0x07
	const DISPLAY_ADDR_LOW = 0x00
	const SYSEX_END = 0xF7

	func create_message(pixels: Array) -> PackedByteArray:
		var message = PackedByteArray()

		# SysEx header
		message.append_array([SYSEX_START, MANUFACTURER_ID, DEVICE_NUM,
							MODEL_ID, DISPLAY_ADDR_HIGH, DISPLAY_ADDR_LOW, 0x00])

		# First slice (columns 0-6)
		for row in range(16):
			var byte = 0
			for col in range(7):
				if pixels[row][col]:
					byte |= (1 << (6 - col))
			message.append(byte)

		# Second slice (columns 7-13)
		for row in range(16):
			var byte = 0
			for col in range(7):
				if pixels[row][col + 7]:
					byte |= (1 << (6 - col))
			message.append(byte)

		# Third slice (columns 14-15)
		for row in range(16):
			var byte = 0
			for col in range(2):
				if pixels[row][col + 14]:
					byte |= (1 << (6 - col))
			message.append(byte)

		message.append(SYSEX_END)
		return message

class YamahaTG300 extends BitmapStandard:
	const SYSEX_START = 0xF0
	const MANUFACTURER_ID = 0x43
	const DEVICE_NUM = 0x10
	const MODEL_ID = 0x2B
	const DISPLAY_ADDR_HIGH = 0x07
	const DISPLAY_ADDR_LOW = 0x01
	const SYSEX_END = 0xF7

	func create_message(pixels: Array) -> PackedByteArray:
		var message = PackedByteArray()

		# SysEx header
		message.append_array([SYSEX_START, MANUFACTURER_ID, DEVICE_NUM,
							MODEL_ID, DISPLAY_ADDR_HIGH, DISPLAY_ADDR_LOW, 0x00])

		# Store position where checksum calculation should start
		var checksum_start = message.size() - 3  # Start after F0 43 10 2B

		# First slice (columns 0-6)
		for row in range(16):
			var byte = 0
			for col in range(7):
				if pixels[row][col]:
					byte |= (1 << (6 - col))
			message.append(byte)

		# Second slice (columns 7-13)
		for row in range(16):
			var byte = 0
			for col in range(7):
				if pixels[row][col + 7]:
					byte |= (1 << (6 - col))
			message.append(byte)

		# Third slice (columns 14-15)
		for row in range(16):
			var byte = 0
			for col in range(2):
				if pixels[row][col + 14]:
					byte |= (1 << (6 - col))
			message.append(byte)

		# Calculate Roland-style checksum
		var checksum = calculate_roland_checksum(message.slice(checksum_start))
		message.append(checksum)
		message.append(SYSEX_END)
		return message

class RolandSC55 extends BitmapStandard:
	const SYSEX_START = 0xF0
	const MANUFACTURER_ID = 0x41
	const DEVICE_NUM = 0x10
	const MODEL_ID = 0x45
	const DISPLAY_ADDR_HIGH = 0x10
	const DISPLAY_ADDR_LOW = 0x01
	const SYSEX_END = 0xF7

	func create_message(pixel_states: Array) -> PackedByteArray:
		var message = PackedByteArray()
		message.append_array([0xF0, 0x41, 0x10, 0x45, 0x12])  # Device header

		var checksum_data = []  # Collect bytes that should be part of checksum

		# Add address and data bytes (these will be included in checksum)
		checksum_data.append_array([0x10, 0x01, 0x00])  # Address bytes

		# Add data bytes (process grid in 5-column sections)
		for section in range(4):
			for row in range(16):
				var byte = 0
				for bit in range(5):
					var col = section * 5 + bit
					if col < 16 and pixel_states[row][col]:
						byte |= (1 << (4 - bit))
				checksum_data.append(byte)

		# Add these bytes to message
		message.append_array(checksum_data)

		# Calculate and add checksum
		message.append(calculate_roland_checksum(checksum_data))
		message.append(0xF7)

		return message
