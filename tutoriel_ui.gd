extends CanvasLayer

func _ready():
	# Optionnel : Faire une petite animation d'apparition ici plus tard
	pass

func _on_bouton_fermer_pressed():
	# Quand on clique, on détruit cette interface
	queue_free()
