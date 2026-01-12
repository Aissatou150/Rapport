*_____________________________________________________________________________
*   Création de la matrice des score de  privations
*_____________________________________________________________________________
	use "${rdata}\matrice_accom.dta", clear

/* 	--------------------------------------------------------------------------
					    	Dimension Education
----------------------------------------------------------------------------*/

*			   	 Indicateur Alphabétisation
*				 ---------------------------------------
	notes : Privation si Le quart des membres du ménage de 15 ans ou plus ///
			ne sait pas lire ou écrire
			
	**  Determination des alpahabètes qui ont plus de 15 ans 
	gen n_alfa_15=cond(alphabetisation==0 & age>=15,1,0)
	** Total par menage
	egen t_nalfa_15 = total(n_alfa_15),by(hhid)
	** Les privations
	gen pr_alfa =cond(t_nalfa_15>(1/4*hhsize),1,0)
	lab var pr_alfa "IP Alphabetisation du menage"

*  			     Indicateur Fréquentation scolaire
* 			     ---------------------------------------
	notes : Le ménage a un enfant de 6-16ans qui ne fréquente actuellement ///
			pas l'école

	gen indiv_freq =cond(inrange(age,6,16)& frequentation==1,1,0)
	egen pr_freq = max (indiv_freq), by(hhid)
	lab var pr_freq "IP fréquentation scolaire"

* 				 Indicateur Retard scolaire
*				 ---------------------------------------
	notes : Le ménage a un enfant de 8-13ans ayant un retard scolaire de /// 
			2ans ou plus

	gen late_scol =cond(inrange(age,8,13)& retard==2,1,0)
	egen pr_late_scol =max(late_scol),by(hhid)
	lab var pr_late_scol "retard scolaire"

	
*				 Indicateur Nombre d'années de scolarité 
*				 ----------------------------------------
	notes : Aucun membre du ménage âgé de 15 ans ou plus n'a complété ///
			6 années d'études
	
	gen annee_scol =cond(age>=15 & annee_scolaire<=6,1,0)
	egen pr_annee_scol= max(annee_scol),by(hhid)
	lab var pr_annee_scol "nombres d'années de scolarite"

/* ----------------------------------------------------------------------------
					    	Dimension Santé
-------------------------------------------------------------------------------*/

*				 Indicateur Qualité des services de santé
*			    ------------------------------------------
	notes : Un membre du ménage apprécie négativement au moins 5 critères sur 6

	gen qs_sante= (nb_crit_sante > 5)
	egen pr_qsante= max(qs_sante),by(hhid)
	lab var pr_qsante "qualites des services de sante"

*		 		 Indicateur Maladies et problèmes de santé
*		        -------------------------------------------
	notes : Un membre du ménage souffre d'une maladie chronique /// 
			(tension ou diabète)
	
	gen affecte=inlist(maladie,7,12)
	egen pr_maladie =max(affecte),by(hhid)
	lab var pr_maladie "maladie et problème de sante"

*			 	 Indicateur Vaccination des enfants
*			    ------------------------------------
	notes : de 0-6 ans	Un enfant de 0-6 ans du ménage n'a pas été vacciné ///
			lors de la campagne passée
	
	egen pr_vacciantion=max(vaccination_enfant),by(hhid)
	lab var pr_vacciantion "vaccination des enfants"

*				 Indicateur Couverture maladie	
*			    -------------------------------
	notes : Plus du tiers des membres du ménage ne disposent d'aucune /// 
			forme d'assurance maladie

	** Les privations
	gen pr_assurance =cond(nb_couvmal<(1/3*hhsize),1,0)
	lab var pr_assurance " Couverture maladie"


*				    Indicateur Handicap physique et mental
*			      ------------------------------------------
	notes : Un membre souffre d'un handicap physique/mental l'empêchant ///
			d'exercer une activité ou d'aller à l'école

	egen pr_handicap =max(handicap),by(hhid)
	replace pr_handicap=0 if pr_handicap==2
	lab var pr_handicap "handicap physique et mental"


/*-----------------------------------------------------------------------------	
					    	Dimension Conditions de vie 
-------------------------------------------------------------------------------*/

*				 Indicateur Type de logement 	
*			    -----------------------------
	notes : Le ménage est privé si le logement est une case, baraque ou «autre»

	gen pr_type_log = (type_logem == 4 | type_logem == 5)
	label variable pr_type_log "Type de logement"

*  		 	     Indicateur Électricité	
*			    ------------------------
	notes : La source d'éclairage du ménage n'est pas : électricité, groupe ///
			électrogène ou solaire

	gen pr_electr = !(source_eclairage == 1 | source_eclairage == 2 | source_eclairage == 3)
	label variable pr_electr "Électricité"

*			 	 Indicateur Évacuation des eaux usées 	
*			     -------------------------------------
	notes : Le ménage est privé si l'évacuation se fait dans la cour ou dans ///
			la rue/nature

	gen pr_evac_eu = !(eva_eu == 1 | eva_eu == 2)
	label variable pr_evac_eu "Évacuation eaux usées"
	
*				Indicateur Évacuation des ordures 	
*				-------------------------------
	notes : Le ménage est privé si l'évacuation se fait par tas d'immondices ///
			ou dans la route/rue

	gen pr_evac_ordu = !(eva_ord== 1 | eva_ord==2 | eva_ord==3)
	label variable pr_evac_ordu "Évacuation ordures"

*  		 	     Indicateur Indice de surpeuplement	
*			     ----------------------------------	
	notes : Le ménage est privé si le logement est surpeuplé (plus de ///
			3 personnes par pièce)  ___b

	gen pr_surpeuplemnt = (ind_surpl >= 3)
	label variable pr_surpeuplemnt "Indice de Surpeuplement"

*			 	 Indicateur Eau potable		
*			     -----------------------
	notes : Le ménage n'a pas accès à l'eau potable	

	gen pr_eau_pot = !(inlist(eau_potable, 1, 2, 3, 4, 11, 14, 16))
	label variable pr_eau_pot "Eau potable"

*			  	 Indicateur Énergie de cuisson 	
*		  	     ------------------------------
	notes : Le ménage n'utilise pas d'énergie propre pour la cuisson ///
			(électricité et gaz)

	gen pr_energ_cuis = (energ_cuiss == 0)
	label variable pr_energ_cuis "Énergie pour cuisson"

*			  	 Indicateur Équipements sanitaires 	
*			     ---------------------------------
	notes : Le ménage ne dispose pas de toilettes privées améliorée

	gen pr_equipm_sanit = !(inlist(type_sanitr, 1, 2, 3, 4))
	label variable pr_equipm_sanit "Équipement sanitaire"

*			 	 Indicateur Biens d'équipement	 	
*		   	     -----------------------------
	notes : Le ménage dispose de moins de 2 équipements (ventilateur, TV, ///
			ordinateur, cuisinière, réfrigérateur, bicyclette, motocyclette) ///
			et ne dispose ni de voiture, camion, machine à laver ni de ///
			groupe électrogène

	gen pr_bien_equipm = (nb_biens < 2)
	label variable pr_bien_equipm  "Biens et équipements"	
	
/* -----------------------------------------------------------------------------
					    	Dimension gouvernance et institutions
-------------------------------------------------------------------------------*/
*                    Indicateur Corruption
*				 	 -------------------------------
	notes : Le ménage a été victime d'un racket dans un service publi
	
	egen pr_corruption=max(corruption),by(hhid)
	lab var pr_corruption "corruption"

* 					 Indicateur Agression et vol 
*				     -------------------------------
	notes : Un membre est victime d'agression ou de vol à domicile ou ///
			dans la rue	___20c

	gen subi_agress= (nb_agress_vol!=0)
	egen pr_agres_vol =max(subi_agress),by(hhid)
	lab var pr_agres_vol "Agression et Vol"
	

/*-----------------------------------------------------------------------------
					    	Dimension Emploi
-------------------------------------------------------------------------------*/
*				 	 Indicateur Chômage	 	
*				     ---------------------------------
	notes : Le nombre de chômeurs est supérieur à la moitié des actifs du ménage

	gen nb_chom = cond(nb_chomeurs <= (nb_actifs / 2), 0, 1) 
	egen pr_chom = max(nb_chom),by(hhid)
	lab var pr_chom "chômage"
	
*				     Indicateur Dépendance économique	 	
*				     ---------------------------------
	notes : Le taux de dépendance est supérieur à 2
	
	gen dep_eco = cond(taux_dep <= 2, 0, 1)
	egen pr_dep_eco = max(dep_eco) , by(hhid)
	lab var pr_dep_eco "dépendance économique"
	
*				     Indicateur sous-emploi	 	
*					 ---------------------------------
	notes : Le nombre de travailleurs sous-employés est supérieur au tiers ///
			des occupés du ménage
	
	gen sous_emploi = cond(nb_sous_emp <= (nb_occ / 3), 0, 1)
	egen pr_sous_emp = max(sous_emploi), by(hhid)
	lab var pr_sous_emp "sous emploi"
	
*				 	 Indicateur Travail des enfants
*					 ---------------------------------
	notes : Le ménage est privé s'il y a un enfant de moins de 15 ans ///
			exerçant un travail
	
	gen travail_enfts = cond(nb_enft_trav > 0, 1, 0)
	egen pr_travail_enfts = max(travail_enfts), by(hhid)
	lab var pr_travail_enfts "Travail des enfants"
	
*	   		 	     Indicateur Protection sociale
*				  	 ---------------------------------
	notes : Le nombre de travailleurs n'ayant pas de protection est supérieur ///
			à la moitié des occupés du ménage


	keep hhid hhweight pr_alfa pr_freq pr_late_scol pr_annee_scol pr_qsante pr_maladie ///
		 pr_vacciantion pr_assurance pr_handicap pr_type_log pr_electr /// 
		 pr_evac_eu pr_evac_ordu pr_surpeuplemnt pr_eau_pot pr_energ_cuis  ///
		 pr_dep_eco pr_equipm_sanit pr_bien_equipm pr_corruption pr_agres_vol pr_chom  ///
		 pr_dep_eco pr_sous_emp pr_travail_enfts 
		 
	save "${rdata}\mat_privation.dta", replace