
/******************************************************************************
                                                                              
                ███████╗███╗   ██╗███████╗ █████╗ ███████╗                    
                ██╔════╝████╗  ██║██╔════╝██╔══██╗██╔════╝                    
                ████╗   ██╔██╗ ██║███████╗███████║█████╗                      
                ██╔═╝   ██║╚██╗██║╚════██║██╔══██║██╔══╝                      
                ███████╗██║ ╚████║███████║██║  ██║███████╗                    
                ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝                    
	 	École nationale de la Statistique et de l'Analyse économique 
							Pierre NDIAYE
	_______________________________________________________________________
			✦✦				Rapport de stage : 				✦✦
						   -------------------
		
		Mesure de la pauvreté multidimensionnelle au niveau départemental 
								par EPD
	______________________________________________________________________
   	                 	
						Auteur : Aïssatou Gueye                        
              Analyste Statisticienne en troisième année  
							  ENSAE Dakar 
*/
******************************************************************************

//_____________________________________________________________________________
// 				 Préparation de l'environnement de travail 
//_____________________________________________________________________________
	notes : Cette base de données est issue de l'enquête EHCVM 
	**** Vider la mémoire 
	clear all
	**** Définir le point comme séparateur de milliers
	set dp comma
	**** Demander à stata d'afficher les résultats complets (long tableau)
	set more off

	***** Définir et fixer les répertoires de travail 		
	global repertoire ="C:\Users\LENOVO\Desktop\ECOLE\ENSAE\MEMOIRE\Rapport de stage\IPM\Bases EHCVM\Bases"
	global repert="https://raw.githubusercontent.com/Aissatou150/Rapport/main/"
	
	
*______________________________________________________________________________
* 			 	Identification des varibales d'intérets
*______________________________________________________________________________
/*
Dans cette partie, nous allons identifier les variables qui ont été retenues
 pour le calcul de l'IPM 

 les bases qui seront utilisées : 
	ehcvm_individu_SEN2021 : a
	 ehcvm_welfare_SEN2021 : b
			s01_me_SEN2021 : 1
	        s03_me_SEN2021 : 3
		   s04a_me_SEN2020 : 4
			s11_me_SEN2019 : 11
		 s20b_1_me_SEN2021 : 20b
		   s20c_me_SEN2021 : 20c
		   
--------------------------------------------------------------------------------
  Dimensions         Indicateurs 							seuils 
 ------------	  ------------------				------------------------
  Éducation		Fréquentation scolaire			Le ménage a un enfant de 6-16ans
												qui ne fréquente actuellement 
												pas l'école	___a
												
				Retard scolaire					Le ménage a un enfant de 8-13ans			
												ayant un retard scolaire de 2ans
												ou plus	___a
												
				Nombre d'années de scolarité	Aucun membre du ménage âgé de 15
												ans ou plus n'a complété 6 années
												d'études___a
												
				Alphabétisation					Le quart des membres du ménage 
												de 15 ans ou plus ne sait pas 
												lire ou écrire ___a
--------------------------------------------------------------------------------
	 Santé		Couverture maladie				Plus du tiers des membres du 
												ménage ne disposent d'aucune 
												forme d'assurance maladie   /a
												
				Qualité des services de santé	Un membre du ménage apprécie 
												négativement au moins 5 critères
												sur 6	___3
												
				Maladies et problèmes de santé	Un membre du ménage souffre d'une
												maladie chronique (tension ou diabète)_3
												
				Vaccination des enfants 		de 0-6 ans	Un enfant de 0-6 ans
				
												du ménage n'a pas été vacciné 
												lors de la campagne passée___3
												
				Handicap physique et mental		Un membre souffre d'un handicap 
												physique/mental l'empêchant 
												d'exercer une activité ou d'aller
												à l'école___3
--------------------------------------------------------------------------------
				Type de logement				Le ménage est privé si le 
												logement est une case, baraque 
												ou « autre » ___11
												
				Électricité						La source d'éclairage du ménage 
												n'est pas : électricité, groupe 
												électrogène ou solaire	___11
												
				Évacuation des eaux usées		Le ménage est privé si l'évacuation 
Conditions										se fait dans la cour ou dans la
	de vie										rue/nature	___11
												
				Indice de surpeuplement			Le ménage est privé si le 
												logement est surpeuplé (plus de 
												3 personnes par pièce)  ___b
												
				Eau potable						Le ménage n'a pas accès à l'eau 
												potable	"s11_me_SEN2021"
												
				Énergie de cuisson				Le ménage n'utilise pas d'énergie
												propre pour la cuisson 
												(électricité et gaz) ___b
												
				Équipements sanitaires			Le ménage ne dispose pas de 
												toilettes privées améliorées___11
												
				Biens d'équipement				Le ménage dispose de moins de 2 
												équipements (ventilateur, TV, 
												ordinateur, cuisinière, réfrigérateur, 
												bicyclette, motocyclette) et ne 
												dispose ni de voiture, camion, 
												machine à laver ni de groupe électrogène ___3
--------------------------------------------------------------------------------			
	Emploi		Dépendance économique			Le taux de dépendance est 
												supérieur à 2	 ______1 , 4
												
				Travail des enfants				Le ménage est privé s'il y a un 
												enfant de moins de 15 ans 
												exerçant un travail	______1 , 4
				Chômage 						Le nombre de chômeurs est 
												supérieur à la moitié des
												actifs du ménage
												
				Sous-emploi 					Le nombre de travailleurs sous-employés
												est supérieur au tiers des occupés du ménage
												
				Protection sociale 				Le nombre de travailleurs n'ayant
												pas de protection est supérieur 
												à la moitié des occupés du ménage
--------------------------------------------------------------------------------
					Corruption					Le ménage a été victime d'un 
												racket dans un service public___20b
	Gouvernance 
et institutions		Agression et vol			Un membre est victime d'agression
												ou de vol à domicile ou dans la
												rue	___20c
--------------------------------------------------------------------------------
*/	

*_____________________________________________________________________________
*   Création de la matrice des score de  bien être ou d'accomplissements
*_____________________________________________________________________________
/*
------------------------------------------------------------------------------
						  Dimension Education 
----------------------------------------------------------------------------*/
			use "${repert}/ehcvm_individu_SEN2021.dta", clear

*					   	 Indicateur Alphabétisation
*						-----------------------------
lab var alfa "Alphabétisation des individus"
rename alfa alphabetisation

* 					  Indicateur Fréquentation scolaire
* 					 -----------------------------------
capture drop frequentation
clonevar frequentation = educ_hi
lab var frequentation "Niveau d'éducation"

/* 						  Indicateur Retard scolaire
						-----------------------------
Au Sénégal, l'âge pour chaque niveau d'étude est le suivant : 
Préscolaire: 3 à 5 ans.
Enseignement primaire: 6 à 11 ans.
Enseignement secondaire 1 : 12 à 15 ans.
Enseignement secondaire 2 : 16 à 18 ans.
Enseignement supérieur: À partir de 19 ans. 
*/
gen retard =.
replace retard=1 if educ_scol==1 & age > 5
replace retard=2 if educ_scol==2  & age  > 11
replace retard=3 if (educ_scol==3  |educ_scol==4) & age > 15
replace retard=4 if (educ_scol==5 |educ_scol==6)  & age > 18
replace retard=0 if missing(retard)
*---
label values retard retard
label variable retard "Retard Scolaire"
label define retard 1 "retard préscolaire" 2 "retard primaire" 3"retard secondaire 1" 4 "retard secondaire 2" 0 "Autres"

*					 Indicateur Nombre d'années de scolarité 
*					-----------------------------------------
gen annee_scolaire=.
replace annee_scolaire=  6 if (educ_scol==4|educ_scol==5)
replace annee_scolaire= 10 if (educ_scol==6|educ_scol==7)
replace annee_scolaire= 13 if  educ_scol==8
replace annee_scolaire= 15 if  educ_scol==9
replace annee_scolaire=  0 if  missing(annee_scolaire)

label values annee_scolaire annee_scolairelbl
label variable annee_scolaire "Nombre d'années scolaires"
label define annee_scolaire 6 "Au moins 6 ans" 10 "Au moins 10 ans" 13 "Au moins 13 ans" 4 "Au moins 15 ans" 0 "Non concerné"

	keep hhid age alphabetisation frequentation retard annee_scolaire
	save "data\d_education.dta", replace	

/* 	
--------------------------------------------------------------------------------
								Dimension Santé 
-------------------------------------------------------------------------------*/
			use "${repert}/s03_me_SEN2021.dta", clear
*_____________________________________________________________________________
*			         Création identifiant unique du ménage
* ____________________________________________________________________________ 
	tostring menage, gen(menage_)
	tostring grappe, gen(grappe_)
	gen hhid1 = cond(strlen(menage_) == 1, grappe_ + "0" + menage_, grappe_ + menage_)
	destring hhid1, gen(hhid)
	drop hhid1 grappe_ menage_
* ____________________________________________________________________________ 

*			 		Indicateur Qualité des services de santé
*				   ------------------------------------------
local var  s03q10__1 s03q10__2 s03q10__3 s03q10__4 s03q10__5 s03q10__6 s03q10__8
 foreach i in `var'{
	replace `i'=0 if missing(`i')
}

local var  s03q10__1 s03q10__2 s03q10__3 s03q10__4 s03q10__5 s03q10__6 s03q10__8
 foreach i in `var'{
	replace `i'=0 if `i'==2 
}
gen nb_crit_sante =  s03q10__1 + s03q10__2 + s03q10__3 + s03q10__4 + s03q10__5 + s03q10__6 + s03q10__8 

label values nb_crit_sante nb_crit_sante_lbl
lab var  nb_crit_sante "Score d'appréciations des services de santé"

*		 		   Indicateur Maladies et problèmes de santé
*		          -------------------------------------------
replace s03q02 = 0 if s03q01==2
label define s03q02 1 "Fièvre/Paludisme" 2 "Diarrhée" 3 "Accident/Blessure" 4 "Problème dentaire" 5 "Problème de peau" 6 "Maladie des yeux" 7 "Problème de tension" 8 "Fièvre typhoïde" 9 "Problème d'estomac (ulcère, cancer, etc)" 10 "Mal de gorge" 11 "Toux, rhume " 12 "Diabète" 13 "Meningite" 14 "COVID-19" 15 "Complications liées à grossesse ou à l'accouchement" 16 "Douleurs/fatigue" 17 "Anémie/drépanocytose" 18 "Autre" 19 "Maux de ventre" 20 "Probleme respiratoire" 0 "Aucune maladie", replace

clonevar maladie12m = s03q02
lab var maladie12m "Principal problème de sante de l'individu 12 DM"

replace s03q21 = 0 if s03q19==2
label define s03q02 1 "Fièvre/Paludisme" 2 "Diarrhée" 3 "Accident/Blessure" 4 "Problème dentaire" 5 "Problème de peau" 6 "Maladie des yeux" 7 "Problème de tension" 8 "Fièvre typhoïde" 9 "Problème d'estomac (ulcère, cancer, etc)" 10 "Mal de gorge" 11 "Toux, rhume " 12 "Diabète" 13 "Meningite" 14 "COVID-19" 15 "Complications liées à grossesse ou à l'accouchement" 16 "Douleurs/fatigue" 17 "Anémie/drépanocytose" 18 "Autre" 19 "Maux de ventre" 20 "Probleme respiratoire" 0 "Aucune maladie", replace

clonevar maladie30j = s03q21
lab var maladie30j "Principal problème de sante de l'individu 30 DJ"

gen maladie_chronq = s03q21

replace maladie_chronq = cond((maladie_chronq !=12 & maladie_chronq!=7) & (s03q02==12 | s03q02==7), s03q02, maladie_chronq)

label values maladie_chronq maladie_chronqlbl
label define maladie_chronqlbl 1 "Fièvre/Paludisme" 2 "Diarrhée" 3 "Accident/Blessure" 4 "Problème dentaire" 5 "Problème de peau" 6 "Maladie des yeux" 7 "Problème de tension" 8 "Fièvre typhoïde" 9 "Problème d'estomac (ulcère, cancer, etc)" 10 "Mal de gorge" 11 "Toux, rhume " 12 "Diabète" 13 "Meningite" 14 "COVID-19" 15 "Complications liées à grossesse ou à l'accouchement" 16 "Douleurs/fatigue" 17 "Anémie/drépanocytose" 18 "Autre" 19 "Maux de ventre" 20 "Probleme respiratoire" 0 "Aucune maladie", replace

lab var maladie_chronq "Principal problème de sante de l'individu 30 DJ / focus MC"


*			 	 	  Indicateur Vaccination des enfants
*			         ------------------------------------
clonevar vaccination_enfant = s03q52
replace vaccination_enfant=	0 if vaccination_enfant==2 | missing(vaccination_enfant)
label define vaccination_enfant 1 "Oui" 0 "Non"
label values vaccination_enfant vaccination_enfant
lab var vaccination_enfant "Est ce que l'enfant à pris tous ses vaccins obligatoires"

*			___________________________________________________________
keep hhid nb_crit_sante maladie_chronq vaccination_enfant
save "data\d_sante1.dta", replace

*				 		Indicateur Couverture maladie	
*					   -------------------------------
use  "data\d_sante1.dta", clear 
merge m:m hhid using "${repert}ehcvm_individu_SEN2021.dta", keepusing(hhweight couvmal handit) nogen

egen nb_couvmal= total(couvmal), by(hhid)
label values nb_couvmal nb_couvmal_lbl
label variable nb_couvmal "Nombre d'individus bénéficiant d'une couverture maladie"
drop couvmal

*				    Indicateur Handicap physique et mental
*			      ------------------------------------------
rename handit handicap

save "data\d_sante.dta", replace 


/* 	
--------------------------------------------------------------------------------
					    	Dimension Conditions de vie 
-------------------------------------------------------------------------------*/
			use "${repert}s11_me_SEN2021.dta", clear
*_____________________________________________________________________________
*			         Création identifiant unique du ménage
* ____________________________________________________________________________ 
	tostring menage, gen(menage_)
	tostring grappe, gen(grappe_)
	gen hhid1 = cond(strlen(menage_) == 1, grappe_ + "0" + menage_, grappe_ + menage_)
	destring hhid1, gen(hhid)
	drop hhid1 grappe_ menage_
* ____________________________________________________________________________ 
*				 		Indicateur Type de logement 	
*					   -------------------------------
	rename s11q01 type_logem 
*				 		   Indicateur Électricité	
*					   -------------------------------
	rename s11q37 source_eclairage 
*				 	 Indicateur Évacuation des eaux usées 	
*					   -------------------------------
	rename s11q59 eva_eu
*				 		Indicateur Évacuation des ordures 	
*					   -------------------------------
	rename s11q53 eva_ord
*				 		   Indicateur Eau potable		
*					   -------------------------------
	rename s11q26b eau_potable
*				 	  Indicateur Équipements sanitaires 	
*					   -------------------------------
	rename s11q54 type_sanitr
	
	keep hhid type_logem source_eclairage eva_eu eva_ord eau_potable type_sanitr s11q02
	save "data\d_condvie_1.dta", replace 

*				 	  Indicateur Indice de surpeuplement	
*					   -------------------------------
	use "data\d_condvie_1.dta", clear

	notes : Le ménage est privé si le logement est surpeuplé (plus de 3 personnes par pièce)
	
	merge 1:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta", keepusing(hhweight hhsize) nogen
	gen ind_surpl = hhsize / s11q02
	drop s11q02 hhsize
	lab var ind_surpl "indice de surpeuplement"
	
	save "data\d_condvie_2.dta", replace 
	
*				 		Indicateur Biens d'équipement	 	
*					   -------------------------------
	use "${repert}ehcvm_menage_SEN2021.dta", clear
	gen nb_equipm = ordin + tv + fer + frigo + cuisin + decod + car
	rename nb_equipm nb_biens
	lab var nb_biens "nombre de biens d'équipements"
	save "data\ehcvm_menage_SEN2021_copie.dta", replace

	use "data\d_condvie_2.dta", clear 
	merge 1:1 hhid using "data\ehcvm_menage_SEN2021_copie.dta", keepusing(nb_biens cuisin) nogen

*				 		Indicateur Énergie de cuisson 	
*					   -------------------------------
	rename cuisin energ_cuiss

	save "data\d_condvie.dta", replace

/* 	
--------------------------------------------------------------------------------
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

keep hhid corruption

save "data\corruption.dta",replace

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
* ____________________________________________________________________________ 

clonevar nb_agress_vol = s20cq03
replace nb_agress_vol =0 if missing(nb_agress_vol)
lab var nb_agress_vol "nombres de personnes ayant subi une agression ou vol dans le menage"

* Merging
merge 1:1 hhid using "Data\corruption.dta" , nogen

keep hhid nb_agress_vol corruption 
save "data\d_gouv_inst.dta",replace


/* 	
--------------------------------------------------------------------------------
							Dimension emploi 
-------------------------------------------------------------------------------*/
			use "${repert}/ehcvm_individu_SEN2021.dta", clear

*				 		    Indicateur Chômage	 	
*					   -------------------------------
 // Nombre d'actifs dans le ménage
 gen actif = inlist(activ7j, 1, 2, 3, 4) 
 bysort hhid: egen nb_actifs = total(actif)
 
 // Nombre de chômeurs dans le ménage
 gen chomeur = (activ7j == 4)
 bysort hhid: egen nb_chomeurs = total(chomeur)
 lab var nb_chomeurs "Nombres de chômeurs"
 
*				     Indicateur Dépendance économique	 	
*				     -------------------------------
 // Nombre d'inactifs par ménage
 gen inactif = (actif == 0)
 bysort hhid: egen nb_inactifs = total(inactif)
 
 // Taux de dépendance économique
 gen taux_dep = nb_inactifs / nb_actifs
 replace taux_dep = 0 if nb_actifs == 0 // dépendance maximale si aucun actif
 lab var taux_dep "taux de dépendance économique"
 
*				 	  	  Indicateur sous-emploi	 	
*					   -------------------------------
 /* Au Sénégal, le nombre d'heures de travail
 réglementaire est de 40h / semaine (législation du travail au Sénégal) */
	global heures_trav_sem_legal = 40
 
 // Nombre d'occupés par ménage
 gen occ = cond(activ7j == 1, 1,0)
 bysort hhid: egen nb_occ = total(occ)
 
 // Individus en sous emploi
 gen emploi = cond(activ7j == 1 | activ7j == 2 | activ7j == 3, 1, 0)
 egen heures_trav_an = rowtotal(volhor volhor_sec)
 gen heures_trav_sem = heures_trav_an / 52
 gen ind_sous_emp = cond(emploi & (heures_trav_sem < $heures_trav_sem_legal), 1, 0)
 replace ind_sous_emp = cond(activ7j == 3, 0, ind_sous_emp) // retirer les TF ne cherchant pas un emploi
 
 // Nombre d'individus en sous emploi par ménage
 bysort hhid: egen nb_sous_emp = total(ind_sous_emp)
 label var nb_sous_emp "nombres de sous-emploi"
 
*				 	   Indicateur Travail des enfants
*					   -------------------------------
  // Identification des ménages ayant au moins un enfant qui travaille
 gen enft_trav = cond(emploi == 1 & age < 15, 1, 0)
 bysort hhid: egen nb_enft_trav = total(enft_trav)

 lab var enft_trav "travail des enfants"
 
 
*				 	    Indicateur Protection sociale
*					   -------------------------------

keep hhid nb_chomeurs taux_dep nb_sous_emp enft_trav
save "data\d_emploi.dta" , replace 


*-------------------------------------------------------------------------------
*		Création de la matrice des accomplissements
*-------------------------------------------------------------------------------
use "data\d_condvie.dta", clear

merge 1:1 hhid using "data\d_gouv_inst",nogen
merge 1:m hhid using "data\d_sante.dta", nogen
merge m:m hhid using "data\d_education.dta", nogen
merge m:m hhid using "data\d_emploi",nogen

* Sauvegarde de la matrice d'accomplissements
save "data\matrice_accomplissement.dta",replace

* Sauvegarde de la matrice d'accomplissements
merge m:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta",nogen keepusing(hhweight zref hhsize)
move hhid hhweight 
move hhsize zref

save "data\matrice_accom.dta",replace
