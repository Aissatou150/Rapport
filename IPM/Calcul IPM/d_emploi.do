/*-----------------------------------------------------------------------------
							Dimension emploi 
  ----------------------------------------------------------------------------*/

/*
  	use "${repert}/s15_me_SEN2021.dta", clear
*_____________________________________________________________________________
*			         Création identifiant unique du ménage

	tostring grappe, gen(grap)
	tostring menage, gen(men)
	gen id =cond(strlen(men)==1,grap+"0"+men,grap+men)
	destring id,gen(hhid)
	drop id grap men
* ____________________________________________________________________________ 
	replace s15q05= 2if missing(s15q05)
*/	
  
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
*					----------------------
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

	gen nb_chom = cond(nb_chomeurs < (nb_actifs / 2), 0, 1) 
	egen pr_chom = max(nb_chom),by(hhid)
	lab var pr_chom "IP chômage"

	 
*				     2- Indicateur Dépendance économique	 	
*				     -------------------------------
	 // Nombre d'inactifs par ménage
	 gen inactif = (activ7j == 5)
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

 
*				 	 3- Indicateur sous-emploi	 	
*					 ---------------------------
 /* Au Sénégal, le nombre d'heures de travail
églementaire est de 40h / semaine (législation du travail au Sénégal) */
	 global heures_trav_sem_legal = 38
 
	 // Nombre d'occupés par ménage
	 gen occup = cond(activ7j == 1, 1,0)
	 bysort hhid: egen nb_occup = total(occ)
	 
	 // Individus en sous emploi
	 gen emploi = cond(activ7j == 1 | activ7j == 2 | activ7j == 3, 1, 0)
	 egen heures_trav_an = rowtotal(volhor volhor_sec)
	 gen heures_trav_sem = heures_trav_an / 52
	 *gen ind_sous_emp = cond(emploi & (heures_trav_sem < $heures_trav_sem_legal ), 1, 0)
	 *replace ind_sous_emp = cond(activ7j == 3, 0, ind_sous_emp) // retirer les TF ne cherchant pas un emploi
	 n
	 gen ind_sous_emp = cond(occup==1 & (heures_trav_sem < $heures_trav_sem_legal), 1, 0)

	 
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
 
	
 
*				 	 4- Indicateur Travail des enfants
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

