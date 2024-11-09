# SYXPYX
This is an attempt to create the tool I was looking for.. that nobody ever made when these devices were contemporary, basically a wacom for MIDI devices.
One of the coolest and most overlooked features of various sound modules produced by Korg, Roland and Yamaha, is their ability to display bitmap / pixel data.

My guess, is that the main reason why very few people bothered with it, is because it's inconvenient to actually create this data, especially in terms of animation. Not because it is complicated, but because there was never a tool which made it as easy as it should have been from the start. Perhaps because the people that would be most attracted to the possibility of making pixel art for their MIDIs aren't programmers, but visual artists and designers, like me. So, I made an LLM program it for me lol. 

This tool is made possible by the RTMidi library for Godot!

Currently, the tool is very much in a stable, alpha state (oxymoron?!)— it supports SC-55, XG (Display:Bitmap) and TG300 (virtually the same as XG, with a different address and using Roland checksum), but not the memory pages used by the 88 Pro, or the fancier displays on the NS5X series or the SC8850. It works well, within the limited functions currently present.

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
  
Animation:
- Play and pause the timeline.
- New frame after current.
- New frame at end of timeline.
- Duplicate current frame.
- Delete current frame.
- Real-time animation display on device.

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
