extends Node2D

# --- CONFIGURATION DE LA CARTE ---
@export var grille_logique: TileMapLayer 
@export var conteneur_batiments: Node2D
@export var camera: Camera2D 

# --- L'INTERFACE ET LES SCÈNES ---
@export var interface_jeu: CanvasLayer 
@export var scene_game_over: PackedScene
@export var scene_usine: PackedScene
@export var scene_pompe: PackedScene
@export var scene_dechet: PackedScene
@export var scene_petrole: PackedScene

# --- L'ÉCONOMIE ET LA VIE ---
var ecopieces = 100         
var cout_batiment = 50      
var prix_nettoyage = 20
var revenu_par_cycle = 10   
var nombre_batiments = 0    
var niveau_ecologie = 100 

# --- MÉMOIRE INTERNE ---
var fantome: Node2D
var cases_occupees = {} 
var dictionnaire_dechets = {} 
var mode_construction = "aucun" # Au début, on ne construit rien

func _ready():
	mettre_a_jour_interface()
	
	var timer_paie = Timer.new()
	timer_paie.wait_time = 2.0 
	timer_paie.autostart = true
	timer_paie.timeout.connect(recolter_revenu_passif)
	add_child(timer_paie)
	
	var timer_pollution = Timer.new()
	timer_pollution.wait_time = 5.0 # Un déchet toutes les 5 secondes
	timer_pollution.autostart = true
	timer_pollution.timeout.connect(generer_pollution)
	add_child(timer_pollution)

func _process(_delta):
	if fantome != null:
		mise_a_jour_fantome()

func _unhandled_input(event):
	# On gère le clic gauche sur la carte
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		gerer_clic_carte()

# --- CONNEXION AVEC LES BOUTONS DE L'INTERFACE ---
# Tu devras connecter les signaux "pressed()" de tes boutons à ces fonctions !
func _on_btn_usine_pressed():
	changer_outil("terre")

func _on_btn_pompe_pressed():
	changer_outil("eau")

# --- LOGIQUE DE CONSTRUCTION ---
func changer_outil(nouveau_mode):
	mode_construction = nouveau_mode
	if fantome != null: 
		fantome.queue_free()
		fantome = null
	
	if mode_construction != "aucun":
		var scene_a_charger = scene_usine if mode_construction == "terre" else scene_pompe
		if scene_a_charger:
			fantome = scene_a_charger.instantiate()
			fantome.modulate.a = 0.5
			add_child(fantome)

func mise_a_jour_fantome():
	if grille_logique == null or fantome == null: return
	var case_grille = grille_logique.local_to_map(get_global_mouse_position())
	fantome.global_position = grille_logique.map_to_local(case_grille)
	
	var id_sol = grille_logique.get_cell_source_id(case_grille)
	var mauvais_sol = (mode_construction == "terre" and id_sol != 0) or (mode_construction == "eau" and id_sol != 1)
	
	if cases_occupees.has(case_grille) or ecopieces < cout_batiment or mauvais_sol:
		fantome.modulate = Color(1, 0, 0, 0.5) 
	else:
		fantome.modulate = Color(0, 1, 0, 0.5) 

# --- ACTION PRINCIPALE : LE CLIC SUR LA MAP ---
func gerer_clic_carte():
	if grille_logique == null: return
	var case_cible = grille_logique.local_to_map(get_global_mouse_position())
	
	# 1. EST-CE QU'ON CLIQUE SUR UN DÉCHET POUR LE NETTOYER ?
	if cases_occupees.has(case_cible) and cases_occupees[case_cible] == "dechet":
		var le_dechet = dictionnaire_dechets[case_cible]
		# On vérifie qu'on a l'argent et qu'il n'est pas déjà en train d'être nettoyé
		if ecopieces >= prix_nettoyage and not le_dechet.en_cours_de_nettoyage:
			ecopieces -= prix_nettoyage 
			mettre_a_jour_interface()
			le_dechet.commencer_nettoyage() 
		# On force l'outil à se déséquiper pour éviter de construire par-dessus après nettoyage
		changer_outil("aucun")
		return 

	# 2. EST-CE QU'ON VEUT CONSTRUIRE UN BÂTIMENT ?
	if mode_construction == "aucun": return # Si pas d'outil sélectionné, on annule
	
	var id_sol = grille_logique.get_cell_source_id(case_cible)
	var mauvais_sol = (mode_construction == "terre" and id_sol != 0) or (mode_construction == "eau" and id_sol != 1)
	
	if ecopieces < cout_batiment or cases_occupees.has(case_cible) or mauvais_sol: 
		return 
	
	ecopieces -= cout_batiment
	var scene_active = scene_usine if mode_construction == "terre" else scene_pompe
	var nouveau_batiment = scene_active.instantiate()
	nouveau_batiment.global_position = grille_logique.map_to_local(case_cible)
	conteneur_batiments.add_child(nouveau_batiment)
	
	cases_occupees[case_cible] = "batiment"
	nombre_batiments += 1 
	changer_outil("aucun") # On déséquipe l'outil après la construction (comme CoC)
	mettre_a_jour_interface()

# --- GÉNÉRATION DES DÉCHETS ET PUNITION ---
func generer_pollution():
	if grille_logique == null: return
	var cases_valides = grille_logique.get_used_cells()
	if cases_valides.is_empty(): return
	
	var case_cible = cases_valides.pick_random()
	var id_sol = grille_logique.get_cell_source_id(case_cible)
	
	if not cases_occupees.has(case_cible):
		var scene_a_creer = scene_dechet if id_sol == 0 else scene_petrole
		if scene_a_creer:
			var nouveau_mal = scene_a_creer.instantiate()
			nouveau_mal.global_position = grille_logique.map_to_local(case_cible)
			conteneur_batiments.add_child(nouveau_mal)
			cases_occupees[case_cible] = "dechet"
			dictionnaire_dechets[case_cible] = nouveau_mal

func punir_joueur():
	niveau_ecologie -= 20 # Baisse de 20 PV si un déchet explose
	mettre_a_jour_interface() 
	
	if niveau_ecologie <= 0:
		if scene_game_over:
			var go_ecran = scene_game_over.instantiate()
			add_child(go_ecran)
		get_tree().paused = true

func liberer_case_dechet(pos_globale):
	var case_grille = grille_logique.local_to_map(pos_globale)
	if cases_occupees.has(case_grille):
		cases_occupees.erase(case_grille)
		dictionnaire_dechets.erase(case_grille)

# --- ECONOMIE ---
func recolter_revenu_passif():
	var gain_total = nombre_batiments * revenu_par_cycle
	if gain_total > 0:
		ecopieces += gain_total
		mettre_a_jour_interface()

func mettre_a_jour_interface():
	if interface_jeu:
		if interface_jeu.has_method("mettre_a_jour_niveau"):
			interface_jeu.mettre_a_jour_niveau(ecopieces)
		if interface_jeu.has_method("mettre_a_jour_ecologie"):
			interface_jeu.mettre_a_jour_ecologie(niveau_ecologie)
		
