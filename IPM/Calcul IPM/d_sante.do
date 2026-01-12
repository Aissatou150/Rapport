/* ----------------------------------------------------------------------------
								Dimension Santé 
-------------------------------------------------------------------------------*/
		use "${repert}/s03_me_SEN2021.dta", clear

*____________________________________________________________________________
*			         Création identifiant unique du ménage
*____________________________________________________________________________ 
	tostring menage, gen(menage_)
	tostring grappe, gen(grappe_)
	gen hhid1 = cond(strlen(menage_) == 1, grappe_ + "0" + menage_, grappe_ + menage_)
	destring hhid1, gen(hhid)
	drop hhid1 grappe_ menage_
* ____________________________________________________________________________ 

	* Configuration des bases 
	merge m:m hhid using "${repert}ehcvm_individu_SEN2021.dta", ///
	keepusing(couvmal handit aff30j ) nogen
	merge m:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta", ///
	keepusing(hhsize) nogen

	
	
*			 		1. Indicateur Qualité des services de santé
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
	*gen qs_sante = cond((nb_crit_sante/8) >= (5/6),1,0)
	egen pr_qsante= max(qs_sante),by(hhid)
	lab var pr_qsante "IP qualites des services de sante"

	
*		 		   2. Indicateur Maladies et problèmes de santé
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
	

	*gen     affecte =0
	*replace affecte =1 if (aff30j == 7 | aff30j==12)
								   

	* ------------------------------------------------------------------------
	notes : Un membre du ménage souffre d'une maladie chronique /// 
			(tension ou diabète)
	* ------------------------------------------------------------------------

	gen affecte=inlist(maladie_chronq,7,12)
	egen pr_maladie =max(affecte),by(hhid)
	lab var pr_maladie "IP maladie et problème de sante"

	
*			 	 	 3. Indicateur Vaccination des enfants
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
	egen pr_vacciantion=max(vacc_O_5),by(hhid)
	lab var pr_vacciantion "IP vaccination des enfants"


*				 	4. Indicateur Couverture maladie	
*					 -------------------------------
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

*				    5. Indicateur Handicap physique et mental
*			      ------------------------------------------
	rename handit handicap
	
	/*gen handicap = 0
	replace handicap = 1 if (s03q41==4 | s03q42==4 | s03q43==4 | s03q44==4 | s03q45==4 | s03q46==4 )
	lab var handicap "handicap physique et mental"
	*/
	* ------------------------------------------------------------------------	
		notes : Un membre souffre d'un handicap physique/mental l'empêchant ///
			d'exercer une activité ou d'aller à l'école
	* ------------------------------------------------------------------------
	
	egen pr_handicap =max(handicap),by(hhid)
	lab var pr_handicap "IP handicap physique et mental"

	
	keep hhid pr_qsante pr_maladie pr_vacciantion pr_assurance pr_handicap
	save "${rdata}\d_sante.dta", replace 
