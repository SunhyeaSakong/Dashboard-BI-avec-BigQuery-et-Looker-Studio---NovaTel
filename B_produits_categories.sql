-- ============================================================
-- Groupe B : Produits et catégories (toute la période)
-- ============================================================

-- B1. Quelles sont les 5 catégories de produits les plus rentables (CA net) ?
SELECT
  categorie_produit,
  ROUND(SUM(montant_net), 2) AS ca_net
FROM `VOTRE_PROJET.novatel.vw_transactions_reporting`
GROUP BY categorie_produit
ORDER BY ca_net DESC
LIMIT 5;


-- B1 (détail). Top 5 des produits par CA net
-- Résultat : Forfait Famille 4 SIM en tête (1 151 579,38 €)
SELECT
  categorie_produit,
  nom_produit,
  ROUND(SUM(montant_net), 2) AS ca_net
FROM `VOTRE_PROJET.novatel.vw_transactions_reporting`
GROUP BY categorie_produit, nom_produit
ORDER BY ca_net DESC
LIMIT 5;


-- B2. Quelle marque génère le plus de CA net ? Le plus de volume (quantité) ?
SELECT
  marque,
  ROUND(SUM(montant_net), 2) AS ca_net,
  SUM(quantite) AS volume
FROM `VOTRE_PROJET.novatel.vw_transactions_reporting`
WHERE marque IS NOT NULL
GROUP BY marque
ORDER BY ca_net DESC;


-- B3. Quel produit individuel a le montant net moyen le plus élevé ?
SELECT
  categorie_produit,
  nom_produit,
  ROUND(AVG(montant_net), 2) AS ca_net_moyen,
  COUNT(*) AS nb_transactions
FROM `VOTRE_PROJET.novatel.vw_transactions_reporting`
GROUP BY categorie_produit, nom_produit
ORDER BY ca_net_moyen DESC
LIMIT 5;


-- B4. Quelle sous-catégorie a le taux de remboursement le plus élevé ?
-- Formule : SUM(remboursement) / SUM(montant_brut)
SELECT
  sous_categorie,
  ROUND(SUM(remboursement), 2) AS somme_remboursement,
  ROUND(SUM(montant_brut), 2) AS somme_montant_brut,
  ROUND(SAFE_DIVIDE(SUM(remboursement), SUM(montant_brut)) * 100, 2) AS taux_remboursement_pct
FROM `VOTRE_PROJET.novatel.vw_transactions_reporting`
GROUP BY sous_categorie
ORDER BY taux_remboursement_pct DESC
LIMIT 5;
