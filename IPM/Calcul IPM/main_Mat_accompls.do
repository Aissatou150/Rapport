*_____________________________________________________________________________
*   			Création de la matrice de privations
*_____________________________________________________________________________

/*-----------------------------------------------------------------------------
						  Dimension Education 
----------------------------------------------------------------------------*/
	use "${repert}/s02_me_SEN2021.dta", clear 	
*_____________________________________________________________________________
*			         Création identifiant unique du ménage
*____________________________________________________________________________ 
	tostring menage, gen(menage_)
	tostring grappe, gen(grappe_)
	gen hhid1 = cond(strlen(menage_) == 1, grappe_ + "0" + menage_, grappe_ + menage_)
	destring hhid1, gen(hhid)
	drop hhid1 grappe_ menage_
* ____________________________________________________________________________ 

	keep hhid s02q14 s02q16
	* Configuration des bases 
	merge m:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta", keepusing(hhsize) nogen
	merge m:m hhid using "${repert}/ehcvm_individu_SEN2021.dta", keepusing(alfa educ_hi educ_scol age ) nogen


*					   	 Indicateur Alphabétisation
*						-----------------------------
	lab var alfa "Alphabétisation des individus"
	rename alfa alphabetisation

	* ------------------------------------------------------------------------
	notes : Privation si Le quart des membres du ménage de 15 ans ou plus ///
			ne sait pas lire ou écrire
	* ------------------------------------------------------------------------

	**  Determination des analphabètes qui ont plus de 15 ans 
	gen n_alfa_15 = cond(alphabetisation==0 & age>=15,1,0)
	**  Total par menage
	egen t_nalfa_15 = total(n_alfa_15),by(hhid)
	**  Les privations
	gen pr_alfa = cond(t_nalfa_15>(1/4*hhsize),1,0)
	lab var pr_alfa "IP Alphabetisation du menage"

	
* 					  Indicateur Fréquentation scolaire
* 					 -----------------------------------
	capture drop frequentation
	clonevar frequentation = educ_hi
	lab var frequentation "Niveau d'éducation"

	* ------------------------------------------------------------------------
	notes : Le ménage a un enfant de 6-16ans qui ne fréquente actuellement ///
			pas l'école
	* ------------------------------------------------------------------------
	
	gen indiv_freq = cond(inrange(age,6,16)& frequentation==1,1,0)
	egen pr_freq = max (indiv_freq), by(hhid)
	lab var pr_freq "IP fréquentation scolaire"


/* 						  Indicateur Retard scolaire
						-----------------------------
			
Au Sénégal, l'âge pour chaque niveau d'étude est le suivant : 
Préscolaire: 3 à 5 ans.
Enseignement primaire: 6 à 11 ans.
Enseignement secondaire 1 : 12 à 15 ans.
Enseignement secondaire 2 : 16 à 18 ans.
Enseignement supérieur: À partir de 19 ans. 
*/

	* ------------------------------------------------------------------------
	notes : Le ménage a un enfant de 8-13ans ayant un retard scolaire de /// 
			2ans ou plus
	* ------------------------------------------------------------------------


	gen retard_scolaire = 0
	* Pour les enfants de 8 ans → devraient être au moins en 2e année (CE1 = s02q14==2 & s02q16==2)
	replace retard_scolaire = 1 if age == 8 & ///
   ((s02q14 == 2 & s02q16 <= 1) | s02q14 < 2)
	* Pour les enfants de 9 ans → devraient être au moins en 3e année (CE2)
	replace retard_scolaire = 1 if age == 9 & ///
   ((s02q14 == 2 & s02q16 <= 2) | s02q14 < 2)
	* Pour les enfants de 10 ans → au moins 4e année (CM1)
	replace retard_scolaire = 1 if age == 10 & ///
   ((s02q14 == 2 & s02q16 <= 3) | s02q14 < 2)
	* Pour les enfants de 11 ans → au moins 5e année (CM2)
	replace retard_scolaire = 1 if age == 11 & ///
   ((s02q14 == 2 & s02q16 <= 4) | s02q14 < 2)
	* Pour les enfants de 12 ans → au moins 6e (secondaire 1, 1ère année)
	replace retard_scolaire = 1 if age == 12 & ///
   ((s02q14 == 2 & s02q16 <= 5) | s02q14 < 2 | ///
    (s02q14 == 3 & s02q16 == 1))  // tolère début du secondaire
	* Pour les enfants de 13 ans → au moins 2e année du secondaire 1
	replace retard_scolaire = 1 if age == 13 & ///
   ((s02q14 == 2 & s02q16 <= 6) | s02q14 < 2 | ///
    (s02q14 == 3 & s02q16 <= 1))

	egen pr_late_scol = max(retard_scolaire), by(hhid)
	lab var pr_late_scol "IP retard scolaire"


*					 Indicateur Nombre d'années de scolarité 
*					-----------------------------------------

	* ------------------------------------------------------------------------
	notes : Aucun membre du ménage âgé de 15 ans ou plus n'a complété ///
			6 années d'études
	* ------------------------------------------------------------------------

	gen an_etude = cond((age>=15 & educ_hi > 3),0,1)
	egen pr_annee_scol= max(an_etude),by(hhid)
	lab var pr_annee_scol "IP nombres d'années de scolarite"


	keep hhid pr_alfa pr_freq pr_late_scol pr_annee_scol
	save "${rdata}\d_education.dta", replace	

/* ----------------------------------------------------------------------------
								Dimension Santé 
-------------------------------------------------------------------------------*/
		use "${repert}/s03_me_SEN2021.dta", clear
*_____________________________________________________________________________
*			         Création identifiant unique du ménage
*____________________________________________________________________________ 
	tostring menage, gen(menage_)
	tostring grappe, gen(grappe_)
	gen hhid1 = cond(strlen(menage_) == 1, grappe_ + "0" + menage_, grappe_ + menage_)
	destring hhid1, gen(hhid)
	drop hhid1 grappe_ menage_
* ____________________________________________________________________________ 

	* Configuration des bases 
	merge m:m hhid using "${repert}ehcvm_individu_SEN2021.dta", keepusing(couvmal handit) nogen
	merge m:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta", keepusing(hhsize) nogen

*			 		Indicateur Qualité des services de santé
*				   ------------------------------------------
	local var   s03q10__1 s03q10__2 s03q10__3 s03q10__4 s03q10__5 s03q10__6 ///
				s03q10__7 s03q10__8
	 foreach i in `var'{
		replace `i'=0 if missing(`i')
	}

	local var  s03q10__1 s03q10__2 s03q10__3 s03q10__4 s03q10__5 s03q10__6 ///
				s03q10__7 s03q10__8
	 foreach i in `var'{
		replace `i'=0 if `i'==2 
	}
	
	gen nb_crit_sante = s03q10__1 + s03q10__2 + s03q10__3 + s03q10__4 + ///
						s03q10__5 + s03q10__6 + s03q10__7 + s03q10__8 

	label values nb_crit_sante nb_crit_sante_lbl
	lab var  nb_crit_sante "Score d'appréciations des services de santé"

	* ------------------------------------------------------------------------	
	notes : Un membre du ménage apprécie négativement au moins 5 critères sur 6
	* ------------------------------------------------------------------------

	gen qs_sante= (nb_crit_sante > 5)
	*gen qs_sante = cond(nb_crit_sante/8 >= 5/6)
	egen pr_qsante= max(qs_sante),by(hhid)
	lab var pr_qsante "IP qualites des services de sante"

	
*		 		   Indicateur Maladies et problèmes de santé
*		          -------------------------------------------
	replace s03q02 = 0 if s03q01==2
	label define s03q02 1 "Fièvre/Paludisme" 2 "Diarrhée" 3 "Accident/Blessure" ///
						4 "Problème dentaire" 5 "Problème de peau" ///
						6 "Maladie des yeux" 7 "Problème de tension" ///
						8 "Fièvre typhoïde" 9 "Problème d'estomac (ulcère, cancer, etc)" ///
						10 "Mal de gorge" 11 "Toux, rhume " 12 "Diabète" ///
						13 "Meningite" 14 "COVID-19" ///
						15 "Complications liées à grossesse ou à l'accouchement" ///
						16 "Douleurs/fatigue" 17 "Anémie/drépanocytose" ///
						18 "Autre" 19 "Maux de ventre" 20 "Probleme respiratoire" ///
						0 "Aucune maladie", replace

	clonevar maladie30J = s03q02
	lab var maladie30J "Principal problème de sante de l'individu 30 DJ"

	replace s03q21 = 0 if s03q19==2
	label define s03q02 1 "Fièvre/Paludisme" 2 "Diarrhée" 3 "Accident/Blessure" ///
						4 "Problème dentaire" 5 "Problème de peau" ///
						6 "Maladie des yeux" 7 "Problème de tension" ///
						8 "Fièvre typhoïde" 9 "Problème d'estomac (ulcère, cancer, etc)" ///
						10 "Mal de gorge" 11 "Toux, rhume " 12 "Diabète" ///
						13 "Meningite" 14 "COVID-19" ///
						15 "Complications liées à grossesse ou à l'accouchement" ///
						16 "Douleurs/fatigue" 17 "Anémie/drépanocytose" ///
						18 "Autre" 19 "Maux de ventre" 20 "Probleme respiratoire" ///
						0 "Aucune maladie", replace

	clonevar maladie12m = s03q21
	lab var maladie12m "Principal problème de sante de l'individu 12 DM"

	gen maladie_chronq = s03q21

	replace maladie_chronq = cond((maladie_chronq !=12 & maladie_chronq!=7) & (s03q02==12 | s03q02==7), s03q02, maladie_chronq)

	label values maladie_chronq maladie_chronqlbl
	label define maladie_chronqlbl 1 "Fièvre/Paludisme" 2 "Diarrhée" ///
								   3 "Accident/Blessure" 4 "Problème dentaire" ///
								   5 "Problème de peau" 6 "Maladie des yeux" ///
								   7 "Problème de tension" 8 "Fièvre typhoïde" ///
								   9 "Problème d'estomac (ulcère, cancer, etc)" ///
								   10 "Mal de gorge" 11 "Toux, rhume " ///
								   12 "Diabète" 13 "Meningite" 14 "COVID-19" ///
								   15 "Complications liées à grossesse ou à l'accouchement" ///
								   16 "Douleurs/fatigue" 17 "Anémie/drépanocytose" ///
								   18 "Autre" 19 "Maux de ventre" 20 "Probleme respiratoire" ///
								   0 "Aucune maladie", replace

	lab var maladie_chronq "Principal problème de sante de l'individu 12 Dm / focus MC"

	* ------------------------------------------------------------------------
	notes : Un membre du ménage souffre d'une maladie chronique /// 
			(tension ou diabète)
	* ------------------------------------------------------------------------

	gen affecte=inlist(maladie_chronq,7,12)
	egen pr_maladie =max(affecte),by(hhid)
	lab var pr_maladie "IP maladie et problème de sante"

	
*			 	 	  Indicateur Vaccination des enfants
*			         ------------------------------------
	clonevar vaccination_enfant = s03q52
	replace vaccination_enfant=	0 if vaccination_enfant==2
	replace vaccination_enfant=	2 if missing(vaccination_enfant)
	label define vaccination_enfant 1 "Oui" 0 "Non" 2 "Non concerné" 
	label values vaccination_enfant vaccination_enfant
	lab var vaccination_enfant "Est ce que l'enfant à pris tous ses vaccins obligatoires"

	* ------------------------------------------------------------------------
	notes : Un enfant de 0-5 ans du ménage n'a pas été vacciné ///
			lors de la campagne passée
	* ------------------------------------------------------------------------
	gen vacc_O_5 = cond(vaccination_enfant==0, 1, 0)
	egen pr_vacciantion=max(vaccination_enfant),by(hhid)
	lab var pr_vacciantion "IP vaccination des enfants"


*				 		Indicateur Couverture maladie	
*					   -------------------------------
	egen nb_couvmal = total(couvmal), by(hhid)
	label values nb_couvmal nb_couvmal_lbl
	label variable nb_couvmal "Nombre d'individus bénéficiant d'une couverture maladie"
	drop couvmal

	* ------------------------------------------------------------------------	
	notes : Plus du tiers des membres du ménage ne disposent d'aucune /// 
			forme d'assurance maladie
	* ------------------------------------------------------------------------

	gen pr_assurance =cond((hhsize-nb_couvmal)>(1/3*hhsize),1,0)
	lab var pr_assurance " Couverture maladie"

*				    Indicateur Handicap physique et mental
*			      ------------------------------------------
	gen handicap = 0
	replace handicap = 1 if (s03q41==4 | s03q42==4 | s03q43==4 | s03q44==4 | s03q45==4 | s03q46==4 )
	lab var handicap "handicap physique et mental"
	
	* ------------------------------------------------------------------------	
		notes : Un membre souffre d'un handicap physique/mental l'empêchant ///
			d'exercer une activité ou d'aller à l'école
	* ------------------------------------------------------------------------
	
	egen pr_handicap =max(handicap),by(hhid)
	lab var pr_handicap "IP handicap physique et mental"

	
	keep hhid pr_qsante pr_maladie pr_vacciantion pr_assurance pr_handicap
	save "${rdata}\d_sante.dta", replace 


/* ----------------------------------------------------------------------------
					    	Dimension Conditions de vie 
-----------------------------------------------------------------------------*/
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
	merge 1:1 hhid using "${rdata}\ehcvm_menage_SEN2021_copie.dta", ///
				   keepusing(ordin tv fer frigo cuisin decod car cuisin) nogen

*				 		Indicateur Type de logement 	
*					   -------------------------------
	rename s11q01 type_logem
	* ------------------------------------------------------------------------		
	notes : Le ménage est privé si le logement est une case, baraque ou «autre»
	* ------------------------------------------------------------------------	
	
	gen pr_type_log = (type_logem == 4 | type_logem == 5)
	label variable pr_type_log "IP Type de logement"

	
*				 		Indicateur Électricité	
*					   -------------------------------
	rename s11q37 source_eclairage 								// 11 missing
	* ------------------------------------------------------------------------	
	notes : La source d'éclairage du ménage n'est pas : électricité, groupe ///
			électrogène ou solaire
	* ------------------------------------------------------------------------	

	gen pr_electr = !(source_eclairage == 1 |source_eclairage == 2 | ///
					source_eclairage == 3)
	label variable pr_electr "IP Électricité"

	
*				 	    Indicateur Évacuation des eaux usées 	
*					   -------------------------------
	rename s11q59 eva_eu
	* ------------------------------------------------------------------------	
	notes : Le ménage est privé si l'évacuation se fait dans la cour ou dans ///
			la rue/nature
	* ------------------------------------------------------------------------	
			
	gen pr_evac_eu = !(eva_eu == 1 | eva_eu == 2)
	label variable pr_evac_eu "IP Évacuation eaux usées"


*				 		Indicateur Évacuation des ordures 	
*					   -------------------------------
	rename s11q53 eva_ord
	* ------------------------------------------------------------------------		
	notes :  Le ménage est privé si l'évacuation se fait par tas d'immondices ///
				ou dans la route/rue
	* ------------------------------------------------------------------------		
	
	gen pr_eva_ord = !(eva_ord==1|eva_ord==2)
	lab var pr_eva_ord "IP Évacuation orudures ménagères"

	
*				 		Indicateur Eau potable		
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

	
*				 	    Indicateur Équipements sanitaires 	
*					    ---------------------------------
	rename s11q54 type_sanitr
	* ------------------------------------------------------------------------		
	notes : Le ménage ne dispose pas de toilettes privées améliorée
	* ------------------------------------------------------------------------	

	gen pr_equipm_sanit = !(inlist(type_sanitr, 1, 2, 3, 4))
	label variable pr_equipm_sanit "IP Équipement sanitaire"
	

*				        Indicateur Indice de surpeuplement	
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

		
*				 		Indicateur Biens d'équipement	 	
*					   -------------------------------
	gen nb_biens = ordin + tv + fer + frigo + cuisin + decod + car
	lab var nb_biens "nombre de biens d'équipements"

	* ------------------------------------------------------------------------		
	notes : Le ménage dispose de moins de 2 équipements (ventilateur, TV, ///
		   ordinateur, cuisinière, réfrigérateur, bicyclette, motocyclette) ///
		   et ne dispose ni de voiture, camion, machine à laver ni de       ///
	   	   groupe électrogène
	* ------------------------------------------------------------------------	

	gen pr_bien_equipm = (nb_biens < 2)
	label variable pr_bien_equipm  "IP Biens et équipements"	


*				 		Indicateur Énergie de cuisson 	
*					   -------------------------------
	rename cuisin energ_cuiss
	* ------------------------------------------------------------------------	
	notes : Le ménage n'utilise pas d'énergie propre pour la cuisson ///
			(électricité et gaz)
	* ------------------------------------------------------------------------	
	gen pr_energ_cuis = (energ_cuiss == 0)
	label variable pr_energ_cuis "IP Énergie pour cuisson"
	
	keep hhid pr_type_log pr_electr pr_evac_eu pr_eva_ord pr_eau_pot ///
		      pr_equipm_sanit pr_surpeuplemnt pr_bien_equipm pr_energ_cuis

	save "${rdata}\d_condvie.dta", replace

/*------------------------------------------------------------------------------
				 	Dimension gouvernance et institutions 
-------------------------------------------------------------------------------*/
*                               Corruption
*					   -------------------------------
					use "${repert}s20b_1_me_SEN2021",clear
*_____________________________________________________________________________
*			         Création identifiant unique du ménage
* ____________________________________________________________________________ 
	tostring grappe, gen(grap)
	tostring menage, gen(men)
	gen id =cond(strlen(men)==1,grap+"0"+men,grap+men)
	destring id,gen(hhid)
	drop id grap men
* ____________________________________________________________________________ 

	clonevar corruption = s20bq12__3 
	lab var corruption "Si le ménage a subi un racket"
	label define ouinon 0 "oui" 1 "non"
	label values corruption ouinon

	*------------------------------------------------------------------------
	notes : Le ménage a été victime d'un racket dans un service public
	*------------------------------------------------------------------------
	
	egen pr_corruption=max(corruption),by(hhid)
	lab var pr_corruption "corruption"

	keep hhid pr_corruption	
	save "${rdata}\corruption.dta",replace

* 								Agression et vol 
*					   -------------------------------
					use "${repert}s20c_me_SEN2021", clear 
*_____________________________________________________________________________
*			         Création identifiant unique du ménage

	tostring grappe, gen(grap)
	tostring menage, gen(men)
	gen id =cond(strlen(men)==1,grap+"0"+men,grap+men)
	destring id,gen(hhid)
	drop id grap men
*____________________________________________________________________________ 

	clonevar nb_agress_vol = s20cq03
	replace nb_agress_vol =0 if missing(nb_agress_vol)
	lab var nb_agress_vol "nombres de personnes ayant subi une agression ou vol dans le menage"

	* ------------------------------------------------------------------------		
	notes : Un membre est victime d'agression ou de vol à domicile ou ///
			dans la rue	___20c
	* ------------------------------------------------------------------------	

	gen subi_agress= (nb_agress_vol!=0)
	egen pr_agres_vol =max(subi_agress),by(hhid)
	lab var pr_agres_vol "IP Agression et Vol"

	
	* Merging
	merge 1:1 hhid using "${rdata}\corruption.dta" , nogen

	keep hhid pr_corruption pr_agres_vol 
	save "${rdata}\d_gouv_inst.dta",replace


/* -----------------------------------------------------------------------------
							Dimension emploi 
-------------------------------------------------------------------------------*/
			use "${repert}/s04b_me_SEN2021.dta", clear
*_____________________________________________________________________________
*			         Création identifiant unique du ménage

	tostring grappe, gen(grap)
	tostring menage, gen(men)
	gen id =cond(strlen(men)==1,grap+"0"+men,grap+men)
	destring id,gen(hhid)
	drop id grap men
* ____________________________________________________________________________ 

	rename s04q38 cotisation_CSS
	keep hhid cotisation_CSS
	merge m:m hhid using "${repert}/ehcvm_individu_SEN2021.dta", nogen


*				 	1- Indicateur Chômage	 	
*					   -------------------------------
	 // Nombre d'actifs dans le ménage
	 gen actif = inlist(activ7j, 1, 2, 3, 4) 
	 bysort hhid: egen nb_actifs = total(actif)
	 
	 // Nombre de chômeurs dans le ménage
	 gen chomeur = (activ7j == 4)
	 bysort hhid: egen nb_chomeurs = total(chomeur)
	 lab var nb_chomeurs "Nombres de chômeurs"

	* ------------------------------------------------------------------------	
	notes : Le nombre de chômeurs est supérieur à la moitié des actifs du ménage
	* ------------------------------------------------------------------------	

	gen nb_chom = cond(nb_chomeurs <= (nb_actifs / 2), 0, 1) 
	egen pr_chom = max(nb_chom),by(hhid)
	lab var pr_chom "IP chômage"

	 
*				     2- Indicateur Dépendance économique	 	
*				     -------------------------------
	 // Nombre d'inactifs par ménage
	 gen inactif = (actif == 0)
	 bysort hhid: egen nb_inactifs = total(inactif)
	 
	 // Taux de dépendance économique
	 gen taux_dep = nb_inactifs / nb_actifs
	 replace taux_dep = 0 if nb_actifs == 0 // dépendance maximale si aucun actif
	 lab var taux_dep "taux de dépendance économique"
	
	* ------------------------------------------------------------------------	
 	notes : Le taux de dépendance est supérieur à 2
	* ------------------------------------------------------------------------	
	gen dep_eco = cond(taux_dep > 2, 1, 0)
	egen pr_dep_eco = max(dep_eco) , by(hhid)
	lab var pr_dep_eco "IP dépendance économique"

 
*				 	  3- Indicateur sous-emploi	 	
*					   -------------------------------
 /* Au Sénégal, le nombre d'heures de travail
 réglementaire est de 40h / semaine (législation du travail au Sénégal) */
	 global heures_trav_sem_legal = 40
 
	 // Nombre d'occupés par ménage
	 gen occup = cond(activ7j == 1, 1,0)
	 bysort hhid: egen nb_occup = total(occ)
	 
	 // Individus en sous emploi
	 gen emploi = cond(activ7j == 1 | activ7j == 2 | activ7j == 3, 1, 0)
	 egen heures_trav_an = rowtotal(volhor volhor_sec)
	 gen heures_trav_sem = heures_trav_an / 52
	 gen ind_sous_emp = cond(emploi & (heures_trav_sem < $heures_trav_sem_legal), 1, 0)
	 replace ind_sous_emp = cond(activ7j == 3, 0, ind_sous_emp) // retirer les TF ne cherchant pas un emploi
	 
	 *gen ind_sous_emp = cond(occup==1 & (heures_trav_sem < $heures_trav_sem_legal), 1, 0)

	 
	 // Nombre d'individus en sous emploi par ménage
	 bysort hhid: egen nb_sous_emp = total(ind_sous_emp)
	 label var nb_sous_emp "nombres de sous-emploi"
 
	* ------------------------------------------------------------------------	
	notes : Le nombre de travailleurs sous-employés est supérieur au tiers ///
			des occupés du ménage
	* ------------------------------------------------------------------------	
	gen sous_emploi  = cond(nb_sous_emp <= (nb_occ / 3), 0, 1)
	egen pr_sous_emp = max(sous_emploi), by(hhid)
	lab var pr_sous_emp "IP sous emploi"
 
 
 
*				 	   4- Indicateur Travail des enfants
*					  -----------------------------------
  // Identification des ménages ayant au moins un enfant qui travaille
	gen enft_trav = cond(emploi == 1 & age < 15, 1, 0)
	bysort hhid: egen nb_enft_trav = total(enft_trav)
	lab var nb_enft_trav "travail des enfants"
 
	* ------------------------------------------------------------------------	
 	notes : Le ménage est privé s'il y a un enfant de moins de 15 ans ///
			exerçant un travail
	* ------------------------------------------------------------------------	
	gen travail_enfts     = cond(nb_enft_trav > 0, 1, 0)
	egen pr_travail_enfts = max(travail_enfts), by(hhid)
	lab var pr_travail_enfts "IP Travail des enfants"

 
*				 	   5- Indicateur Protection sociale
*					  ----------------------------------
 
	gen trav_not_protec = cond((emploi==1 & cotisation_CSS==2),1,0)
	bysort hhid : egen nb_trav_nprotect = total(trav_not_protec)
	lab var nb_trav_nprotect "nombres de travailleurs sans protection sociale"
    
	/* NOTES : Gerer les individus qui se trouvent dans "df_protec_so" et non 
			dans "individus" */
	
	* ------------------------------------------------------------------------	
	notes : Le nombre de travailleurs n'ayant pas de protection est supérieur ///
			à la moitié des occupés du ménage
	* ------------------------------------------------------------------------	
	gen protec_social = cond(nb_trav_nprotect>(nb_occ/2),1,0)		
	egen pr_protec_social = max(protec_social), by (hhid)
	lab var pr_protec_social "IP Protection sociale"
		
* ------------------------------------------------------------------------	
	keep hhid pr_chom pr_dep_eco pr_sous_emp pr_travail_enfts pr_protec_social	
	save "${rdata}\d_emploi.dta" , replace 


*-------------------------------------------------------------------------------
*		Création de la matrice des privations 
*-------------------------------------------------------------------------------
	use "${rdata}\d_condvie.dta", clear

	merge 1:1 hhid using "${rdata}\d_gouv_inst",nogen
	merge 1:m hhid using "${rdata}\d_sante.dta", nogen
	merge m:m hhid using "${rdata}\d_education.dta", nogen
	merge m:m hhid using "${rdata}\d_emploi",nogen

	* Sauvegarde de la matrice d'accomplissements
	save "${rdata}\matrice_privations.dta",replace

	* Sauvegarde de la matrice d'accomplissements
	merge m:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta",nogen keepusing(hhweight zref)


	save "${rdata}\matrice_privations2.dta",replace
