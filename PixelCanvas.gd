extends Node2D

const GRID_SIZE = 16
const WIDTH_TO_HEIGHT_RATIO = 2
const TOOLBAR_WIDTH_RATIO = 0.1
const PLAYBACK_FPS = 12  # Standard animation framerate

signal pixel_states_changed(states: Array)
signal frame_state_changed(frame_index: int)
signal playback_frame_changed(frame_index: int)  # Specific to playback

enum Tool { DRAW, ERASE }

var state_mutex = Mutex.new()
var pixel_states = []
var is_drawing = false
var is_drawing_pixels = false
var current_tool = Tool.DRAW
var action_history = ActionHistory.new()
var erased_color = Color(0.8, 0.8, 0.8)
var current_action_pixels: Array[Dictionary] = []
var drawn_pixels = {}
var frames = []  # Array of pixel states for each frame
var current_frame_index = 0
const FRAME_THUMBNAIL_SIZE = 40  # Same as button_size.y
var frame_scroll_offset = 0  # For horizontal scrolling
var is_dragging_scrollbar = false
var drag_start_position = Vector2.ZERO
var drag_start_scroll = 0
var is_playing = false
var playback_timer = 0.0
var frame_copy_buffer = null  # For copy/paste operations

func _ready():
	# Initialize first frame
	pixel_states = []
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			row.append(false)
		pixel_states.append(row)

	# Add first frame to frames array
	frames.append(pixel_states.duplicate(true))
	set_process_input(false)
	set_process(true)  # Enable _process
	var window = get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.mode = Window.MODE_WINDOWED

func _process(delta):
	if is_playing:
		playback_timer += delta
		if playback_timer >= 1.0 / PLAYBACK_FPS:
			playback_timer = 0.0
			if current_frame_index < frames.size() - 1:
				frames[current_frame_index] = pixel_states.duplicate(true)
				current_frame_index += 1
				pixel_states = frames[current_frame_index].duplicate(true)
				emit_signal("pixel_states_changed", pixel_states)
				queue_redraw()
			else:
				frames[current_frame_index] = pixel_states.duplicate(true)
				current_frame_index = 0
				pixel_states = frames[current_frame_index].duplicate(true)
				emit_signal("pixel_states_changed", pixel_states)
				queue_redraw()

func get_current_frame_data_safe() -> Array:
	state_mutex.lock()
	var data = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			data.append(pixel_states[y][x])
	state_mutex.unlock()
	return data

func get_current_frame_bytes_safe() -> PackedByteArray:
	state_mutex.lock()
	var bytes = PackedByteArray()
	var current_byte = 0
	var bit_position = 0

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if pixel_states[y][x]:
				current_byte |= (1 << bit_position)
			bit_position += 1
			if bit_position == 8:
				bytes.append(current_byte)
				current_byte = 0
				bit_position = 0

	if bit_position > 0:
		bytes.append(current_byte)

	state_mutex.unlock()
	return bytes

func handle_frame_change(direction: int):
	var new_index = current_frame_index + direction
	if new_index >= 0 and new_index < frames.size():
		frames[current_frame_index] = pixel_states.duplicate(true)
		current_frame_index = new_index
		pixel_states = frames[current_frame_index].duplicate(true)
		emit_signal("pixel_states_changed", pixel_states)
		queue_redraw()

func _draw():
	print("_draw function called")
	var viewport_size = get_viewport_rect().size
	var toolbar_width = viewport_size.x * TOOLBAR_WIDTH_RATIO
	var canvas_width = viewport_size.x - toolbar_width
	var pixel_width = canvas_width / GRID_SIZE
	var pixel_height = pixel_width / WIDTH_TO_HEIGHT_RATIO
	var actual_canvas_height = pixel_height * GRID_SIZE
	var button_size = Vector2(toolbar_width, toolbar_width)

	# Draw toolbar
	draw_rect(Rect2(0, 0, toolbar_width, actual_canvas_height), Color.LIGHT_GRAY)

	# Draw tool buttons
	draw_rect(Rect2(Vector2.ZERO, button_size), Color.WHITE if current_tool == Tool.DRAW else Color.GRAY)
	draw_rect(Rect2(Vector2(0, toolbar_width), button_size), Color.WHITE if current_tool == Tool.ERASE else Color.GRAY)

	# Draw clear button
	var clear_button_rect = Rect2(0, actual_canvas_height - button_size.y, button_size.x, button_size.y)
	draw_rect(clear_button_rect, Color.RED)

	# Draw pixels
	var pixel_color = Color.BLACK
	print("Current pixel states:")
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var pixel_pos = Vector2(toolbar_width + x * pixel_width, y * pixel_height)
			if pixel_states[y][x]:
				draw_rect(Rect2(pixel_pos, Vector2(pixel_width, pixel_height)), pixel_color)
				#print("Drawing pixel at (%d, %d)" % [x, y])
			else:
				draw_rect(Rect2(pixel_pos, Vector2(pixel_width, pixel_height)), erased_color)

	# Draw grid lines
	var grid_color = Color(0.7, 0.7, 0.7, 0.5)
	for x in range(GRID_SIZE + 1):
		var start = Vector2(toolbar_width + x * pixel_width, 0)
		var end = Vector2(toolbar_width + x * pixel_width, actual_canvas_height)
		draw_line(start, end, grid_color)
	for y in range(GRID_SIZE + 1):
		var start = Vector2(toolbar_width, y * pixel_height)
		var end = Vector2(viewport_size.x, y * pixel_height)
		draw_line(start, end, grid_color)

	# Draw frame container
	var frame_container_rect = Rect2(0, actual_canvas_height, viewport_size.x, viewport_size.y - actual_canvas_height)
	draw_rect(frame_container_rect, Color.DARK_GRAY)

	# Draw frames
	var visible_width = viewport_size.x - toolbar_width
	var max_visible_frames = int(visible_width / FRAME_THUMBNAIL_SIZE)
	var total_frames_width = frames.size() * FRAME_THUMBNAIL_SIZE

	# Draw frame thumbnails
	for i in range(frames.size()):
		var frame_x = toolbar_width + (i * FRAME_THUMBNAIL_SIZE) - frame_scroll_offset
		if frame_x >= toolbar_width and frame_x < viewport_size.x:
			var frame_rect = Rect2(frame_x, actual_canvas_height, FRAME_THUMBNAIL_SIZE - 2, FRAME_THUMBNAIL_SIZE - 2)
			if i == current_frame_index:
				draw_rect(frame_rect, Color.WHITE)
			else:
				draw_rect(frame_rect, Color.LIGHT_GRAY)

			# Check if frame has any pixels
			var has_pixels = false
			for y in range(GRID_SIZE):
				for x in range(GRID_SIZE):
					if frames[i][y][x]:
						has_pixels = true
						break
				if has_pixels:
					break

			# Draw indicator dot if frame has pixels
			if has_pixels:
				var dot_size = 4
				var dot_pos = Vector2(
					frame_x + (FRAME_THUMBNAIL_SIZE - dot_size) / 2,
					actual_canvas_height + (FRAME_THUMBNAIL_SIZE - dot_size) / 2
				)
				draw_rect(Rect2(dot_pos, Vector2(dot_size, dot_size)), Color.BLACK)

	# Draw scrollbar if needed
	if total_frames_width > visible_width:
		var scrollbar_height = 30
		var scrollbar_y = viewport_size.y - scrollbar_height  # Changed to align with bottom of viewport
		var scrollbar_width = viewport_size.x - toolbar_width

		# Draw scrollbar background
		draw_rect(Rect2(toolbar_width, scrollbar_y, scrollbar_width, scrollbar_height), Color.DARK_GRAY)

		# Draw scrollbar handle
		var handle_ratio = visible_width / total_frames_width
		var handle_width = max(scrollbar_width * handle_ratio, 60)
		var handle_x = toolbar_width + (frame_scroll_offset / (total_frames_width - visible_width)) * (scrollbar_width - handle_width)
		var handle_rect = Rect2(handle_x, scrollbar_y, handle_width, scrollbar_height)
		draw_rect(handle_rect, Color(0.8, 0.8, 0.8))
		draw_rect(handle_rect, Color(0.9, 0.9, 0.9) if is_dragging_scrollbar else Color(0.7, 0.7, 0.7), false)

	print("Drawing complete")


func _input(event):
	var viewport_size = get_viewport_rect().size
	var toolbar_width = viewport_size.x * TOOLBAR_WIDTH_RATIO
	var visible_width = viewport_size.x - toolbar_width
	var total_frames_width = frames.size() * FRAME_THUMBNAIL_SIZE
	var scrollbar_height = 30
	var pixel_width = (viewport_size.x - toolbar_width) / GRID_SIZE
	var pixel_height = pixel_width / WIDTH_TO_HEIGHT_RATIO
	var actual_canvas_height = pixel_height * GRID_SIZE
	var scrollbar_y = viewport_size.y - scrollbar_height

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var pos = event.position
				if total_frames_width > visible_width and event.position.y >= scrollbar_y and event.position.y <= scrollbar_y + scrollbar_height:
					is_dragging_scrollbar = true
					drag_start_position = event.position
					drag_start_scroll = frame_scroll_offset
				elif is_position_in_pixel_grid(pos):
					is_drawing_pixels = true
					is_drawing = true
					current_action_pixels.clear()
					drawn_pixels.clear()
					handle_input(pos)
					frames[current_frame_index] = pixel_states.duplicate(true)
					emit_signal("frame_state_changed", current_frame_index)
				elif not is_drawing_pixels:
					is_drawing = true
					current_action_pixels.clear()
					drawn_pixels.clear()
					handle_input(pos)
					frames[current_frame_index] = pixel_states.duplicate(true)
					emit_signal("frame_state_changed", current_frame_index)
			else:  # Mouse button released
				if is_dragging_scrollbar:
					is_dragging_scrollbar = false
				elif is_drawing_pixels:
					is_drawing_pixels = false
					is_drawing = false
					commit_current_action()
					frames[current_frame_index] = pixel_states.duplicate(true)
					emit_signal("frame_state_changed", current_frame_index)
				else:
					is_drawing = false
					commit_current_action()
					frames[current_frame_index] = pixel_states.duplicate(true)
					emit_signal("frame_state_changed", current_frame_index)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			frame_scroll_offset = max(0, frame_scroll_offset - FRAME_THUMBNAIL_SIZE)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var max_scroll = max(0, total_frames_width - visible_width)
			frame_scroll_offset = min(max_scroll, frame_scroll_offset + FRAME_THUMBNAIL_SIZE)
			queue_redraw()

	elif event is InputEventMouseMotion:
		if is_dragging_scrollbar:
			var drag_distance = event.position.x - drag_start_position.x
			var scroll_range = total_frames_width - visible_width
			var scroll_ratio = (drag_distance / (visible_width - toolbar_width)) * 2.5
			frame_scroll_offset = clamp(
				drag_start_scroll + (scroll_ratio * scroll_range),
				0,
				max(0, total_frames_width - visible_width)
			)
			queue_redraw()
		elif is_drawing and is_drawing_pixels:
			if is_position_in_pixel_grid(event.position):
				handle_input(event.position)
				frames[current_frame_index] = pixel_states.duplicate(true)
				emit_signal("frame_state_changed", current_frame_index)
		elif is_drawing:
			handle_input(event.position)
			frames[current_frame_index] = pixel_states.duplicate(true)
			emit_signal("frame_state_changed", current_frame_index)

func is_position_in_pixel_grid(pos: Vector2) -> bool:
	var viewport_size = get_viewport_rect().size
	var toolbar_width = viewport_size.x * TOOLBAR_WIDTH_RATIO
	var canvas_width = viewport_size.x - toolbar_width
	var pixel_width = canvas_width / GRID_SIZE
	var pixel_height = pixel_width / WIDTH_TO_HEIGHT_RATIO

	if pos.x < toolbar_width or pos.x >= viewport_size.x:
		return false
	if pos.y < 0 or pos.y >= GRID_SIZE * pixel_height:
		return false

	return true

func delete_current_frame():
	if frames.size() <= 1:  # Don't allow deleting the last frame
		return

	var deleted_frame = frames[current_frame_index].duplicate(true)
	var deleted_index = current_frame_index

	# Remove the frame
	frames.remove_at(current_frame_index)

	# Adjust current frame index if needed
	if current_frame_index >= frames.size():
		current_frame_index = frames.size() - 1

	# Load the new current frame
	pixel_states = frames[current_frame_index].duplicate(true)

	# Add scroll management here
	var viewport_size = get_viewport_rect().size
	var toolbar_width = viewport_size.x * TOOLBAR_WIDTH_RATIO
	var visible_width = viewport_size.x - toolbar_width
	var frame_x = toolbar_width + (current_frame_index * FRAME_THUMBNAIL_SIZE) - frame_scroll_offset

	# If we're scrolled too far right after deletion, adjust scroll
	var max_scroll = max(0, (frames.size() * FRAME_THUMBNAIL_SIZE) - visible_width)
	frame_scroll_offset = min(frame_scroll_offset, max_scroll)

	# If current frame is out of view to the left, scroll to it
	if frame_x < toolbar_width:
		frame_scroll_offset = max(0, current_frame_index * FRAME_THUMBNAIL_SIZE)

	# Record the action for undo/redo
	var action_data: Array[Dictionary] = [{
		"frame": deleted_frame,
		"index": deleted_index
	}]
	action_history.add_action(ActionHistory.ActionType.DELETE, action_data, deleted_index)
	queue_redraw()

func copy_current_frame():
	frame_copy_buffer = frames[current_frame_index].duplicate(true)

func paste_to_current_frame():
	if frame_copy_buffer != null:
		var old_frame = frames[current_frame_index].duplicate(true)
		frames[current_frame_index] = frame_copy_buffer.duplicate(true)
		pixel_states = frames[current_frame_index].duplicate(true)

		var action_data: Array[Dictionary] = [{
			"frame": old_frame,
			"index": current_frame_index
		}]
		action_history.add_action(ActionHistory.ActionType.PASTE, action_data, current_frame_index)
		queue_redraw()

func duplicate_current_frame():
	var new_frame = frames[current_frame_index].duplicate(true)
	frames.insert(current_frame_index + 1, new_frame)

	var action_data: Array[Dictionary] = [{
		"index": current_frame_index + 1
	}]
	action_history.add_action(ActionHistory.ActionType.DUPLICATE, action_data, current_frame_index)

	current_frame_index += 1
	pixel_states = frames[current_frame_index].duplicate(true)
	queue_redraw()

func add_new_frame(at_end: bool = false):
	# Save current frame before creating new one
	frames[current_frame_index] = pixel_states.duplicate(true)

	# Create new empty frame
	var new_frame = []
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			row.append(false)
		new_frame.append(row)

	# Insert the new frame either after current frame or at end
	if at_end:
		frames.append(new_frame)
		current_frame_index = frames.size() - 1
	else:
		frames.insert(current_frame_index + 1, new_frame)
		current_frame_index += 1

	pixel_states = frames[current_frame_index]

	# Add scroll management here
	var viewport_size = get_viewport_rect().size
	var toolbar_width = viewport_size.x * TOOLBAR_WIDTH_RATIO
	var visible_width = viewport_size.x - toolbar_width
	var frame_x = toolbar_width + (current_frame_index * FRAME_THUMBNAIL_SIZE) - frame_scroll_offset
	if frame_x + FRAME_THUMBNAIL_SIZE > viewport_size.x:
		frame_scroll_offset = max(0, (current_frame_index * FRAME_THUMBNAIL_SIZE) - visible_width + FRAME_THUMBNAIL_SIZE)

	queue_redraw()

func handle_input(pos):
	var viewport_size = get_viewport_rect().size
	var toolbar_width = viewport_size.x * TOOLBAR_WIDTH_RATIO
	var canvas_width = viewport_size.x - toolbar_width
	var pixel_height = (canvas_width / GRID_SIZE) / WIDTH_TO_HEIGHT_RATIO
	var actual_canvas_height = pixel_height * GRID_SIZE

	# Handle frame container clicks
	if pos.y >= actual_canvas_height and pos.y < actual_canvas_height + FRAME_THUMBNAIL_SIZE and not is_drawing_pixels:
		var frame_x = int((pos.x - toolbar_width + frame_scroll_offset) / FRAME_THUMBNAIL_SIZE)
		if frame_x >= 0 and frame_x < frames.size():
			# Save current frame
			frames[current_frame_index] = pixel_states.duplicate(true)
			# Switch to selected frame
			current_frame_index = frame_x
			pixel_states = frames[current_frame_index].duplicate(true)
			queue_redraw()
		return

	if pos.x < toolbar_width and not is_drawing_pixels:
		if pos.y >= actual_canvas_height - toolbar_width and pos.y < actual_canvas_height:
			clear_all_pixels()
		else:
			var tool_index = int(pos.y / toolbar_width)
			if tool_index < Tool.size():
				current_tool = Tool.values()[tool_index]
				queue_redraw()
	else:
		draw_at_mouse_position(pos)

func draw_at_mouse_position(pos):
	var viewport_size = get_viewport_rect().size
	var toolbar_width = viewport_size.x * TOOLBAR_WIDTH_RATIO
	var canvas_width = viewport_size.x - toolbar_width
	var pixel_width = canvas_width / GRID_SIZE
	var pixel_height = pixel_width / WIDTH_TO_HEIGHT_RATIO
	var x = int((pos.x - toolbar_width) / pixel_width)
	var y = int(pos.y / pixel_height)
	if x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE:
		toggle_pixel(x, y)

func toggle_pixel(x, y):
	var old_state = pixel_states[y][x]
	var new_state = (current_tool == Tool.DRAW)

#only proceed if the action would change the pixel state
	if old_state != new_state:
		pixel_states[y][x] = new_state
		current_action_pixels.append({"x": x, "y": y, "old_state": old_state})
		emit_signal("pixel_states_changed", pixel_states)
		queue_redraw()

func commit_current_action():
	print("Committing action with", current_action_pixels.size(), "pixels")
	if not current_action_pixels.is_empty():
		var action_type = ActionHistory.ActionType.DRAW if current_tool == Tool.DRAW else ActionHistory.ActionType.ERASE
		action_history.add_action(action_type, current_action_pixels.duplicate(), current_frame_index)
		current_action_pixels.clear()
	else:
		print("No pixels to commit")

func undo():
	print("Undo called")
	var action = action_history.undo()
	if action:
		print("Applying undo action:", action.type)
		apply_action(action, true)
	else:
		print("No action to undo")

func redo():
	print("Redo called")
	var action = action_history.redo()
	if action:
		print("Applying redo action:", action.type)
		apply_action(action, false)
	else:
		print("No action to redo")

func apply_action(action: ActionHistory.Action, is_undo: bool):
	match action.type:
		ActionHistory.ActionType.DRAW, ActionHistory.ActionType.ERASE:
			for pixel in action.data:
				var x = pixel["x"]
				var y = pixel["y"]
				if is_undo:
					pixel_states[y][x] = pixel["old_state"]
				else:
					pixel_states[y][x] = !pixel["old_state"]
		ActionHistory.ActionType.CLEAR:
			if is_undo:
				for pixel in action.data:
					pixel_states[pixel["y"]][pixel["x"]] = pixel["old_state"]
			else:
				for y in range(GRID_SIZE):
					for x in range(GRID_SIZE):
						pixel_states[y][x] = false
		ActionHistory.ActionType.DELETE:
			if is_undo:
				# Restore the deleted frame
				var deleted_data = action.data[0]
				var frame = deleted_data["frame"]
				var index = deleted_data["index"]
				frames.insert(index, frame)
				current_frame_index = index
				pixel_states = frames[current_frame_index].duplicate(true)
			else:
				# Re-delete the frame
				var index = action.data[0]["index"]
				frames.remove_at(index)
				if current_frame_index >= frames.size():
					current_frame_index = frames.size() - 1
				pixel_states = frames[current_frame_index].duplicate(true)
		ActionHistory.ActionType.PASTE:
			if is_undo:
				# Restore the old frame
				var old_data = action.data[0]
				frames[old_data["index"]] = old_data["frame"].duplicate(true)
				if current_frame_index == old_data["index"]:
					pixel_states = frames[current_frame_index].duplicate(true)
			else:
				# Re-apply the paste
				frames[action.data[0]["index"]] = frame_copy_buffer.duplicate(true)
				if current_frame_index == action.data[0]["index"]:
					pixel_states = frames[current_frame_index].duplicate(true)
		ActionHistory.ActionType.DUPLICATE:
			if is_undo:
				# Remove the duplicated frame
				var dup_index = action.data[0]["index"]
				frames.remove_at(dup_index)
				if current_frame_index >= dup_index:
					current_frame_index = max(current_frame_index - 1, 0)
					pixel_states = frames[current_frame_index].duplicate(true)
			else:
				# Re-insert the duplicated frame
				var dup_index = action.data[0]["index"]
				frames.insert(dup_index, frames[dup_index - 1].duplicate(true))
				current_frame_index = dup_index
				pixel_states = frames[current_frame_index].duplicate(true)
	# Update the current frame in our frames array
	frames[current_frame_index] = pixel_states.duplicate(true)
	emit_signal("pixel_states_changed", pixel_states)
	queue_redraw()

func clear_all_pixels():
	var old_states: Array[Dictionary] = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if pixel_states[y][x]:
				old_states.append({"x": x, "y": y, "old_state": true})

	if not old_states.is_empty():
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				pixel_states[y][x] = false
		action_history.add_action(ActionHistory.ActionType.CLEAR, old_states, current_frame_index)
		emit_signal("pixel_states_changed", pixel_states)
		emit_signal("frame_state_changed", current_frame_index)
		queue_redraw()
