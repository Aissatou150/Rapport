/*-----------------------------------------------------------------------------
						  Dimension Education 
----------------------------------------------------------------------------*/
	use "${repert}s02_me_SEN2021.dta", clear 	
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
	merge m:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta", ///
				   keepusing(hhsize) nogen
	merge m:m hhid using "${repert}/ehcvm_individu_SEN2021.dta", ///
				   keepusing(alfa educ_hi educ_scol age ) nogen


*				   	 1. Indicateur Alphabétisation
*					-------------------------------
	lab var alfa "Alphabétisation des individus"
	rename alfa alphabetisation

	* ------------------------------------------------------------------------
	notes : Privation si Le quart des membres du ménage de 15 ans ou plus ///
			ne sait pas lire ou écrire
	* ------------------------------------------------------------------------

	**  Determination des analphabètes qui ont plus de 15 ans 
	gen n_alfa_15 = cond(alphabetisation==0 & age>15,1,0)
	**  Total par menage
	egen t_nalfa_15 = total(n_alfa_15),by(hhid)
	**  Les privations
	gen pr_alfa = cond(t_nalfa_15>=(1/4*hhsize),1,0)
	lab var pr_alfa "IP Alphabetisation du menage"

	
* 					 2. Indicateur Fréquentation scolaire
* 					 -------------------------------------
	capture drop frequentation
	clonevar frequentation = educ_hi
	lab var frequentation "Niveau d'éducation"

	* ------------------------------------------------------------------------
	notes : Le ménage a un enfant de 6-16ans qui ne fréquente actuellement ///
			pas l'école
	* ------------------------------------------------------------------------
	
	gen indiv_freq = cond(inrange(age,6,16) & frequentation==1,1,0)
	egen pr_freq = max (indiv_freq), by(hhid)
	lab var pr_freq "IP fréquentation scolaire"


/* 					  3. Indicateur Retard scolaire
					  ------------------------------
			
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


*					 4. Indicateur Nombre d'années de scolarité 
*					--------------------------------------------

	* ------------------------------------------------------------------------
	notes : Aucun membre du ménage âgé de 15 ans ou plus n'a complété ///
			6 années d'études
	* ------------------------------------------------------------------------

/*
	gen age15 = cond(age>=15,1,0)
	egen t_age15 = total(age15),by(hhid)
	
	gen etude15ans = cond((age>=15 & educ_hi < 3),1,0)
	egen t_an_etude = total(etude15ans), by (hhid)
	
	gen an_etude=cond(t_an_etude==t_age15,1,0)
	
	egen pr_annee_scol= max(an_etude),by(hhid)
	lab var pr_annee_scol "IP nombres d'années de scolarite"
*/
	

	gen an_etude = cond((age>=15 & educ_hi > 3),0,1)
	egen pr_annee_scol= max(an_etude),by(hhid)
	lab var pr_annee_scol "IP nombres d'années de scolarite"


	keep hhid pr_alfa pr_freq pr_late_scol pr_annee_scol
	save "${rdata}\d_education.dta", replace	
