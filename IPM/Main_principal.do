
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

//_____________________________________________________________________________
// 				 Préparation de l'environnement de travail 
//_____________________________________________________________________________
	notes : Cette base de données est issue de l'enquête EHCVM 2021-2022 ///
			Veuillez adapter le chemin d'accès à votre environnement de travail
	
	**** Vider la mémoire 
	clear all
	**** Définir le point comme séparateur de milliers
	set dp comma
	**** Demander à stata d'afficher les résultats complets (long tableau)
	set more off

	**** Définir et fixer les répertoires de travail 		
	global repert="https://raw.githubusercontent.com/Aissatou150/Rapport/main/"
	
	**** Créer un repertoire de travail et trois sous répertoires
	capture	mkdir "C:\Users\LENOVO\Desktop\ECOLE\ENSAE\MEMOIRE\Rapport_de_stage\IPM\traitement"
	global RT ="C:\Users\LENOVO\Desktop\ECOLE\ENSAE\MEMOIRE\Rapport_de_stage\IPM\traitement"
	capture mkdir "$RT\dirdata"
	capture mkdir "$RT\diroutput"
	
	**** Fixation du repertoire de trvail
	cd "C:\Users\LENOVO\Desktop\ECOLE\ENSAE\MEMOIRE\Rapport_de_stage\IPM\traitement"
	global rdata="$RT\dirdata"
	global routput="$RT\diroutput"

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
------------------------------------------------------------------------------*/

			/***** EXECUTION DES DIFFERENTS DO-FILES *******/
				 if(1) {
				 	do "main_Mat_accompls.do"
					}
				 if(1) {
				 	do "Main_Mat_privations.do"
					}
				 if(1) {
				 	do "Calcul_IPM.do"
					}
				 if(1) {
				 	do "analyse_IPM.do"
				 }