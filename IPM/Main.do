******************************************************************************
/*
							Rapport de stage
							
	_______________________________________________________________________
		Mesure de la pauvreté multidimensionnelle au niveau départemental 
								par EPD
	_______________________________________________________________________

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
	global repertoire ="https://raw.githubusercontent.com/Aissatou150/Rapport"
	
	
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
  Éducation		Fréquentation scolaire			Le ménage a un enfant de 6-16 ans qui ne fréquente actuellement pas l'école	___a
				Retard scolaire					Le ménage a un enfant de 8-13 ans ayant un retard scolaire de 2 ans ou plus	___a
				Nombre d'années de scolarité	Aucun membre du ménage âgé de 15 ans ou plus n'a complété 6 années d'études	___a
				Alphabétisation					Le quart des membres du ménage de 15 ans ou plus ne sait pas lire ou écrire ___a

	 Santé		Couverture maladie				Plus du tiers des membres du ménage ne disposent d'aucune forme d'assurance maladie       /a
				Qualité des services de santé	Un membre du ménage apprécie négativement au moins 5 critères sur 6	___3
				Maladies et problèmes de santé	Un membre du ménage souffre d'une maladie chronique (tension ou diabète)___3
				Vaccination des enfants 		de 0-6 ans	Un enfant de 0-6 ans du ménage n'a pas été vacciné lors de la campagne passée___3
				Handicap physique et mental		Un membre souffre d'un handicap physique/mental l'empêchant d'exercer une activité ou d'aller à l'école___3

Conditions 		Type de logement				Le ménage est privé si le logement est une case, baraque ou « autre » ___11
	de vie		Électricité						La source d'éclairage du ménage n'est pas : électricité, groupe électrogène ou solaire	___11
				Évacuation des eaux usées		Le ménage est privé si l'évacuation se fait dans la cour ou dans la rue/nature	___11
				Indice de surpeuplement			Le ménage est privé si le logement est surpeuplé (plus de 3 personnes par pièce)  ___b
				Eau potable						Le ménage n'a pas accès à l'eau potable	"s11_me_SEN2021"
				Énergie de cuisson				Le ménage n'utilise pas d'énergie propre pour la cuisson (électricité et gaz) ___b
				Équipements sanitaires			Le ménage ne dispose pas de toilettes privées améliorées	___11
				Biens d'équipement				Le ménage dispose de moins de 2 équipements (ventilateur, TV, ordinateur, cuisinière, réfrigérateur, bicyclette, motocyclette) et ne dispose ni de voiture, camion, machine à laver ni de groupe électrogène ___3

	Emploi		Dépendance économique			Le taux de dépendance est supérieur à 2	 ______1 , 4
				Travail des enfants				Le ménage est privé s'il y a un enfant de moins de 15 ans exerçant un travail	______1 , 4

Gouvernance 		Corruption					Le ménage a été victime d'un racket dans un service public	___20b
et institutions		Agression et vol			Un membre est victime d'agression ou de vol à domicile ou dans la rue	___20c
--------------------------------------------------------------------------------

*/	

/*_______________________________________________________________________________
      Création de la matrice des score de  bien être ou d'accomplissements
  _______________________________________________________________________________
*/

/* 						   Dimension Education 
						-------------------------                             */

use "${repertoire}/ehcvm_individu_SEN2021.dta"
// 		Indicateur Alphabétisation



// 		Indicateur Fréquentation scolaire



// 		Indicateur Retard scolaire



// 		Indicateur Nombre d'années de scolarité

save "emploi.dta", replace


/*_______________________________________________________________________________
      Création de la matrice des score de  bien être ou d'accomplissements
  _______________________________________________________________________________
*/

/* 						   Dimension Santé 
						-------------------------                             */

use "${repertoire}/ehcvm_welfare_SEN2018.dta",clear
// 		Indicateur Couverture maladie	



// 		Indicateur Qualité des services de santé



// 		Indicateur Maladies et problèmes de santé



// 		Indicateur Vaccination des enfants



// 		Indicateur Handicap physique et mental

save "sante.dta", replace