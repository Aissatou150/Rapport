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

	*Sauvegarde de la matrice d'accomplissements
	merge m:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta",nogen /// 
				   keepusing(hhweight zref)


	save "${rdata}\matrice_privations2.dta",replace
