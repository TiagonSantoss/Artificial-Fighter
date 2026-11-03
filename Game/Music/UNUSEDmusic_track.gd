class_name MusicTrack
extends Resource

enum Mood { EXPLORE, COMBAT }

## The MOOD, ofc
@export var mood: Mood = Mood.EXPLORE
## FMOD parameter number
@export var fmod_value: int = 0
## Seconds, so the director knows when it ends
@export var length: float = 120.0
## Higher values mean more chance
@export var weight: float = 1.0
