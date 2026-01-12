*-------------------------------------------------------*
* 	 			Variables auxiliaires 
*-------------------------------------------------------*


*	 			Conversion des bases
*-------------------------------------------------------*

	cd "E:\Nouveau_dossier\dixieme_recensement"

	*import spss using "dixieme_RGPH_5_indiv_SECTION_B.sav"
	*save "RGPH_5_indiv_SB.dta", replace

	*import spss using "dixieme_RGPH_5_habitat_SECTION_E.sav"
	*save "RGPH_5_habitat_SE.dta", replace

*-------------------------------------------------------*
*	 			Variables de la section B
*-------------------------------------------------------*
	use "RGPH_5_indiv_SB.dta", clear 

	* Définition du plan de sondage
	svyset [pweight = POIDS_STRATE_P]


/*		 	1 : TAUX D'ALPHABÉTISATION (B34)
-------------------------------------------------------*/	
	notes : Pourcentage de personnes âgées de 15 ans et plus sachant lire /// 
	et écrire dans au moins une langue (codes 1-24 dans B34).

*	1. variable alpha  
	
	gen alpha = (B34_FR == 1)
	*gen alpha_plus15  = (B34_FR == 1) if B08>=15
	*gen alpha_moins15 = (B34_FR == 1) if B08<15
	
*	2. Pourcentage par département 
	
	preserve
		keep if B08 >= 15

		levelsof A02, local(depts)
		gen alpha_dept = .

		foreach d of local depts {
			svy, subpop(if A02 == "`d'"): mean alpha
			scalar val = r(table)[1,1]
			replace alpha_dept = val if A02 == "`d'"
			scalar drop val
		}

		collapse (first) alpha_dept, by(A02)
		gen alpha_pct = alpha_dept*100
		format alpha_dept alpha_pct %9.2f

		export excel using "C:\\Users\\LENOVO\\Desktop\\ECOLE\\ENSAE\\MEMOIRE\\Rapport_de_stage\\Small area\\auxiliaires.xlsx", ///
			sheet("Alpha") firstrow(variables) replace
	restore

	
/*		 	2 : TAUX D'EMPLOI (B36)
-------------------------------------------------------*/	
	notes : Pourcentage de personnes âgées de 15 à 64 ans déclarant être ///
			occupées (B36 = 1) parmi la population en âge de travailler.
	
	preserve 
	* Restriction âge actif
	keep if B08 >= 15 & B08 <= 64

	* Variable occupé
	gen occupe = (B36==1)

	* Liste des départements
	levelsof A02, local(depts)

	gen taux_emploi = .

	foreach d of local depts {
		svy, subpop(if A02=="`d'"): mean occupe
		scalar e_val = r(table)[1,1]
		replace taux_emploi = e_val if A02=="`d'"
		scalar drop e_val
	}

	collapse (first) taux_emploi [pw=POIDS_STRATE_P], by(A02)
	gen taux_emploi_pct = taux_emploi * 100
	format taux_emploi taux_emploi_pct %9.2f

	export excel using "C:\\Users\\LENOVO\\Desktop\\ECOLE\\ENSAE\\MEMOIRE\\Rapport_de_stage\\Small area\\auxiliaires.xlsx", ///
		sheet("taux_emploi") firstrow(variables) sheetmodify

	restore
	
/*		 	3: RATIO DE DÉPENDANCE ÉCONOMIQUE (B36)
-------------------------------------------------------*/	
	notes : Ratio = nombre de personnes inactives (B36 = 4-9) ///
	nombre de personnes actives (B36 = 1-3) dans la population de 15 ans et plus.

	preserve
	
	* Limite d'âge
	keep if B08 >= 15

	* Variables actifs / inactifs
	gen actif = inlist(B36, 1, 2, 3)
	gen inactif = inlist(B36, 4, 5, 6, 7, 8, 9)

	* Liste des départements
	levelsof A02, local(depts)

	* Création des variables de sortie
	gen ratio_dep = .
	foreach d of local depts {

		* Moyenne pondérée des actifs
		svy, subpop(if A02=="`d'"): mean actif
		scalar m_actif = r(table)[1,1]

		* Moyenne pondérée des inactifs
		svy, subpop(if A02=="`d'"): mean inactif
		scalar m_inactif = r(table)[1,1]

		* Ratio = inactifs / actifs
		replace ratio_dep = m_inactif / m_actif if A02=="`d'"
		scalar drop m_actif m_inactif
	}
	
	collapse (first) ratio_dep [pw=POIDS_STRATE_P], by(A02)
	format ratio_dep %9.3f

	* Export dans la feuille dédiée
	export excel using "C:\\Users\\LENOVO\\Desktop\\ECOLE\\ENSAE\\MEMOIRE\\Rapport_de_stage\\Small area\\auxiliaires.xlsx", ///
		sheet("ratio_dependance") firstrow(variables) sheetmodify

	restore



/*		 	4 : TAUX DE HANDICAP GLOBAL (B21-B26)
-------------------------------------------------------*/	
	notes : Pourcentage de personnes déclarant avoir au moins une /// 
			difficulté fonctionnelle sévère (codes 2-3 : "beaucoup de difficultés" ///
			ou "pas du tout capable") dans au moins un des 6 domaines ///
			: vue, audition, mobilité, cognition, soins personnels, communication.


	* Construction du handicap sévère ou total
	gen handicap_severe = (B21>=2 | B22>=2 | B23>=2 | B24>=2 | B25>=2 | B26>=2)

	* Liste des départements
	levelsof A02, local(depts)

	gen handicap_global = .

	foreach d of local depts {
		svy, subpop(if A02=="`d'"): mean handicap_severe
		scalar h_val = r(table)[1,1]
		replace handicap_global = h_val if A02=="`d'"
		scalar drop h_val
	}

	preserve

	collapse (first) handicap_global [pw=POIDS_STRATE_P], by(A02)
	gen handicap_pct = handicap_global * 100
	format handicap_global handicap_pct %9.2f

	export excel using "C:\\Users\\LENOVO\\Desktop\\ECOLE\\ENSAE\\MEMOIRE\\Rapport_de_stage\\Small area\\auxiliaires.xlsx", ///
		sheet("handicap") firstrow(variables) sheetmodify

	restore

	

*-------------------------------------------------------*
*	 			Variables de la section E
*-------------------------------------------------------*
	use "RGPH_5_habitat_SB.dta", clear
*-------------------------------------------------------*
*        Nettoyage et préparation
*-------------------------------------------------------*

svyset [pw = POIDS_STRATE_P]


*-------------------------------------------------------*
* 1. ACCÈS ÉLECTRICITÉ (E11)
*-------------------------------------------------------*
	svyset [pw = POIDS_STRATE_P]

	* 1 = accès, 0 = privation
	gen elec = inlist(E11,1,2,3,5)

	levelsof A02, local(depts)
	gen elec_dep = .

	foreach d of local depts {
		svy, subpop(if A02=="`d'"): mean elec
		scalar val = r(table)[1,1]
		replace elec_dep = val if A02=="`d'"
		scalar drop val
	}

	preserve
	collapse (first) elec_dep [pw=POIDS_STRATE_P], by(A02)
	gen elec_pct = elec_dep*100
	format elec_dep elec_pct %9.2f

	export excel using "C:\\Users\\LENOVO\\Desktop\\ECOLE\\ENSAE\\MEMOIRE\\Rapport_de_stage\\Small area\\auxiliaires.xlsx", ///
		sheet("Electricite") firstrow(variables) sheetmodify
	restore


*-------------------------------------------------------*
* 2. ACCÈS EAU POTABLE (E09)
*-------------------------------------------------------*
	svyset [pw = POIDS_STRATE_P]

	gen eau = inlist(E09,1,2,3,4)

	levelsof A02, local(depts)
	gen eau_dep = .

	foreach d of local depts {
		svy, subpop(if A02=="`d'"): mean eau
		scalar val = r(table)[1,1]
		replace eau_dep = val if A02=="`d'"
		scalar drop val
	}

	preserve
	collapse (first) eau_dep [pw=POIDS_STRATE_P], by(A02)
	gen eau_pct = eau_dep*100
	format eau_dep eau_pct %9.2f

	export excel using "C:\\Users\\LENOVO\\Desktop\\ECOLE\\ENSAE\\MEMOIRE\\Rapport_de_stage\\Small area\\auxiliaires.xlsx", ///
		sheet("Eau") firstrow(variables) sheetmodify
	restore

*-------------------------------------------------------*
* 3. TOILETTES AMÉLIORÉES (E08A)
*-------------------------------------------------------*
	svyset [pw = POIDS_STRATE_P]

	gen toilette = inlist(E08A,11,12,23)

	levelsof A02, local(depts)
	gen toilette_dep = .

	foreach d of local depts {
		svy, subpop(if A02=="`d'"): mean toilette
		scalar val = r(table)[1,1]
		replace toilette_dep = val if A02=="`d'"
		scalar drop val
	}

	preserve
	collapse (first) toilette_dep [pw=POIDS_STRATE_P], by(A02)
	gen toilette_pct = toilette_dep*100
	format toilette_dep toilette_pct %9.2f

	export excel using "C:\\Users\\LENOVO\\Desktop\\ECOLE\\ENSAE\\MEMOIRE\\Rapport_de_stage\\Small area\\auxiliaires.xlsx", ///
		sheet("Toilettes") firstrow(variables) sheetmodify
	restore


*-------------------------------------------------------*
* 4. LOGEMENT DUR (E01)
*-------------------------------------------------------*
	svyset [pw = POIDS_STRATE_P]

	gen logt = inlist(E01,30,41,42,43,44,50)

	levelsof A02, local(depts)
	gen logt_dep = .

	foreach d of local depts {
		svy, subpop(if A02=="`d'"): mean logt
		scalar val = r(table)[1,1]
		replace logt_dep = val if A02=="`d'"
		scalar drop val
	}

	preserve
	collapse (first) logt_dep [pw=POIDS_STRATE_P], by(A02)
	gen logt_pct = logt_dep*100
	format logt_dep logt_pct %9.2f

	export excel using "C:\\Users\\LENOVO\\Desktop\\ECOLE\\ENSAE\\MEMOIRE\\Rapport_de_stage\\Small area\\auxiliaires.xlsx", ///
		sheet("Logement") firstrow(variables) sheetmodify
	restore


*-------------------------------------------------------*
* 5. INDICE D'ÉQUIPEMENT (E13_1 à E13_24)
*-------------------------------------------------------*
	svyset [pw = POIDS_STRATE_P]

	egen nb_equip = rowtotal(E13_1 E13_2 E13_3 E13_4 E13_5 E13_6 E13_7 E13_8 ///
							 E13_9 E13_10 E13_11 E13_12 E13_13 E13_14 ///
							 E13_15 E13_16 E13_17 E13_18 E13_19 E13_20 ///
							 E13_21 E13_22 E13_23 E13_24)

	levelsof A02, local(depts)
	gen equip_dep = .

	foreach d of local depts {
		svy, subpop(if A02=="`d'"): mean nb_equip
		scalar val = r(table)[1,1]
		replace equip_dep = val if A02=="`d'"
		scalar drop val
	}

	preserve
	collapse (first) equip_dep [pw=POIDS_STRATE_P], by(A02)
	format equip_dep %9.2f

	export excel using "C:\\Users\\LENOVO\\Desktop\\ECOLE\\ENSAE\\MEMOIRE\\Rapport_de_stage\\Small area\\auxiliaires.xlsx", ///
		sheet("Equipement") firstrow(variables) sheetmodify
	restore

	
*   	10. INSÉCURITÉ ALIMENTAIRE PAR DÉPARTEMENT
*-------------------------------------------------------*

	* Déclaration du poids
	svyset [pw = POIDS_STRATE_P]

	* Création de la variable indicatrice
	* 1 si le ménage a sauté au moins un repas (E18 = 1 ou E19 = 1), 0 sinon
	gen insa_alim = (E18==1 | E19==1)

	* Liste des départements
	levelsof A02, local(depts)

	* Variable pour stocker le résultat par département
	gen insa_alim_dep = .

	foreach d of local depts {
		svy, subpop(if A02=="`d'"): mean insa_alim
		scalar val = r(table)[1,1]
		replace insa_alim_dep = val if A02=="`d'"
		scalar drop val
	}

	preserve

	* Agrégation par département
	collapse (first) insa_alim_dep [pw=POIDS_STRATE_P], by(A02)

	* Conversion en pourcentage
	gen insa_alim_pct = insa_alim_dep*100
	format insa_alim_dep insa_alim_pct %9.2f

	* Export Excel dans la feuille dédiée
	export excel using "C:\\Users\\LENOVO\\Desktop\\ECOLE\\ENSAE\\MEMOIRE\\Rapport_de_stage\\Small area\\auxiliaires.xlsx", ///
		sheet("Insecurite_alimentaire") firstrow(variables) sheetmodify

	restore