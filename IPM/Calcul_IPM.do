
*-------------------------------------------------------*
* Étape 1 : Pondération des indicateurs (pondération globale)
* Chaque dimension reçoit un poids de 1/5 = 0.2
* Pondération à l'intérieur de chaque dimension = 0.2 / nb_indicateurs
*-------------------------------------------------------*
use "${rdata}\mat_privation.dta", clear
svyset [pw=hhweight]

*   Définition des différents poids
*	-------------------------------

	 // Poids indicateurs dim 1 (éducation)
	 global poids_edu 	 = 0.05
	 // Poids indicateurs dim 2 (santé)
	 global poids_sant   = 0.04
	 // Poids indicateurs dim 3 (conditions de vie)
	 global poids_cond_vie = (0.2/9)
	 // Poids indicateurs dim 4 (emploi)
	 global poids_emploi    = 0.05
	 // Poids indicateurs dim 5 (Gouvernance & institutions)
	 global poids_gouv_inst = (0.2/2)

*-------------------------------------------------------*
* Étape 2 : Calcul des scores 
*-------------------------------------------------------*

// calcul des scores des indicateurs

	* Dimension 1 : Education
	ds pr_alfa - pr_annee_scol
	local ind_dim `r(varlist)'
	foreach i of local ind_dim {
		gen scor1_`i'= `i' * $poids_edu
	}
		
	* Dimension 2 : Santé
	ds pr_qsante - pr_handicap
	local ind_dim `r(varlist)'
	foreach i of local ind_dim {
		gen scor2_`i'= `i' * $poids_sant
	}
	
	* Dimension 3 : Condition de vie
	ds pr_type_log - pr_bien_equipm
	local ind_dim `r(varlist)'
	foreach i of local ind_dim {
		gen scor3_`i'= `i' * $poids_cond_vie
	}		
	
	* Dimension 4 : Emploi 
	ds pr_chom - pr_travail_enfts
	local ind_dim `r(varlist)'
	foreach i of local ind_dim {
		gen scor4_`i'= `i' * $poids_emploi
	}
	
	* Dimension 5 : Gouvernance & institutions
	ds pr_corruption - pr_agres_vol
	local ind_dim `r(varlist)'
	foreach i of local ind_dim {
		gen scor5_`i'= `i' * $poids_gouv_inst
	}

		
// calcul des scores des indicateurs

	* Dimension 1 : Education
	 egen scor_dim_edu      = rowtotal(scor1_*)	

	* Dimension 2 : Santé
	 egen scor_dim_sant     = rowtotal(scor2_*)	
	
	* Dimension 3 : Condition de vie
	 egen scor_dim_condvie  = rowtotal(scor3_*)		
	
	* Dimension 4 : Emploi 
	 egen scor_dim_emploi   = rowtotal(scor4_*)	
	
	* Dimension 3 : Gouvernance & institutions
	 egen scor_dim_gouvinst = rowtotal(scor5_*)	

*-------------------------------------------------------*
* Étape 3 : Cumul pondéré des privations
*-------------------------------------------------------*

egen cumul_pr  = rowtotal (pr_alfa - pr_travail_enfts)
label variable cumul_pr "Score total des privations"

egen score_final = rowtotal (scor1_pr_alfa - scor5_pr_agres_vol)
label variable score_final "Score total des privations pondéré "

*-------------------------------------------------------*
* Étape 4 : Identification des pauvres multidimensionnels
* Seuil fixé à 33% le seuil standard (4/12=0.33)
*-------------------------------------------------------*

// Définition du seuil de pauvreté 
	global seuil_PM = 0.33

gen pauvre = (score_final >= $seuil_PM)
label variable pauvre "Pauvre multidimensionnel (1=Oui)"

*-------------------------------------------------------*
* Étape 5 : Calcul de l'incidence (H)
*-------------------------------------------------------*
svy: mean is_pauvre
scalar H_scl =r(table)[1,1]

gen H = H_scl
scalar drop H_scl
label variable H "Incidence H de la pauvreté multidimensionnelle"

*-------------------------------------------------------*
* Étape 5 : Calcul de l'intensité (A)
*-------------------------------------------------------*
global nb_ind= 21
gen indiv_priv= cumul_pr/$nb_ind 

svy, subpop(pauvre) : mean indiv_priv
scalar A_scl =r(table)[1,1]

gen A = A_scl
scalar drop A_scl
label variable A "Intensité moyenne A chez les pauvres"

*-------------------------------------------------------*
* Étape 6 : Calcul de l'IPM
*-------------------------------------------------------*
gen IPM = H * A
label variable IPM "Indice de pauvreté multidimensionnelle"


*-------------------------------------------------------*
* Étape 7 : Sauvegarde des résultats
*-------------------------------------------------------*
save "${data}\base_IPM.dta", replace

