extends Node2D

signal IncrementScore(incr: int)
signal IncrementCombo()
signal ResetCombo()

signal CreateFallingKey(button_name: String)
signal KeyListenerPress(button_name: String, array_num: int)

signal LevelFinished()

signal NoteHit(rating: String)
signal GameOver(passed: bool)
signal UpdateCountdown(text: String)
