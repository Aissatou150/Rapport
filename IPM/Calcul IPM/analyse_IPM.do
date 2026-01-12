*______________________________________________________________________
*					 Partie: Analyse de l'IPM
*______________________________________________________________________

	use "${rdata}\base_IPM.dta", clear

	merge m:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta", keepusing(region zref pcexp hmstat hgender heduc milieu hhsize dtot hactiv7j hage halfa) nogen

	gen milieu_bis =.
	replace milieu_bis=1 if  region==1
	replace milieu_bis=2 if  milieu==1 & region!=1
	replace milieu_bis=3 if  milieu==2 & region!=1

	label values milieu_bis milieux_lbl
	label define milieux_lbl 1 "Dakar urbain" 2 "Autres urbains" 3 "rural"
	lab var milieu_bis "milieu de résidence"

	save "${rdata}\base_IPM_bis.dta", replace 
	
*-------------------------------------------------------*
* 	1. IPM selon le milieu de résidence
*-------------------------------------------------------*

	* Déclaration du plan de sondage
	svyset [pw = hhweight]

	* Récupérer les valeurs de milieu
	levelsof milieu_bis, local(milieux)

	* Initialisation
	gen H_milieu = .
	gen A_milieu = .

	* ---- 1A : Incidence H ----
	foreach m of local milieux {
		svy, subpop(if milieu_bis == `m'): mean pauvre
		replace H_milieu = r(table)[1,1] if milieu_bis == `m'
	}

	* ---- 1B : Intensité A ----
	foreach m of local milieux {
		svy, subpop(if milieu_bis == `m' & pauvre==1): mean indiv_priv
		replace A_milieu = r(table)[1,1] if milieu_bis == `m'
	}

	* ---- 1C : IPM ----
	gen IPM_milieu = H_milieu * A_milieu

	* ---- Export ----
	preserve
	collapse (mean) H_milieu A_milieu IPM_milieu [iw=hhweight], by(milieu_bis)
	format H_milieu A_milieu IPM_milieu %9.2f
	export excel using "${routput}/synthese_IPM.xlsx", sheet("milieu") replace firstrow(variables)
	restore

*-----------------------------------------------------
*		2. CONTRIBUTION GLOBALE DES DIMENSIONS
*-----------------------------------------------------
	local dims edu sant condvie emploi gouvinst

	foreach d of local dims {
		gen contrib_`d' = scor_dim_`d' * hhweight if pauvre==1
	}
	gen score_total_pond = score_final * hhweight if pauvre==1

	foreach d of local dims {
		quietly summarize contrib_`d'
		scalar tot_`d' = r(sum)
	}
	summarize score_total_pond
	scalar tot_score = r(sum)

	* Pourcentages
	foreach d of local dims {
		scalar pct_`d' = (tot_`d' / tot_score) * 100
	}

	preserve
	clear

	set obs `=wordcount("`dims'")'
	gen str12 dimension=""
	gen contribution=.

	local i=1
	foreach d of local dims {
		replace dimension = "`d'" in `i'
		replace contribution = pct_`d' in `i'
		local ++i
	}

	format contribution %9.2f
	export excel using "${routput}/synthese_IPM.xlsx", sheet("contrib_globales") ///
		firstrow(variables) sheetmodify
	restore

*-----------------------------------------------------
*		3. CONTRIBUTIONS PAR MILIEU
*-----------------------------------------------------
	svyset [pw = hhweight]

	* liste des milieux et des dimensions
	levelsof milieu_bis, local(milieux)
	local dims edu sant condvie emploi gouvinst

	* --- Calcul des contributions pondérées par milieu ---*
	foreach m of local milieux {
		di "=== Calcul contributions pour milieu_bis = `m' ==="

		* créer contributions pondérées (chez les pauvres du milieu)
		foreach d of local dims {
			qui gen double contrib_`d'_`m' = scor_dim_`d' * hhweight ///
				if pauvre == 1 & milieu_bis == `m'
		}

		qui gen double score_total_pond_`m' = score_final * hhweight ///
			if pauvre == 1 & milieu_bis == `m'

		* Sommes pondérées
		foreach d of local dims {
			quietly summarize contrib_`d'_`m'
			scalar total_`d'_`m' = r(sum)
		}
		quietly summarize score_total_pond_`m'
		scalar total_score_`m' = r(sum)

		* Si total_score_`m' est manquant ou zéro, on protège la division
		foreach d of local dims {
			if missing(total_score_`m') | total_score_`m' == 0 {
				scalar contrib_`d'_`m'_pct = .
			}
			else {
				scalar contrib_`d'_`m'_pct = (total_`d'_`m' / total_score_`m') * 100
			}
		}
	}

	* --- Construire un petit fichier propre et l'exporter (postfile) ---*
	tempfile out_mil
	capture postutil clear
	postfile pf str12 dimension str15 milieu double contribution using `out_mil', replace

	foreach m of local milieux {
		local milieu_label = cond(`m'==1, "Dakar urbain", cond(`m'==2, "Autres urbain", "Rural"))
		foreach d of local dims {
			scalar val = contrib_`d'_`m'_pct
			post pf ("`d'") ("`milieu_label'") (val)
		}
	}

	postclose pf

	* ouvrir et exporter
	use `out_mil', clear
	format contribution %9.2f
	export excel using "${routput}/synthese_IPM.xlsx", sheet("contrib_mil") ///
		firstrow(variables) sheetmodify
	restore

*-------------------------------------------------------*
*   1. IPM selon la région (globale)
*-------------------------------------------------------*
	
	use "${rdata}\base_IPM_bis.dta", clear 

	svyset [pw = hhweight]

	levelsof region, local(regions)

	gen H_region = .
	gen A_region = .

	foreach reg of local regions {
		svy, subpop(if region == `reg'): mean pauvre
		scalar H_val = r(table)[1,1]
		replace H_region = H_val if region == `reg'
		scalar drop H_val

		svy, subpop(if region == `reg' & pauvre == 1): mean indiv_priv
		scalar A_val = r(table)[1,1]
		replace A_region = A_val if region == `reg'
		scalar drop A_val
	}

	gen IPM_reg = H_region * A_region

	* Sauvegarde par région
	preserve
	collapse (first) H_region A_region IPM_reg [pw = hhweight], by(region)
	format H_region A_region IPM_reg %9.2f
	export excel using "${routput}/synthese_IPM.xlsx", ///
		sheet("region") firstrow(variables) sheetmodify
	restore

*-------------------------------------------------------*
*   4. IPM selon la région et le milieu (avec Dakar spécial)
*-------------------------------------------------------*
	
	use "${rdata}\base_IPM_bis.dta", clear 

	levelsof milieu, local(milieux)
	gen H_reg_mil = .
	gen A_reg_mil = .

	foreach reg of local regions {
		foreach mil of local milieux {
			
			* Traitement spécial Dakar : pas de rural
			if `reg' == 1 {   // <-- Remplacer 1 par le code numérique de Dakar
				local mil = 1  // on ne garde que le milieu urbain
			}
			
			* Incidence H
			svy, subpop(if region == `reg' & milieu == `mil'): mean pauvre
			scalar H_val = r(table)[1,1]
			replace H_reg_mil = H_val if (region == `reg' & milieu == `mil')
			scalar drop H_val

			* Intensité A
			svy, subpop(if region == `reg' & milieu == `mil' & pauvre == 1): mean indiv_priv
			scalar A_val = r(table)[1,1]
			replace A_reg_mil = A_val if (region == `reg' & milieu == `mil')
			scalar drop A_val
		}
	}

	* IPM région x milieu
	gen IPM_reg_mil = H_reg_mil * A_reg_mil

	* Sauvegarde
	preserve
	collapse (first) H_reg_mil A_reg_mil IPM_reg_mil [pw = hhweight], by(region milieu)
	format H_reg_mil A_reg_mil IPM_reg_mil %9.2f
	export excel using "${routput}/synthese_IPM.xlsx", ///
		sheet("region_mil") firstrow(variables) sheetmodify
	restore


*------------------------------------------------------------*
* 	5.	IPM selon certaines caractéristiques du chef de ménage
*------------------------------------------------------------*

*----------------------------------------
//		IPM selon le sexe du CM
*----------------------------------------
 svyset [pweight = hhweight]
 
 * Incidence et intensité globale selon le sexe du CM
 levelsof hgender, local(sexe_cm)
 gen H_sex_nat = .
 gen A_sex_nat = .
 
 foreach sex of local sexe_cm {
 	svy, subpop(if hgender == `sex'): mean pauvre 
	scalar H_val = r(table)[1,1]
	replace H_sex_nat = H_val if hgender == `sex'
	
	svy, subpop(if hgender == `sex' & pauvre == 1): mean indiv_priv
	scalar A_val = r(table)[1,1]
	replace A_sex_nat = A_val if hgender == `sex'
 }
 
 * IPM selon le sexe du CM 
 gen IPM_sex_nat = H_sex_nat * A_sex_nat
 
 * stocker les résultats
 preserve
 collapse (mean) H_sex_nat A_sex_nat IPM_sex_nat [iw = hhweight], by(hgender)
 ds, has(type numeric)
 format `r(varlist)' %9.2f
 export excel using "${routput}/synthese_IPM.xlsx", firstrow(variables) sheet("sexe_CM") sheetmodify
 restore
 
 * Incidence et intensité globale selon le sexe du CM et le milieu
 levelsof hgender, local(sexe_cm)
 levelsof milieu, local(milieux)
 gen H_sex_mil = .
 gen A_sex_mil = .
 
 foreach sex of local sexe_cm {
 	foreach mil of local milieux {
		svy, subpop(if hgender == `sex' & milieu == `mil'): mean pauvre
		scalar H_val = r(table)[1,1]
		replace H_sex_mil = H_val if (hgender == `sex' & milieu == `mil')
		
		svy, subpop(if hgender == `sex' & milieu == `mil' & pauvre == 1): mean indiv_priv
		scalar A_val = r(table)[1,1]
		replace A_sex_mil = A_val if (hgender == `sex' & milieu == `mil')
	}
 }
 
  * IPM selon le sexe du CM et le milieu
  gen IPM_sex_mil = H_sex_mil * A_sex_mil
  
  * stocker les résultats
 preserve
 collapse (mean) H_sex_mil A_sex_mil IPM_sex_mil [iw = hhweight], by(milieu hgender)
 ds, has(type numeric)
 format `r(varlist)' %9.2f
 export excel using "${routput}/synthese_IPM.xlsx", firstrow(variables) sheet("sexe_CM_mil") sheetmodify
 restore
 
*----------------------------------------
 // IPM selon le groupe d'âge du CM
*----------------------------------------
 
 * Définition des groupes d'âge
 gen     groupe_age = cond(hage > 0 & hage < 35, 1,0)
 replace groupe_age = cond(groupe_age == 0 & hage <= 60,2, groupe_age)
 replace groupe_age = cond(groupe_age == 0, 3, groupe_age)
 
 label define groupe_age_label 1 "Moins de 35 ans" ///
							   2 "35 - 60 ans" 	   ///
							   3 "Plus de 60 ans"
 label values groupe_age groupe_age_label
 
 svyset [pweight = hhweight]
 
 * Incidence et intensité globale selon le groupe d'âge du CM
 levelsof groupe_age, local(age_cm)
 gen H_age_nat = .
 gen A_age_nat = .
 
 foreach age of local age_cm {
 	svy, subpop(if groupe_age == `age'): mean pauvre 
	scalar H_val = r(table)[1,1]
	replace H_age_nat = H_val if groupe_age == `age'
	
	svy, subpop(if groupe_age == `age' & pauvre == 1): mean indiv_priv
	scalar A_val = r(table)[1,1]
	replace A_age_nat = A_val if groupe_age == `age'
 }
 
 * IPM selon le groupe d'âge du CM 
 gen IPM_age_nat = H_age_nat * A_age_nat

 
 * stocker les résultats
 preserve
 collapse (mean) H_age_nat A_age_nat IPM_age_nat [iw = hhweight], by(groupe_age)
 ds, has(type numeric)
 format `r(varlist)' %9.2f
 export excel using "${routput}/synthese_IPM.xlsx", firstrow(variables) sheet("age_CM") sheetmodify
 restore
 
 * Incidence et intensité globale selon le groupe d'âge du CM et le milieu
 levelsof groupe_age, local(age_cm)
 levelsof milieu, local(milieux)
 gen H_age_mil = .
 gen A_age_mil = .
 
 foreach age of local age_cm {
 	foreach mil of local milieux {
		svy, subpop(if groupe_age == `age' & milieu == `mil'): mean pauvre
		scalar H_val = r(table)[1,1]
		replace H_age_mil = H_val if (groupe_age == `age' & milieu == `mil')
		
		svy, subpop(if groupe_age == `age' & milieu == `mil' & pauvre == 1): mean indiv_priv
		scalar A_val = r(table)[1,1]
		replace A_age_mil = A_val if (groupe_age == `age' & milieu == `mil')
	}
 }
 
  * IPM selon le groupe d'âge du CM et le milieu
  gen IPM_age_mil = H_age_mil * A_age_mil
  
  * stocker les résultats
 preserve
 collapse (mean) H_age_mil A_age_mil IPM_age_mil [iw = hhweight], by(milieu groupe_age)
 ds, has(type numeric)
 format `r(varlist)' %9.2f
 export excel using "${routput}/synthese_IPM.xlsx", firstrow(variables) sheet("age_CM_mil") sheetmodify
 restore
 
 
*------------------------------------------
 // IPM selon le statut matrimonial du CM
*------------------------------------------
 svyset [pweight = hhweight]
 
 * Incidence et intensité globale selon le statut matrimonial du CM
 levelsof hmstat, local(statut_cm)
 gen H_statut_nat = .
 gen A_statut_nat = .
 
 foreach statut of local statut_cm {
 	svy, subpop(if hmstat == `statut'): mean pauvre 
	scalar H_val = r(table)[1,1]
	replace H_statut_nat = H_val if hmstat == `statut'
	
	count if hmstat == `statut' & pauvre == 1
	if r(N) > 0 {
		svy, subpop(if hmstat == `statut' & pauvre == 1): mean indiv_priv
	    scalar A_val = r(table)[1,1]
	    replace A_statut_nat = A_val if hmstat == `statut'
	}
	else {
            di as error "Pas de données valides pour A avec hmstat = `statut' !!!"
    }
	
 }
 
 * IPM selon le statut matrimonial du CM 
 gen IPM_statut_nat = H_statut_nat * A_statut_nat
 
 * stocker les résultats
 preserve
 collapse (mean) H_statut_nat A_statut_nat IPM_statut_nat [iw = hhweight], by(hmstat)
 ds, has(type numeric)
 format `r(varlist)' %9.2f
 export excel using "${routput}/synthese_IPM.xlsx", firstrow(variables) sheet("statut_CM") sheetmodify
 restore
 
 * Incidence et intensité globale selon le statut du CM et le milieu
 levelsof hmstat, local(statut_cm)
 levelsof milieu, local(milieux)
 gen H_statut_mil = .
 gen A_statut_mil = .
 
 foreach statut of local statut_cm {
 	foreach mil of local milieux {
		count if hmstat == `statut' & milieu == `mil'
		if r(N) > 0 {
			svy, subpop(if hmstat == `statut' & milieu == `mil'): mean pauvre
		    scalar H_val = r(table)[1,1]
		    replace H_statut_mil = H_val if (hmstat == `statut' & milieu == `mil')
		}
		else {
            di as error "Pas de données valides pour H avec hmstat = `statut' & milieu = `mil' !!!"
       }
		
		count if hmstat == `statut' & milieu == `mil' & pauvre == 1
		if r(N) > 0 {
			svy, subpop(if hmstat == `statut' & milieu == `mil' & pauvre == 1): mean indiv_priv
		    scalar A_val = r(table)[1,1]
		    replace A_statut_mil = A_val if (hmstat == `statut' & milieu == `mil')
		}
		else {
            di as error "Pas de données valides pour A avec hmstat = `statut' & milieu = `mil' !!!"
       }
		
	}
 } 
  * IPM selon le statut du CM et le milieu
  gen IPM_statut_mil = H_statut_mil * A_statut_mil
  
  * stocker les résultats
 preserve
 collapse (mean) H_statut_mil A_statut_mil IPM_statut_mil [iw = hhweight], by(hmstat milieu)
 ds, has(type numeric)
 format `r(varlist)' %9.2f
 export excel using "${routput}/synthese_IPM.xlsx", firstrow(variables) sheet("statut_CM_mil") sheetmodify
 restore
 
 
 *-------------------------------------------
 // IPM selon le niveau d'instruction du CM
 *-------------------------------------------
 
 * Redéfinir les niveaux d'instruction
 gen niv_ins = .
 replace niv_ins = cond(heduc == 1,1,niv_ins)
 replace niv_ins = cond(inlist(heduc, 2, 3),2,niv_ins)
 replace niv_ins = cond(inlist(heduc, 4, 5, 6, 7), 3, niv_ins)
 replace niv_ins = cond(heduc == 8,4,niv_ins)
 replace niv_ins = cond(heduc == 9,5,niv_ins)

 label define niv_instruction 1"Aucun" 2"Primaire" 3"Secondaire" 4"Post-secondaire" 5"Supérieur"
 label values niv_ins niv_instruction
 
  svyset [pweight = hhweight]
 
 * Incidence et intensité globale selon le niveau d'éducation du CM
 levelsof niv_ins, local(educ_cm)
 gen H_educ_nat = .
 gen A_educ_nat = .
 
 foreach niv of local educ_cm {
 	svy, subpop(if niv_ins == `niv'): mean pauvre 
	scalar H_val = r(table)[1,1]
	replace H_educ_nat = H_val if niv_ins == `niv'
	
	svy, subpop(if niv_ins == `niv' & pauvre == 1): mean indiv_priv
	scalar A_val = r(table)[1,1]
	replace A_educ_nat = A_val if niv_ins == `niv'
 }
 
 * IPM selon le niveau d'éducation du CM 
 gen IPM_educ_nat = H_educ_nat * A_educ_nat
 
 * stocker les résultats
 preserve
 collapse (mean) H_educ_nat A_educ_nat IPM_educ_nat [iw = hhweight], by(niv_ins)
 ds, has(type numeric)
 format `r(varlist)' %9.2f
 export excel using "${routput}/synthese_IPM.xlsx", firstrow(variables) sheet("educ_CM") sheetmodify
 restore
 
 * Incidence et intensité globale selon le niveau d'éducation du CM et le milieu
 levelsof niv_ins, local(educ_cm)
 levelsof milieu, local(milieux)
 gen H_educ_mil = .
 gen A_educ_mil = .
 
 foreach niv of local educ_cm {
 	foreach mil of local milieux {
		svy, subpop(if niv_ins == `niv' & milieu == `mil'): mean pauvre
		scalar H_val = r(table)[1,1]
		replace H_educ_mil = H_val if (niv_ins == `niv' & milieu == `mil')
		
		svy, subpop(if niv_ins == `niv' & milieu == `mil' & pauvre == 1): mean indiv_priv
		scalar A_val = r(table)[1,1]
		replace A_educ_mil = A_val if (niv_ins == `niv' & milieu == `mil')
	}
 }
 
  * IPM selon le niveau d'éducation du CM et le milieu
  gen IPM_educ_mil = H_educ_mil * A_educ_mil
  
  * stocker les résultats
 preserve
 collapse (mean) H_educ_mil A_educ_mil IPM_educ_mil [iw = hhweight], by(milieu niv_ins)
 ds, has(type numeric)
 format `r(varlist)' %9.2f
 export excel using "${routput}/synthese_IPM.xlsx", firstrow(variables) sheet("educ_CM_mil") sheetmodify
 restore
 
 
*-----------------------------------------
//		IPM selon l'occupation du CM
*-----------------------------------------
 svyset [pweight = hhweight]
 
 * Incidence et intensité globale selon l'occupation du CM
 levelsof hactiv7j if hactiv7j != 6, local(occ_cm)
 gen H_occ_nat = .
 gen A_occ_nat = .
 
 foreach niv of local occ_cm {
 	svy, subpop(if hactiv7j == `niv'): mean pauvre 
	scalar H_val = r(table)[1,1]
	replace H_occ_nat = H_val if hactiv7j == `niv'
	
	svy, subpop(if hactiv7j == `niv' & pauvre == 1): mean indiv_priv
	scalar A_val = r(table)[1,1]
	replace A_occ_nat = A_val if hactiv7j == `niv'
 }
 
 * IPM selon l'occupation du CM 
 gen IPM_occ_nat = H_occ_nat * A_occ_nat
 
 * stocker les résultats
 preserve
 collapse (mean) H_occ_nat A_occ_nat IPM_occ_nat [iw = hhweight] if hactiv7j != 6, by(hactiv7j)
 ds, has(type numeric)
 format `r(varlist)' %9.2f
 export excel using "${routput}/synthese_IPM.xlsx", firstrow(variables) sheet("occ_CM") sheetmodify
 restore
 
 * Incidence et intensité globale selon l'occupation du CM et le milieu
 levelsof hactiv7j if hactiv7j != 6, local(occ_cm)
 levelsof milieu, local(milieux)
 gen H_occ_mil = .
 gen A_occ_mil = .

 foreach niv of local occ_cm {
 	foreach mil of local milieux {
		svy, subpop(if hactiv7j == `niv' & milieu == `mil'): mean pauvre
		scalar H_val = r(table)[1,1]
		replace H_occ_mil = H_val if (hactiv7j == `niv' & milieu == `mil')
		
		svy, subpop(if hactiv7j == `niv' & milieu == `mil' & pauvre == 1): mean indiv_priv
		scalar A_val = r(table)[1,1]
		replace A_occ_mil = A_val if (hactiv7j == `niv' & milieu == `mil')
	}
 }
 
  * IPM selon l'occupation du CM et le milieu
  gen IPM_occ_mil = H_occ_mil * A_occ_mil

  * stocker les résultats
 preserve
 collapse (mean) H_occ_mil A_occ_mil IPM_occ_mil [iw = hhweight] if hactiv7j != 6, by(milieu hactiv7j)
 ds, has(type numeric)
 format `r(varlist)' %9.2f
 export excel using "${routput}/synthese_IPM.xlsx", firstrow(variables) sheet("occ_CM_mil") sheetmodify
 restore
