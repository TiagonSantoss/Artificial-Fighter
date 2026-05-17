class_name HealthComponent
extends EntityComponent

signal damaged(amount)
signal died

var health: int
var max_health: int

func configure(max_hp: int):
	max_health = max_hp
	health = max_hp

func damage(amount: int):
	health -= amount

	damaged.emit(amount)

	print(health)

	if health <= 0:
		died.emit()
