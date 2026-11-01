-- ============================================================
-- Groupe A : Chiffre d'affaires (année 2024)
-- ============================================================

-- A1. Quel est le CA net total 2024 par mois ?
-- Résultat : pic en décembre (750 300,48 €), creux en janvier (518 977,73 €)
SELECT
  numero_mois,
  ROUND(SUM(montant_net), 2) AS ca_net_mois
FROM `VOTRE_PROJET.novatel.vw_transactions_reporting`
WHERE EXTRACT(YEAR FROM date_transaction) = 2024
GROUP BY numero_mois
ORDER BY numero_mois;


-- A2. Quel est le CA encaissé vs CA net ? Quelle est la part non encaissée en % ?
-- Résultat : CA net 7 677 292,51 €, CA encaissé 7 565 739,83 €, 1,45 % non encaissé
SELECT
  ROUND(SUM(montant_net), 2) AS ca_net,
  ROUND(SUM(montant_encaisse), 2) AS ca_encaisse,
  ROUND(SUM(montant_net) - SUM(montant_encaisse), 2) AS ca_non_encaisse,
  ROUND(SAFE_DIVIDE(SUM(montant_net) - SUM(montant_encaisse), SUM(montant_net)) * 100, 2) AS pct_non_encaisse
FROM `VOTRE_PROJET.novatel.vw_transactions_reporting`
WHERE EXTRACT(YEAR FROM date_transaction) = 2024;


-- A3. Quels sont les 3 mois avec le CA net le plus élevé ?
-- Résultat : décembre, octobre, novembre
SELECT
  numero_mois,
  ROUND(SUM(montant_net), 2) AS ca_net_mois
FROM `VOTRE_PROJET.novatel.vw_transactions_reporting`
WHERE EXTRACT(YEAR FROM date_transaction) = 2024
GROUP BY numero_mois
ORDER BY ca_net_mois DESC
LIMIT 3;


-- A4. Quel trimestre génère le plus de CA net ? Le moins ?
-- Résultat : T4 le plus élevé, T1 le plus faible
SELECT
  EXTRACT(QUARTER FROM date_transaction) AS trimestre,
  ROUND(SUM(montant_net), 2) AS ca_net_trimestre
FROM `VOTRE_PROJET.novatel.vw_transactions_reporting`
WHERE EXTRACT(YEAR FROM date_transaction) = 2024
GROUP BY trimestre
ORDER BY ca_net_trimestre DESC;
