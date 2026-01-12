/*------------------------------------------------------------------------------
				 	Dimension gouvernance et institutions 
-------------------------------------------------------------------------------*/

*		                       1. Corruption
*							  ---------------
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
	label define ouinon 0 "non" 1 "oui"
	label values corruption ouinon

	*------------------------------------------------------------------------
	notes : Le ménage a été victime d'un racket dans un service public
	*------------------------------------------------------------------------
	
	gen racket=cond(corruption==1,0,1)
	egen pr_corruption=max(racket),by(hhid)
	lab var pr_corruption "corruption"

	keep hhid pr_corruption	
	save "${rdata}\corruption.dta",replace

* 							2. Agression et vol 
*					   	   ----------------------
					use "${repert}s20c_me_SEN2021", clear 
*_____________________________________________________________________________
*			         Création identifiant unique du ménage

	tostring grappe, gen(grap)
	tostring menage, gen(men)
	gen id =cond(strlen(men)==1,grap+"0"+men,grap+men)
	destring id,gen(hhid)
	drop id grap men
*____________________________________________________________________________ 

	clonevar nb_agress_vol = s20cq03		// 6.933 missing values  
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

