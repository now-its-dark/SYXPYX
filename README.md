# SYXPYX
One of the coolest and most overlooked features of various sound modules produced by Korg, Roland and Yamaha, is their ability to display bitmap / pixel data.

This is an attempt to create the tool I was looking for.. the one that was never made when these devices were contemporary, basically a wacom and legitimate animation editor for MIDI devices.

My guess, is that the main reason why very few people bothered with this capability (or at least not in much depth), is because it's inconvenient to actually create this data, especially in terms of animation. Not that it is technically complicated, but because a tool wasn't available to allow for a reasonably fluid creative workflow, (as it should have been from the start). 

Perhaps this dearth of usable tools was due to the fact that the people who would be most attracted to the possibility of making pixel art for their MIDIs aren't programmers, but visual artists and designers, like me. So, I made an LLM program it for me lol. 

This tool is made possible by [NullMember's port of the RTMidi library for Godot](https://github.com/NullMember/godot-rtmidi/releases)!

If you want to try this, you'll need to grab their extension and place it in the project folder, as described in their repo.

Currently, the tool is in a stable, alpha state (oxymoron?!)— it supports SC-55, XG (Display:Bitmap) and TG300 (virtually the same as XG, with a different address and using Roland checksum), but not the memory pages used by the 88 Pro, or the fancier displays on the NS5X series or the SC8850. It works well, within the limited functions currently present.

What is *missing...*

- Any form of file handling
- MIDI input
- A decent UI design

What works:

User input:
Mostly keyboard-based, other than for drawing operations— nearly every function has an associated key command, which can be reassigned via the native key mapping in Godot.
There are non-iconographic buttons for draw, erase and clear. 
There is direct input selection for frames on the timeline, as well as the ability to move between them with the arrow keys. 
You can scroll the frames with a fairly janky scrollbar, but the scroll position will also advance to reveal non-visible frames, once the current frame exceeds the bounds of the visible area.

Drawing:
- Draw pixel tool
- Erase pixel tool
- Clear all pixels from current frame (does not delete the frame)
- Display current pixels on device (one-shot)
- Display real-time (persistently show any changes immediately on device, including frame changes)
  
Animation/timeline:
- Play and pause the timeline.
- New frame after current.
- New frame at end of timeline.
- Duplicate current frame.
- Delete current frame.
- Real-time animation display on device.
- Indicator dot for populated vs empty frame.

MIDI
- Assign MIDI output port (app will refresh when new ports appear on the system)
- Assign bitmap standard (XG, SC-55, TG300)
- Stores the current port name in use, in case of a disconnect, then refreshes the connection and opens the port if device reconnects.

<pre>
Default Keymap:
(currently implemented)

system functions
           esc : toggle menu

Pixel editing functions:
             E : Toggle pixel edit mode between Draw & Erase.
           DEL : Delete pixels in current frame.
        CTRL+C : Copy pixels in current frame.
        CTRL+V : Paste pixels to current frame.

Timeline functions:
             N : New frame after current frame.
      SHIFTt+N : New frame to end of timeline.
  SHIFT+DELETE : Delete current frame.
         SPACE : Start / Stop playback.
        CTRL+D : Duplicate current frame.
       L.ARROW : Go to left adjacent frame.
       R.ARROW : Go to right adjacent frame.

MIDI functions:
         ENTER : Transmit pixels in current frame.
   SHIFT+ENTER : Toggle MIDI pixel mirror— this transmits all pixel/frame changes to device in real-time. (wacom mode)
   SHIFT+SPACE : Toggle MIDI timeline mirror— transmits only timeline output to device as it plays.
   </pre>


What I intend/hope for this to do in the future:

UI
- An actual, properly conceived GUI, with all functions available using coherent iconography.
- Auto adjustment for pixel size / aspect ratio, depending on the current device type (for example, TG300 has nearly square pixels, while XG devices mostly have double-width).
- Assign background color, depending on device type. (Green / Orange / other??).

Editor Tools:
- Shift Pixels in a direction on X & Y axis, with and without wrapping
- Flood fill tool
- Invert tool (current frame or all frames)
- Layers
- Layer timeline properties (eg. set one layer to run at 4 FPS, while another runs as 15)
- Layer Effects (nothing that fancy, but maybe auto-outline a higher layer, to always ensure distinction from lower ones)
  
File handling:
- Import/Export GIF
- Import/Export images & image sequences in various formats
- Import/Export .syx containing bitmap messages
- Export timed MIDI data, with *separate* settings for FPS and BPM.
  
MIDI Control:
- Trigger on Note — on an instantiated virtual MIDI port, map received MIDI note input to corresponding frame number and display it.
- Shift pixels — on MIDI CC, move and wrap current pixels on X or Y axis in either direction.
- Velocity Shift — Switch current frame from frame 1->last available frame, dependent on note velocity. (scale velocity across total number of frames)
- Some other, less clearly formed ideas.
- MIDI 2.0 CI profile, so anything can see its capabilties in ze pixels, cuz fuck yeah.

Visualizers:
- Map shaders to pixel grid; would allow for easy use of dithering algorithms and live inputs, such as from a webcam.
- Virtual audio device receiver + spectrum analyzer to display audio frequency information from the device.
- Region activation - display activity state for individual notes, for things like drum sounds, which are not represented on the device ordinarily.

Optimization:
- Right now, it just sends the entire message every time. This is not necessary, as pixels can be transmitted discretely, but it's additional logic that doesn't exist yet. Partly, because there is a balance to be struck— if numerous single pixel changes must transmitted, it could end up being less efficient in some cases, due to the additional bytes needed to setup each message.
