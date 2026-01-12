*****************************************************************************
*______________________________________________________________________
*       Estimations directes IPM par département (VERSION CORRIGÉE)
*______________________________________________________________________

*______________________________________________________________________
*                    Partie 1: Préparation des données
*______________________________________________________________________
use "${repert}s00_me_SEN2021.dta", clear

*_____________________________________________________________________________
*                      Création identifiant unique du ménage
tostring menage, gen(menage_)
tostring grappe, gen(grappe_)
gen hhid1 = cond(strlen(menage_) == 1, grappe_+"0"+menage_, grappe_+menage_)
destring hhid1, gen(hhid)
drop hhid1 grappe_ menage_

* ____________________________________________________________________________ 
rename s00q02 departement

keep hhid departement grappe

merge 1:1 hhid using "${repert}ehcvm_welfare_SEN2021.dta", ///
           keepusing(region pcexp hmstat hgender heduc ///
                     milieu hhsize dtot hactiv7j hage halfa hhweight) nogen

merge 1:m hhid using "${rdata}\base_IPM.dta", nogen

* Vérifier que toutes les variables nécessaires existent
capture confirm variable pauvre hhweight indiv_priv grappe departement
if _rc != 0 {
    display "ERREUR : Variables manquantes!"
    desc pauvre hhweight indiv_priv grappe departement
    exit
}

* Supprimer les anciennes variables départementales si elles existent
capture drop H_dept A_dept IPM_dept variance_H se_H cv_H ///
             n_menages n_effectif deff_dept ci_lower_H ci_upper_H

*_____________________________________________________________________________
*                    CRÉER LES NOUVELLES VARIABLES RÉSULTATS
*_____________________________________________________________________________
gen H_dept = .
gen A_dept = .
gen IPM_dept = .
gen variance_H = .
gen se_H = .
gen cv_H = .
gen n_menages = .
gen n_effectif = .
gen deff_dept = .
gen ci_lower_H = .
gen ci_upper_H = .

*_____________________________________________________________________________
*                    PLAN DE SONDAGE CORRECT
*_____________________________________________________________________________

* Vérifier si variable strate existe
capture confirm variable strate
if _rc == 0 {
    display "Plan de sondage : grappes + strates"
    svyset grappe [pw=hhweight], strata(strate)
}
else {
    display "Plan de sondage : grappes uniquement"
    svyset grappe [pw=hhweight]
}

* Vérifier le plan déclaré
svydescribe

*_____________________________________________________________________________
*                    BOUCLE PAR DÉPARTEMENT - AVEC CALCUL MANUEL DEFF
*_____________________________________________________________________________
levelsof departement, local(depts)

foreach d of local depts {
    
    display "======================================"
    display "Traitement du département : `d'"
    display "======================================"
    
    * Vérifier s'il y a des observations dans ce département
    quietly count if departement == `d'
    if r(N) == 0 {
        display "  Aucune observation dans ce département"
        display ""
        continue
    }
    
    * Sauvegarder le nombre total d'observations
    scalar n_total = r(N)
    replace n_menages = n_total if departement == `d'
    
    * 1. CALCUL DE H (INCIDENCE) - Proportion de pauvres
    capture quietly svy, subpop(if departement == `d'): mean pauvre
    
    if _rc == 0 {
        * Extraction des résultats depuis r(table)
        matrix H_table = r(table)
        
        * Stocker H et son erreur standard
        scalar H_val = H_table[1,1]
        scalar se_val = H_table[2,1]
        
        replace H_dept = H_val if departement == `d'
        replace se_H = se_val if departement == `d'
        replace variance_H = (se_val)^2 if departement == `d'
        
        * Calculer le coefficient de variation
        if !missing(H_val) & H_val > 0 {
            replace cv_H = se_val / H_val if departement == `d'
        }
        
        * Intervalles de confiance
        replace ci_lower_H = H_table[5,1] if departement == `d'
        replace ci_upper_H = H_table[6,1] if departement == `d'
        
        * CALCUL MANUEL DU DESIGN EFFECT (DEFF)
        * Formule: DEFF = variance_complexe / variance_SRS
        * variance_SRS = p*(1-p)/n pour une proportion
        
        if !missing(H_val) & H_val > 0 & H_val < 1 {
            * Variance sous échantillonnage aléatoire simple (SRS)
            scalar variance_srs = (H_val * (1 - H_val)) / n_total
            
            * Variance estimée avec plan complexe
            scalar variance_complexe = (se_val)^2
            
            * Design effect
            if variance_srs > 0 {
                scalar deff_val = variance_complexe / variance_srs
                replace deff_dept = deff_val if departement == `d'
                
                * Taille effective
                scalar n_eff = n_total / deff_val
                replace n_effectif = n_eff if departement == `d'
            }
            else {
                scalar deff_val = .
                scalar n_eff = .
            }
        }
        else {
            scalar deff_val = .
            scalar n_eff = .
        }
        
        * Affichage des résultats H
        display "  H = " %6.4f H_val
        display "  SE = " %6.4f se_val
        if !missing(H_val) & H_val > 0 {
            display "  CV = " %6.2f (se_val/H_val)*100 "%"
        }
        display "  Design effect = " %6.2f deff_val
        display "  N (brut) = " n_total
        if !missing(scalar(n_eff)) {
            display "  N (effectif) = " %6.1f n_eff
        }
    }
    else {
        display "  ERREUR dans le calcul de H"
        scalar H_val = .
        scalar se_val = .
        scalar deff_val = .
        scalar n_eff = .
    }
    
    * 2. CALCUL DE A (INTENSITÉ) - Moyenne des privations chez les pauvres
    quietly count if departement == `d' & pauvre == 1
    scalar n_pauvres = r(N)
    
    scalar A_val = .
    if n_pauvres > 0 {
        capture quietly svy, subpop(if departement == `d' & pauvre == 1): mean indiv_priv
        if _rc == 0 {
            matrix A_table = r(table)
            scalar A_val = A_table[1,1]
            replace A_dept = A_val if departement == `d'
            display "  A = " %6.4f A_val
            display "  Nombre de pauvres = " n_pauvres
            display "  % de pauvres = " %6.2f (n_pauvres/n_total)*100 "%"
        }
    }
    else {
        display "  Aucun pauvre dans ce département (H=0)"
        replace A_dept = 0 if departement == `d'  // A = 0 quand il n'y a pas de pauvres
        scalar A_val = 0
    }
    
    * 3. CALCUL IPM = H × A
    if !missing(scalar(H_val)) & !missing(scalar(A_val)) {
        scalar ipm_val = H_val * A_val
        replace IPM_dept = ipm_val if departement == `d'
        display "  IPM = H × A = " %6.4f H_val " × " %6.4f A_val " = " %6.4f ipm_val
    }
    
    display ""
    
    * Nettoyer les scalaires
    scalar drop H_val se_val deff_val n_total n_eff A_val ipm_val n_pauvres variance_srs variance_complexe
}

*_____________________________________________________________________________
*                    VÉRIFICATION ET CORRECTION DES VALEURS EXTRÊMES
*_____________________________________________________________________________

display ""
display "======================================"
display "VÉRIFICATION DES VALEURS EXTRÊMES"
display "======================================"

* Vérifier les design effects extrêmes
summarize deff_dept, detail
scalar deff_mean = r(mean)
scalar deff_sd = r(sd)

* Identifier les valeurs aberrantes (plus de 3 écarts-types)
gen deff_outlier = (deff_dept > deff_mean + 3*deff_sd) & !missing(deff_dept)
count if deff_outlier == 1
if r(N) > 0 {
    display "Design effects extrêmes détectés : " r(N)
    list departement deff_dept n_menages n_effectif if deff_outlier == 1, clean noobs
}

* Limiter les design effects extrêmes (max 100 pour éviter des tailles effectives trop faibles)
replace deff_dept = 100 if deff_dept > 100 & !missing(deff_dept)

* Recalculer la taille effective avec les DEFF corrigés
replace n_effectif = n_menages / deff_dept if !missing(deff_dept) & deff_dept > 0

*_____________________________________________________________________________
*                    DIAGNOSTICS ET EXPORTATION
*_____________________________________________________________________________

preserve
collapse (first) H_dept A_dept IPM_dept ///
                variance_H se_H cv_H ///
                n_menages n_effectif deff_dept ///
                ci_lower_H ci_upper_H, by(departement)

* Statistiques descriptives
display ""
display "======================================"
display "STATISTIQUES DES ESTIMATIONS DÉPARTEMENTALES"
display "======================================"

* H (Incidence)
summarize H_dept, detail
display "Incidence moyenne (H) : " %6.4f r(mean) " [" %6.4f r(min) "-" %6.4f r(max) "]"

* A (Intensité)
summarize A_dept, detail
display "Intensité moyenne (A) : " %6.4f r(mean) " [" %6.4f r(min) "-" %6.4f r(max) "]"

* IPM
summarize IPM_dept, detail
display "IPM moyen : " %6.4f r(mean) " [" %6.4f r(min) "-" %6.4f r(max) "]"

* Taille effective
summarize n_effectif, detail
display "Taille effective moyenne : " %6.1f r(mean) " [" %6.0f r(min) "-" %6.0f r(max) "]"

* Design effect
summarize deff_dept, detail
display "Design effect moyen : " %6.2f r(mean) " [" %6.2f r(min) "-" %6.2f r(max) "]"

* CV pour évaluer la précision
summarize cv_H if !missing(cv_H), detail

* Catégoriser par qualité du CV
gen qualite = ""
replace qualite = "Excellente (CV < 5%)" if cv_H < 0.05 & !missing(cv_H)
replace qualite = "Bonne (5-10%)" if cv_H >= 0.05 & cv_H < 0.10 & !missing(cv_H)
replace qualite = "Acceptable (10-15%)" if cv_H >= 0.10 & cv_H < 0.15 & !missing(cv_H)
replace qualite = "Médiocre (15-25%)" if cv_H >= 0.15 & cv_H < 0.25 & !missing(cv_H)
replace qualite = "Mauvaise (≥25%)" if cv_H >= 0.25 & !missing(cv_H)
replace qualite = "Non estimable" if missing(cv_H)

display ""
display "======================================"
display "QUALITÉ DES ESTIMATIONS PAR CV"
display "======================================"
tabulate qualite

* Identifier les départements problématiques
gen probleme = (cv_H > 0.15 & !missing(cv_H)) | (n_effectif < 30 & !missing(n_effectif))
count if probleme == 1
scalar n_problematiques = r(N)

if n_problematiques > 0 {
    display ""
    display "Départements problématiques (CV > 15% ou taille effective < 30) :"
    list departement H_dept cv_H n_menages n_effectif deff_dept if probleme == 1, ///
         clean noobs abbreviate(20)
}

* Classer les départements par taux de pauvreté
gsort -H_dept
gen rang_H = _n
label variable rang_H "Rang par incidence de pauvreté"

gsort -IPM_dept
gen rang_IPM = _n
label variable rang_IPM "Rang par IPM"

* Renommer pour export clair
rename H_dept taux_pauvrete_MD
rename variance_H variance_directe
rename n_menages n_echantillon

label variable taux_pauvrete_MD "Taux de pauvreté MD (H) départemental"
label variable variance_directe "Variance de l'estimation directe"
label variable se_H "Erreur standard de H"
label variable cv_H "Coefficient de variation de H"
label variable n_echantillon "Nombre de ménages échantillonnés"
label variable n_effectif "Taille d'échantillon effective"
label variable deff_dept "Design effect"
label variable A_dept "Intensité moyenne (A) départementale"
label variable IPM_dept "IPM départemental"

* Ordonner les variables pour un affichage logique
order departement rang_H rang_IPM taux_pauvrete_MD A_dept IPM_dept ///
      se_H cv_H n_echantillon n_effectif deff_dept ///
      ci_lower_H ci_upper_H variance_directe

* Sauvegarder les résultats
save "${rdata}\IPM_departements_final.dta", replace

export delimited using "${rdata}\IPM_departements_final.csv", replace

export excel using "${routput}/IPM_departements_final.xlsx", ///
     sheet("Résultats2") firstrow(variables) replace

display ""
display "✓ Exportations terminées :"
display "  - Stata : IPM_departements_final.dta"
display "  - CSV   : IPM_departements_final.csv"
display "  - Excel : IPM_departements_final.xlsx"

*_____________________________________________________________________________
*                    ANALYSE DE LA PRÉCISION
*_____________________________________________________________________________

display ""
display "======================================"
display "ANALYSE DE LA PRÉCISION DES ESTIMATIONS"
display "======================================"

* Relation entre taille effective et CV
correlate n_effectif cv_H
display "Corrélation taille effective - CV : " %6.4f r(rho)

* Relation entre design effect et CV
correlate deff_dept cv_H
display "Corrélation design effect - CV : " %6.4f r(rho)

* Graphique de la précision vs taille d'échantillon (pour visualisation)
scatter cv_H n_effectif, ///
    title("Précision vs Taille d'échantillon effective") ///
    ytitle("Coefficient de variation (CV)") ///
    xtitle("Taille d'échantillon effective") ///
    mlabel(departement) mlabsize(vsmall) ///
    note("Les estimations avec CV > 15% sont considérées peu précises")

*_____________________________________________________________________________


restore