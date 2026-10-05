extends Node2D

# --- Score & Combo Signals ---
signal IncrementScore(incr: int)
signal IncrementCombo()
signal ResetCombo()

# --- Key Spawning & Input Signals ---
signal CreateFallingKey(button_name: String)
signal KeyListenerPress(button_name: String, array_num: int)

# --- Level Flow Signals ---
signal LevelFinished()

# --- Win/Loss System Signals ---
signal NoteHit(rating: String)
signal GameOver(passed: bool)
signal UpdateCountdown(text: String)
