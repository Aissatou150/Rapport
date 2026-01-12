 
*______________________________________________________________________
*					 Partie: Analyse de l'IPM
*______________________________________________________________________

	use "${repert}s00_me_SEN2021.dta", clear
*_____________________________________________________________________________
*			         Création identifiant unique du ménage

	tostring menage, gen(menage_)
	tostring grappe, gen(grappe_)
	gen hhid1 = cond(strlen(menage_) == 1, grappe_+"0"+menage_, grappe_+menage_)
	destring hhid1, gen(hhid)
	drop hhid1 grappe_ menage_
* ____________________________________________________________________________ 

	rename s00q02 departement
	
	keep hhid departement
	
	merge 1:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta", ///
			   keepusing(region pcexp hmstat hgender heduc ///
						 milieu hhsize dtot hactiv7j hage halfa) nogen
	merge 1:m hhid using "${rdata}\base_IPM.dta", nogen
	
* ---------------------------------------------------------------------------

	*-------------------------------------------------------*
	*   IPM par DEPARTEMENT
	*-------------------------------------------------------*

	* Assurer une bonne déclaration du poids
	svyset [pw = hhweight]

	* Vérifier les valeurs du département
	levelsof departement, local(depts)

	* ----------------- 1. Calcul de H (incidence) ----------------- *
	gen H_dept = .

	foreach d of local depts {
		svy, subpop(if departement == `d'): mean pauvre
		scalar H_val = r(table)[1,1]
		replace H_dept = H_val if departement == `d'
		scalar drop H_val
	}

	* ----------------- 2. Calcul de A (intensité) ----------------- *
	gen A_dept = .

	foreach d of local depts {
		svy, subpop(if departement == `d' & pauvre == 1): mean indiv_priv
		scalar A_val = r(table)[1,1]
		replace A_dept = A_val if departement == `d'
		scalar drop A_val
	}

	* ----------------- 3. IPM département ----------------- *
	gen IPM_dept = H_dept * A_dept

	* ----------------- 4. Sauvegarde propre en tableau ----------------- *
	preserve

	collapse (first) H_dept A_dept IPM_dept [pw = hhweight], by(departement)

	format H_dept A_dept IPM_dept %9.2f

	export excel using "${routput}/synthese_IPM.xlsx", ///
		sheet("departement") firstrow(variables) sheetmodify

	restore