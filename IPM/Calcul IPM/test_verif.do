**********************************************************
* 1. Charger la base
**********************************************************
use "${rdata}\base_IPM_bis.dta", clear 

**********************************************************
* 2. Définition des poids et indicateur de pauvreté
**********************************************************
gen indweight = hhweight * hhsize
gen is_poor   = pcexp < zref

**********************************************************
* 3. Préparer fichier Excel
**********************************************************
putexcel set "${routput}/resultats_IPM.xlsx", sheet("FGT_Gini") replace

putexcel A1 = "Milieu"  ///
         B1 = "P0"      ///
         C1 = "P1"      ///
         D1 = "P2"      ///
         E1 = "Gini"

**********************************************************
* 4. Programme fiable pour calculer les indicateurs
**********************************************************
	cap program drop calc_indics
	program define calc_indics
    syntax , row(integer) label(str)

    ******************************************************************
    *      1. FGT
    ******************************************************************
    svyset [pweight = indweight]

    *--- P0 ---
    svy: mean is_poor
    scalar P0 = 100 * r(table)[1,1]

    *--- P1 ---
    gen ratio = cond(is_poor==1, (zref - pcexp) / zref, 0)
    svy: mean ratio
    scalar P1 = 100 * r(table)[1,1]
    drop ratio

    *--- P2 ---
    gen ratio2 = cond(is_poor==1, ((zref - pcexp) / zref)^2, 0)
    svy: mean ratio2
    scalar P2 = 100 * r(table)[1,1]
    drop ratio2

    ******************************************************************
    *      2. GINI (Méthode fiable – aire sous la courbe de Lorenz)
    ******************************************************************
    sort pcexp

    gen w  = indweight
    gen wx = w * pcexp

    gen cw  = sum(w)
    gen cwx = sum(wx)

    quietly summarize w
    scalar W = r(sum)

    quietly summarize wx
    scalar Y = r(sum)

    * Lorenz curve: L(F)
    gen L = cwx / Y
    gen F = cw / W

    * Aire sous la courbe de Lorenz
    gen area = (L + L[_n-1]) * (F - F[_n-1]) / 2 if _n > 1

    quietly summarize area
    scalar B = r(sum)

    scalar G = 100 * (1 - 2 * B)

    * Nettoyage
    drop w wx cw cwx L F area

    ******************************************************************
    *      3. Export vers Excel
    ******************************************************************
    putexcel A`row' = "`label'" ///
             B`row' = P0 ///
             C`row' = P1 ///
             D`row' = P2 ///
             E`row' = G

	putexcel set "${routput}/resultats_IPM.xlsx", sheet("Regions") modify

putexcel A1 = "Région" ///
         B1 = "P0"     ///
         C1 = "P1"     ///
         D1 = "P2"     ///
         E1 = "Gini"

end

**********************************************************
* 5. CALCUL POUR LES 4 MILIEUX
**********************************************************

display "----- CALCUL GLOBAL -----"
calc_indics, row(2) label("Global")

display "----- CALCUL URBAIN -----"
preserve
keep if milieu_bis == 1
calc_indics, row(3) label("Urbain")
restore

display "----- CALCUL AUTRES URBAIN -----"
preserve
keep if milieu_bis == 2
calc_indics, row(4) label("Autres urbain")
restore

display "----- CALCUL RURAL -----"
preserve
keep if milieu_bis == 3
calc_indics, row(5) label("Rural")
restore

display ">>> Export terminé : ${routput}/resultats_IPM.xlsx"



levelsof region, local(liste_regions)

local row = 2

foreach r of local liste_regions {

    preserve
        keep if region == `r'

        * Récupérer le label de la région (affichage propre)
        local lab : label (region) `r'
        if "`lab'" == "" local lab = "`r'"

        display "----- CALCUL REGION : `lab' -----"

        calc_indics, row(`row') label("`lab'")
    restore

    local row = `row' + 1
}

