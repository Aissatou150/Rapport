clear all
set more off
set seed 12345  // Reproductibilité


* Définir chemins (ADAPTER À VOTRE ENVIRONNEMENT)
global rdata   "C:\Users\LENOVO\Desktop\ECOLE\ENSAE\MEMOIRE\Rapport_de_stage\IPM\validite\data"
global tables  "C:\Users\LENOVO\Desktop\ECOLE\ENSAE\MEMOIRE\Rapport_de_stage\IPM\validite\tables"
global graphs  "C:\Users\LENOVO\Desktop\ECOLE\ENSAE\MEMOIRE\Rapport_de_stage\IPM\validite\graphs"

* Créer dossiers si nécessaire
capture mkdir "${tables}"
capture mkdir "${graphs}"

*-------------------------------------------------------*
* PARTIE 1 : IPM NATIONAL - VERSION CORRECTE
*-------------------------------------------------------*

use "${rdata}\base_IPM.dta", clear
svyset [pw=hhweight]

di _newline(3) "{bf:{ul:PARTIE 1 : IPM NATIONAL}}"
di "{hline 70}"

* Programme
capture program drop ipm_national
program define ipm_national, rclass
    quietly svy: mean pauvre
    scalar H_temp = r(table)[1,1]
    
    quietly svy, subpop(pauvre): mean indiv_priv
    scalar A_temp = r(table)[1,1]
    
    return scalar H = H_temp
    return scalar A = A_temp
    return scalar M0 = H_temp * A_temp
    
    scalar drop H_temp A_temp
end

* Bootstrap
di _newline "Bootstrap (1000 reps)..."
timer clear 1
timer on 1

bootstrap M0=r(M0) H=r(H) A=r(A), reps(1000) notable ///
    saving("${rdata}\boot_national", replace): ipm_national

timer off 1
qui timer list 1
local temps = r(t1)/60

estat bootstrap, percentile

* ⭐ EXTRAIRE CORRECTEMENT LES RÉSULTATS
* e(b) = estimations [1 ligne x 3 colonnes: M0, H, A]
* e(ci_percentile) = IC [2 lignes x 3 colonnes: M0, H, A]
*   Ligne 1 = lower limits, Ligne 2 = upper limits
* e(se) = erreurs-types [1 ligne x 3 colonnes: M0, H, A]

matrix coef = e(b)
matrix ic   = e(ci_percentile)
matrix se   = e(se)

di _newline "{txt}{bf:VÉRIFICATION :}"
di "Coefficients e(b):"
matrix list coef
di _newline "IC e(ci_percentile):"
matrix list ic
di _newline "SE e(se):"
matrix list se

* ⭐ EXTRACTION CORRECTE (colonnes : 1=M0, 2=H, 3=A)

* M0 (colonne 1)
scalar M0_est = coef[1,1]
scalar M0_inf = ic[1,1]    // lower limit, colonne M0
scalar M0_sup = ic[2,1]    // upper limit, colonne M0
scalar M0_se  = se[1,1]

* H (colonne 2)
scalar H_est = coef[1,2]
scalar H_inf = ic[1,2]     // lower limit, colonne H
scalar H_sup = ic[2,2]     // upper limit, colonne H
scalar H_se  = se[1,2]

* A (colonne 3)
scalar A_est = coef[1,3]
scalar A_inf = ic[1,3]     // lower limit, colonne A
scalar A_sup = ic[2,3]     // upper limit, colonne A
scalar A_se  = se[1,3]

* Affichage
di _newline(2) "{txt}{bf:RÉSULTATS IPM NATIONAL :}"
di "{txt}{hline 75}"
di "{txt}Incidence (H) : {res}" %7.5f H_est  "{txt} ± {res}" %7.5f H_se  "{txt}  IC [{res}" %7.5f H_inf  "{txt} ; {res}" %7.5f H_sup  "{txt}]"
di "{txt}Intensité (A) : {res}" %7.5f A_est  "{txt} ± {res}" %7.5f A_se  "{txt}  IC [{res}" %7.5f A_inf  "{txt} ; {res}" %7.5f A_sup  "{txt}]"
di "{txt}IPM (M₀)      : {res}" %7.5f M0_est "{txt} ± {res}" %7.5f M0_se "{txt}  IC [{res}" %7.5f M0_inf "{txt} ; {res}" %7.5f M0_sup "{txt}]"
di "{txt}{hline 75}"
di "{txt}Temps d'exécution : {res}" %4.1f `temps' "{txt} minutes"

* Export Excel
putexcel set "${tables}\ipm_national.xlsx", replace sheet("National")

putexcel A1 = "Indice de Pauvreté Multidimensionnelle - Niveau National", bold
putexcel A2 = "Sénégal, EHCVM 2021-2022"

putexcel A4 = "Indicateur", bold
putexcel B4 = "Estimation", bold
putexcel C4 = "Erreur-type", bold
putexcel D4 = "IC 95% inf", bold
putexcel E4 = "IC 95% sup", bold

* Ligne H
putexcel A5 = "Incidence (H)"
putexcel B5 = (H_est), nformat(number_d4)
putexcel C5 = (H_se), nformat(number_d4)
putexcel D5 = (H_inf), nformat(number_d4)
putexcel E5 = (H_sup), nformat(number_d4)

* Ligne A
putexcel A6 = "Intensité (A)"
putexcel B6 = (A_est), nformat(number_d4)
putexcel C6 = (A_se), nformat(number_d4)
putexcel D6 = (A_inf), nformat(number_d4)
putexcel E6 = (A_sup), nformat(number_d4)

* Ligne M0
putexcel A7 = "IPM (M₀)", bold
putexcel B7 = (M0_est), nformat(number_d4)
putexcel C7 = (M0_se), nformat(number_d4)
putexcel D7 = (M0_inf), nformat(number_d4)
putexcel E7 = (M0_sup), nformat(number_d4)

* Notes
putexcel A9 = "Source : Calculs de l'auteur à partir de l'EHCVM 2021-2022"
putexcel A10 = "Note : Intervalles de confiance calculés par bootstrap (1000 réplications, méthode percentile)"
putexcel A11 = "Seuil de pauvreté multidimensionnelle : k = 0.32 (32% des privations cumulées)"

di _newline "{txt}✓ Tableau sauvegardé : {res}${tables}\ipm_national.xlsx"

* Nettoyer les scalaires
scalar drop M0_est M0_inf M0_sup M0_se H_est H_inf H_sup H_se A_est A_inf A_sup A_se
```

## 📊 Ce que vous devriez voir maintenant :

**Dans la console :**
```
Incidence (H) : 0.47470 ± 0.00258  IC [0.46957 ; 0.47979]
Intensité (A) : 0.49599 ± 0.00059  IC [0.49482 ; 0.49719]
IPM (M₀)      : 0.23544 ± 0.00129  IC [0.23282 ; 0.23797]


*-------------------------------------------------------*
* PARTIE 2 : SENSIBILITÉ - VERSION DÉFINITIVEMENT CORRIGÉE
*-------------------------------------------------------*

use "${rdata}\base_IPM.dta", clear
svyset [pw=hhweight]

di _newline(3) "{bf:{ul:PARTIE 2 : SENSIBILITÉ AU SEUIL k}}"
di "{hline 70}"
di "{txt}Seuils testés : 0.25, 0.30, 0.32, 0.33, 0.35, 0.40"
di "{txt}Bootstrap : 500 réplications par seuil"
di "{hline 70}"

local seuils "0.25 0.30 0.32 0.33 0.35 0.40"
local nb_seuils : word count `seuils'

matrix sens_k = J(`nb_seuils', 9, .)

timer clear 2
timer on 2

* ⭐ DÉFINIR LE PROGRAMME UNE SEULE FOIS, AVANT LA BOUCLE
capture program drop ipm_k
program define ipm_k, rclass
    quietly svy: mean pauvre_k
    scalar H_temp = r(table)[1,1]
    
    quietly svy, subpop(pauvre_k): mean indiv_priv
    scalar A_temp = r(table)[1,1]
    
    return scalar H = H_temp
    return scalar A = A_temp
    return scalar M0 = H_temp * A_temp
    
    scalar drop H_temp A_temp
end

* Maintenant la boucle
local row = 1
foreach k of local seuils {
    
    di _newline(2) "{txt}{bf:[`row'/`nb_seuils'] Seuil k = `k'}"
    
    * Créer la variable pauvre_k
    gen pauvre_k = (score_final >= `k')
    
    * Bootstrap (le programme ipm_k existe déjà)
    di "{txt}Bootstrap en cours (500 reps)..."
    bootstrap M0=r(M0) H=r(H) A=r(A), reps(500) dots(10): ipm_k
    
    * Extraire résultats
    estat bootstrap, percentile
    
    matrix coef_k = e(b)
    matrix ic_k   = e(ci_percentile)
    matrix se_k   = e(se)
    
    * Stocker
    matrix sens_k[`row', 1] = `k'
    matrix sens_k[`row', 2] = coef_k[1,2]    // H
    matrix sens_k[`row', 3] = coef_k[1,3]    // A
    matrix sens_k[`row', 4] = coef_k[1,1]    // M0
    matrix sens_k[`row', 5] = ic_k[1,1]      // M0 lower
    matrix sens_k[`row', 6] = ic_k[2,1]      // M0 upper
    matrix sens_k[`row', 7] = se_k[1,1]      // SE(M0)
    matrix sens_k[`row', 8] = ic_k[2,1] - ic_k[1,1]  // Largeur
    
    if `k' == 0.32 {
        scalar M0_base = coef_k[1,1]
    }
    
    di "{txt}✓ Terminé - M₀ = " %6.4f coef_k[1,1]
    
    * Supprimer pauvre_k pour la prochaine itération
    drop pauvre_k
    
    local row = `row' + 1
}

timer off 2
qui timer list 2
local temps2 = r(t2)/60

* ⭐ CORRECTION : Calculer la variation APRÈS avoir identifié M0_base
* D'abord, vérifier que M0_base existe
if scalar(M0_base) == . {
    di "{err}Erreur : baseline k=0.32 non trouvée"
    exit
}

* Variation vs baseline
forvalues i = 1/`nb_seuils' {
    * Vérifier que M0_base existe et n'est pas manquant
    if M0_base != . {
        matrix sens_k[`i', 9] = (sens_k[`i',4] - M0_base) / M0_base * 100
    }
    else {
        matrix sens_k[`i', 9] = .
    }
}

matrix colnames sens_k = "k" "H" "A" "M0" "M0_inf" "M0_sup" "SE" "Largeur" "Var_%"

* Affichage
di _newline(2) "{txt}{bf:RÉSULTATS SENSIBILITÉ :}"
di "{txt}{hline 90}"
di "{txt}   k    │    H     │    A     │   M₀     │       IC 95%        │  Var %"
di "{txt}{hline 90}"
forvalues i = 1/`nb_seuils' {
    di "{txt} " %5.3f sens_k[`i',1] "  │ " ///
       %7.5f sens_k[`i',2] " │ " ///
       %7.5f sens_k[`i',3] " │ " ///
       %7.5f sens_k[`i',4] " │ [" ///
       %7.5f sens_k[`i',5] " ; " ///
       %7.5f sens_k[`i',6] "] │ " ///
       %7.2f sens_k[`i',9] "%"  // ⭐ Changé de %+6.2f à %7.2f
}
di "{txt}{hline 90}"
di "{txt}Temps : {res}" %4.1f `temps2' "{txt} minutes"
* Export Excel
*-------------------------------------------------------*
* EXPORT MANUEL (MÉTHODE INFAILLIBLE)
*-------------------------------------------------------*

* Créer le fichier Excel avec putexcel
putexcel set "${tables}\sensibilite_k.xlsx", replace sheet("Sensibilité")

* En-têtes
putexcel A1 = "Test de sensibilité de l'IPM au seuil de pauvreté", bold
putexcel A2 = "Niveau national - Sénégal (EHCVM 2021-2022)"

putexcel A4 = "Seuil (k)", bold
putexcel B4 = "H", bold
putexcel C4 = "A", bold
putexcel D4 = "M₀", bold
putexcel E4 = "IC 95% inf", bold
putexcel F4 = "IC 95% sup", bold
putexcel G4 = "Erreur-type", bold
putexcel H4 = "Largeur IC", bold
putexcel I4 = "Variation (%)", bold

* Remplir ligne par ligne
forvalues i = 1/6 {
    local row = `i' + 4
    
    * Extraire les valeurs
    scalar k_val = sens_k[`i', 1]
    scalar h_val = sens_k[`i', 2]
    scalar a_val = sens_k[`i', 3]
    scalar m0_val = sens_k[`i', 4]
    scalar m0_inf = sens_k[`i', 5]
    scalar m0_sup = sens_k[`i', 6]
    scalar se_val = sens_k[`i', 7]
    scalar larg = sens_k[`i', 8]
    scalar var_val = sens_k[`i', 9]
    
    * Écrire dans Excel
    putexcel A`row' = (k_val), nformat(number_d2)
    putexcel B`row' = (h_val), nformat(number_d4)
    putexcel C`row' = (a_val), nformat(number_d4)
    putexcel D`row' = (m0_val), nformat(number_d4)
    putexcel E`row' = (m0_inf), nformat(number_d4)
    putexcel F`row' = (m0_sup), nformat(number_d4)
    putexcel G`row' = (se_val), nformat(number_d5)
    putexcel H`row' = (larg), nformat(number_d4)
    putexcel I`row' = (var_val), nformat(number_d2)
}

* Notes
putexcel A12 = "Source : Calculs de l'auteur, EHCVM 2021-2022"
putexcel A13 = "Note : Intervalles de confiance calculés par bootstrap (500 réplications, méthode percentile)"
putexcel A14 = "Baseline : k = 0.32 (ligne en gras)"
putexcel A15 = "Standard international : k = 0.33"

* Mettre en gras la ligne k=0.32 (ligne 7 du tableau = row 11)
putexcel A7:I7, bold

di _newline "{txt}✓ Tableau Excel créé : {res}${tables}\sensibilite_k.xlsx"

* Nettoyer les scalaires
scalar drop k_val h_val a_val m0_val m0_inf m0_sup se_val larg var_val

* Graphique
preserve
    clear
    svmat sens_k, names(col)
    
    twoway (line M0 k, lwidth(thick) lcolor(navy)) ///
           (rarea M0_inf M0_sup k, fcolor(navy%15) lwidth(none)), ///
        xlabel(0.25(0.05)0.40, format(%3.2f) grid) ///
        ylabel(, format(%4.3f) grid angle(0)) ///
        xtitle("Seuil de pauvreté (k)", size(medlarge)) ///
        ytitle("IPM (M₀)", size(medlarge)) ///
        title("Sensibilité de l'IPM au seuil", size(large)) ///
        xline(0.32, lpattern(dash) lcolor(red)) ///
        xline(0.33, lpattern(dot) lcolor(blue)) ///
        legend(order(1 "M₀" 2 "IC 95%") pos(6)) ///
        note("Rouge: k=0.32 (baseline) ; Bleu: k=0.33 (standard)", size(small)) ///
        scheme(s2color) graphregion(color(white))
    
    graph export "${graphs}\sensibilite_k.png", replace width(3000)
restore

di "{txt}✓ Graphique : {res}${graphs}\sensibilite_k.png"

scalar drop M0_base



*=======================================================*
* ANALYSE IPM PAR MILIEU DE RÉSIDENCE
* Dakar urbain | Autres urbains | Rural
*=======================================================*

use "${rdata}\base_IPM_bis.dta", clear
svyset [pw=hhweight]

*-------------------------------------------------------*
* PARTIE 1 : IPM PAR MILIEU AVEC IC
*-------------------------------------------------------*

* Matrice pour stocker résultats (3 milieux × 9 colonnes)
matrix ipm_milieu = J(3, 9, .)

* Programme bootstrap (identique à avant)
capture program drop ipm_milieu_calc
program define ipm_milieu_calc, rclass
    args milieu_val
    
    quietly svy, subpop(if milieu_bis == `milieu_val'): mean pauvre
    scalar H_temp = r(table)[1,1]
    
    quietly svy, subpop(if milieu_bis == `milieu_val' & pauvre == 1): mean indiv_priv
    scalar A_temp = r(table)[1,1]
    
    return scalar H = H_temp
    return scalar A = A_temp
    return scalar M0 = H_temp * A_temp
    
    scalar drop H_temp A_temp
end

* Boucle sur les 3 milieux
forvalues m = 1/3 {
    
    local milieu_nom : label milieu_lbl `m'
    
    di _newline(2) "{bf:MILIEU `m' : `milieu_nom'}"
    di "{txt}Bootstrap (1000 reps)..."
    
    * Bootstrap
    timer clear
    timer on 1
    
    bootstrap M0=r(M0) H=r(H) A=r(A), reps(1000) notable: ///
        ipm_milieu_calc `m'
    
    timer off 1
    qui timer list 1
    local temps = r(t1)/60
    
    estat bootstrap, percentile
    
    * Extraire résultats
    matrix coef_m = e(b)
    matrix ic_m   = e(ci_percentile)
    matrix se_m   = e(se)
    
    * Stocker dans matrice
    matrix ipm_milieu[`m', 1] = `m'
    matrix ipm_milieu[`m', 2] = coef_m[1,2]    // H
    matrix ipm_milieu[`m', 3] = ic_m[1,2]      // H_inf
    matrix ipm_milieu[`m', 4] = ic_m[2,2]      // H_sup
    matrix ipm_milieu[`m', 5] = coef_m[1,3]    // A
    matrix ipm_milieu[`m', 6] = ic_m[1,3]      // A_inf
    matrix ipm_milieu[`m', 7] = ic_m[2,3]      // A_sup
    matrix ipm_milieu[`m', 8] = coef_m[1,1]    // M0
    matrix ipm_milieu[`m', 9] = ic_m[1,1]      // M0_inf
    
    * Ajouter M0_sup dans une 10ème colonne
    matrix ipm_milieu = (ipm_milieu, J(3,1,.))
    matrix ipm_milieu[`m', 10] = ic_m[2,1]     // M0_sup
    
    * Affichage
    di "{txt}H  : {res}" %6.4f coef_m[1,2] "{txt} IC [{res}" %6.4f ic_m[1,2] "{txt};{res}" %6.4f ic_m[2,2] "{txt}]"
    di "{txt}A  : {res}" %6.4f coef_m[1,3] "{txt} IC [{res}" %6.4f ic_m[1,3] "{txt};{res}" %6.4f ic_m[2,3] "{txt}]"
    di "{txt}M₀ : {res}" %6.4f coef_m[1,1] "{txt} IC [{res}" %6.4f ic_m[1,1] "{txt};{res}" %6.4f ic_m[2,1] "{txt}]"
    di "{txt}Temps : {res}" %4.1f `temps' "{txt} min"
}

matrix colnames ipm_milieu = "Milieu" "H" "H_inf" "H_sup" "A" "A_inf" "A_sup" "M0" "M0_inf" "M0_sup"

* Affichage récapitulatif
di _newline(2) "{bf:TABLEAU RÉCAPITULATIF PAR MILIEU :}"
di "{txt}{hline 85}"
di "{txt}Milieu             │    H     │       IC 95%       │   M₀     │       IC 95%"
di "{txt}{hline 85}"
forvalues m = 1/3 {
    local nom : label milieu_lbl `m'
    di "{txt}" %15s "`nom'" " │ " ///
       %6.4f ipm_milieu[`m',2] " │ [" ///
       %6.4f ipm_milieu[`m',3] ";" ///
       %6.4f ipm_milieu[`m',4] "] │ " ///
       %6.4f ipm_milieu[`m',8] " │ [" ///
       %6.4f ipm_milieu[`m',9] ";" ///
       %6.4f ipm_milieu[`m',10] "]"
}
di "{txt}{hline 85}"

*-------------------------------------------------------*
* EXPORT EXCEL
*-------------------------------------------------------*

putexcel set "${tables}\ipm_par_milieu.xlsx", replace sheet("Par_milieu")

putexcel A1 = "IPM par milieu de résidence - Sénégal (EHCVM 2021-2022)", bold
putexcel A3 = "Milieu", bold
putexcel B3 = "H", bold
putexcel C3 = "H (IC inf)", bold
putexcel D3 = "H (IC sup)", bold
putexcel E3 = "A", bold
putexcel F3 = "A (IC inf)", bold
putexcel G3 = "A (IC sup)", bold
putexcel H3 = "M₀", bold
putexcel I3 = "M₀ (IC inf)", bold
putexcel J3 = "M₀ (IC sup)", bold

* Remplir les lignes
forvalues m = 1/3 {
    local row = `m' + 3
    local nom : label milieu_lbl `m'
    
    putexcel A`row' = "`nom'"
    putexcel B`row' = (ipm_milieu[`m',2]), nformat(number_d4)
    putexcel C`row' = (ipm_milieu[`m',3]), nformat(number_d4)
    putexcel D`row' = (ipm_milieu[`m',4]), nformat(number_d4)
    putexcel E`row' = (ipm_milieu[`m',5]), nformat(number_d4)
    putexcel F`row' = (ipm_milieu[`m',6]), nformat(number_d4)
    putexcel G`row' = (ipm_milieu[`m',7]), nformat(number_d4)
    putexcel H`row' = (ipm_milieu[`m',8]), nformat(number_d4)
    putexcel I`row' = (ipm_milieu[`m',9]), nformat(number_d4)
    putexcel J`row' = (ipm_milieu[`m',10]), nformat(number_d4)
}

putexcel A9 = "Source : Calculs de l'auteur, EHCVM 2021-2022"
putexcel A10 = "Note : IC à 95% par bootstrap (1000 réplications)"
putexcel A11 = "Seuil : k = 0.32"

di _newline "{txt}✓ Tableau sauvegardé : {res}${tables}\ipm_par_milieu.xlsx"
