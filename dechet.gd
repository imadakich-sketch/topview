extends Node2D

var temps_avant_explosion = 10.0 # Le déchet explose au bout de 10 secondes
var en_cours_de_nettoyage = false

func _ready():
	# 1. On lance le chrono de la mort dès qu'il apparaît
	var timer_mort = Timer.new()
	timer_mort.wait_time = temps_avant_explosion
	timer_mort.autostart = true
	timer_mort.timeout.connect(_on_explosion)
	add_child(timer_mort)

func _on_explosion():
	if not en_cours_de_nettoyage:
		# L'explosion ! On va chercher le MainGame pour baisser la barre
		var main_game = get_tree().current_scene
		if main_game.has_method("punir_joueur"):
			main_game.punir_joueur()
		
		# Le déchet a fait ses dégâts, on nettoie la case et on le détruit
		if main_game.has_method("liberer_case_dechet"):
			main_game.liberer_case_dechet(global_position)
		queue_free()

# --- FONCTION APPELÉE PAR LE CLIC DU JOUEUR ---
func commencer_nettoyage():
	en_cours_de_nettoyage = true
	
	# On assombrit l'image pour montrer qu'on est en train de nettoyer
	modulate = Color(0.3, 0.3, 0.3) 
	
	# Petit délai de nettoyage (1 seconde) avant de disparaître
	var timer_nettoyage = Timer.new()
	timer_nettoyage.wait_time = 1.0
	timer_nettoyage.one_shot = true
	timer_nettoyage.autostart = true
	timer_nettoyage.timeout.connect(_on_nettoye)
	add_child(timer_nettoyage)

func _on_nettoye():
	# Le nettoyage est fini, on libère la case et on détruit l'objet
	var main_game = get_tree().current_scene
	if main_game.has_method("liberer_case_dechet"):
		main_game.liberer_case_dechet(global_position)
	queue_free()
	
