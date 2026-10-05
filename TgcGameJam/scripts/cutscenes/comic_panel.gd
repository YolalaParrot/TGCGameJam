class_name ComicPanel
extends Resource

enum Side { LEFT, RIGHT, TOP, BOTTOM }

@export var texture: Texture2D
@export var rect := Rect2(0.05, 0.05, 0.9, 0.9)
@export var enter_from := Side.LEFT
