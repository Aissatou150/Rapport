/* ----------------------------------------------------------------------------
					    	Dimension Conditions de vie 
-----------------------------------------------------------------------------*/
/*
			use "${repert}s12_me_SEN2021.dta", clear
*_____________________________________________________________________________
*			         Création identifiant unique du ménage

	tostring menage, gen(menage_)
	tostring grappe, gen(grappe_)
	gen hhid1 = cond(strlen(menage_) == 1, grappe_ + "0" + menage_, grappe_ + menage_)
	destring hhid1, gen(hhid)
	drop hhid1 grappe_ menage_
* ____________________________________________________________________________ 

*/
			use "${repert}s11_me_SEN2021.dta", clear
*_____________________________________________________________________________
*			         Création identifiant unique du ménage

	tostring menage, gen(menage_)
	tostring grappe, gen(grappe_)
	gen hhid1 = cond(strlen(menage_) == 1, grappe_ + "0" + menage_, grappe_ + menage_)
	destring hhid1, gen(hhid)
	drop hhid1 grappe_ menage_
* ____________________________________________________________________________ 
	
	merge 1:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta", ///
				   keepusing(hhweight hhsize) nogen
	merge 1:1 hhid using "${repert}ehcvm_menage_SEN2021.dta", ///
				   keepusing(ordin tv fer frigo cuisin decod car cuisin) nogen
				   
				   
*				 		1. Indicateur Type de logement 	
*					   -------------------------------
	rename s11q01 type_logem
	* ------------------------------------------------------------------------		
	notes : Le ménage est privé si le logement est une case, baraque ou «autre»
	* ------------------------------------------------------------------------	
	
	gen pr_type_log = (type_logem == 4 | type_logem == 5)
	label variable pr_type_log "IP Type de logement"

	
*				 		2. Indicateur Électricité	
*					   -------------------------------
	rename s11q37 source_eclairage 								// 11 missing
	* ------------------------------------------------------------------------	
	notes : La source d'éclairage du ménage n'est pas : électricité, groupe ///
			électrogène ou solaire
	* ------------------------------------------------------------------------	

	gen pr_electr = !(source_eclairage == 1 |source_eclairage == 2 | ///
					source_eclairage == 3)
	label variable pr_electr "IP Électricité"

	
*				 	    3. Indicateur Évacuation des eaux usées 	
*					   -------------------------------
	rename s11q59 eva_eu
	* ------------------------------------------------------------------------	
	notes : Le ménage est privé si l'évacuation se fait dans la cour ou dans ///
			la rue/nature
	* ------------------------------------------------------------------------	
			
	gen pr_evac_eu = !(eva_eu == 1 | eva_eu == 2)
	label variable pr_evac_eu "IP Évacuation eaux usées"


*				 		4. Indicateur Évacuation des ordures 	
*					   -------------------------------
	rename s11q53 eva_ord
	* ------------------------------------------------------------------------		
	notes :  Le ménage est privé si l'évacuation se fait par tas d'immondices ///
				ou dans la route/rue
	* ------------------------------------------------------------------------		
	
	gen pr_eva_ord = !(eva_ord==1|eva_ord==2|eva_ord==3)
	lab var pr_eva_ord "IP Évacuation orudures ménagères"

	
*				 		5. Indicateur Eau potable		
*					    ----------------------
	rename s11q26b eau_potable
	* ------------------------------------------------------------------------	
	notes : Le ménage n'a pas accès à l'eau potable	///
	/*
	L'eau potable est une eau que l'on peut boire ou utiliser à des fins 
	domestiques et industrielles sans risque pour la santé.*/
	* ------------------------------------------------------------------------	
	
	gen pr_eau_pot = !(inlist(eau_potable, 1, 2, 3, 4, 11, 14, 16))
	label variable pr_eau_pot "IP Eau potable"

	
*				 	    6. Indicateur Équipements sanitaires 	
*					    ---------------------------------
	rename s11q54 type_sanitr
	* ------------------------------------------------------------------------		
	notes : Le ménage ne dispose pas de toilettes privées améliorée
	* ------------------------------------------------------------------------	

	gen pr_equipm_sanit = !(inlist(type_sanitr, 1, 2, 3, 4, 5))
	label variable pr_equipm_sanit "IP Équipement sanitaire"
	

*				        7. Indicateur Indice de surpeuplement	
*					    ----------------------------------
	rename s11q02 nb_pieces	
	gen ind_surpl = hhsize / nb_pieces
	* drop s11q02 hhsize
	lab var ind_surpl "indice de surpeuplement"

	* ------------------------------------------------------------------------	
	notes : Le ménage est privé si le logement est surpeuplé ///
			(plus de 3 personnes par pièce)
	* ------------------------------------------------------------------------	

	gen pr_surpeuplemnt = (ind_surpl >= 3)
	label variable pr_surpeuplemnt "IP Indice de Surpeuplement"

		
*				 		8. Indicateur Biens d'équipement	 	
*					   -------------------------------
	gen nb_biens = ordin + tv + fer + frigo + cuisin + decod + car
	lab var nb_biens "nombre de biens d'équipements"

	* ------------------------------------------------------------------------		
	notes : Le ménage dispose de moins de 2 équipements (ventilateur, TV, ///
		   ordinateur, cuisinière, réfrigérateur, bicyclette, motocyclette) ///
		   et ne dispose ni de voiture, camion, machine à laver ni de       ///
	   	   groupe électrogène
	* ------------------------------------------------------------------------	

	gen pr_bien_equipm = (nb_biens <= 2)
	label variable pr_bien_equipm  "IP Biens et équipements"	


*				 		9. Indicateur Énergie de cuisson 	
*					   -------------------------------
	
	gen energ_cuiss=cond(s11q52__4==1|s11q52__4==2|s11q52__5==1|s11q52__5==2,0,1)
		
	* ------------------------------------------------------------------------	
	notes : Le ménage n'utilise pas d'énergie propre pour la cuisson ///
			(électricité et gaz)
	* ------------------------------------------------------------------------	
	gen pr_energ_cuis = (energ_cuiss == 1)
	label variable pr_energ_cuis "IP Énergie pour cuisson"
	
	keep hhid pr_type_log pr_electr pr_evac_eu pr_eva_ord pr_eau_pot ///
		      pr_equipm_sanit pr_surpeuplemnt pr_bien_equipm pr_energ_cuis

	save "${rdata}\d_condvie.dta", replace
