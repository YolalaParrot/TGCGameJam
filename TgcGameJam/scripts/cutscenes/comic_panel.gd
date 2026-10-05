class_name ComicPanel
extends Resource

enum Side { LEFT, RIGHT, TOP, BOTTOM }

@export var texture: Texture2D
## Where the panel sits, as fractions of the screen: x, y, width, height (0 to 1).
## Any shape works: wide, tall or square.
@export var rect := Rect2(0.05, 0.05, 0.9, 0.9)
## The screen edge the panel slides in from.
@export var enter_from := Side.LEFT
