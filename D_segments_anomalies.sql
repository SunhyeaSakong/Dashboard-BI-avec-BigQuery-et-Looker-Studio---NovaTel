-- ============================================================
-- UrbanStay (PostgreSQL) : D. Segments et anomalies
-- Tables : reservations, clients, chambres, hotels
-- ============================================================


-- ------------------------------------------------------------
-- Segments clients
-- ------------------------------------------------------------

-- D1. Combien de clients par segment ?
-- Résultat : Loisirs 305, Business 151, Groupe 44 (total : 500)
SELECT TRIM(segment_client) AS segment,
       COUNT(*) AS nb_clients
FROM clients
GROUP BY TRIM(segment_client)
ORDER BY nb_clients DESC;


-- D2. Pour chaque segment : nombre de clients et date d'inscription la plus ancienne
-- Résultat : Loisirs 2023-01-03, Business 2023-01-01, Groupe 2023-02-01
SELECT INITCAP(TRIM(segment_client)) AS segment,
       COUNT(*) AS nb_clients,
       MIN(date_inscription) AS premiere_inscription
FROM clients
GROUP BY segment
ORDER BY nb_clients DESC;


-- D3. Combien de réservations par segment client ?
-- Résultat : Loisirs 1240, Business 578, Groupe 182 (total : 2000)
SELECT UPPER(TRIM(cl.segment_client)) AS segment,
       COUNT(*) AS nb_reservations
FROM reservations r
JOIN clients cl ON r.client_id = cl.client_id
GROUP BY UPPER(TRIM(cl.segment_client))
ORDER BY nb_reservations DESC;


-- D4. Quel montant moyen par segment client, avec l'effectif ?
-- Résultat : Groupe 722,31 € (182), Loisirs 551,99 € (1234), Business 380,22 € (576)
SELECT UPPER(TRIM(cl.segment_client)) AS segment,
       ROUND(AVG(r.montant_total), 2) AS montant_moyen,
       COUNT(r.montant_total) AS nb_reservations_calcul
FROM reservations r
JOIN clients cl ON r.client_id = cl.client_id
GROUP BY UPPER(TRIM(cl.segment_client))
ORDER BY montant_moyen DESC;


-- D5. Quelle durée moyenne de séjour par segment client ?
-- Résultat : Groupe 4,31 nuits, Loisirs 3,52, Business 2,39
SELECT UPPER(TRIM(cl.segment_client)) AS segment,
       ROUND(AVG(r.date_depart - r.date_arrivee), 2) AS duree_moyenne_nuits
FROM reservations r
JOIN clients cl ON r.client_id = cl.client_id
GROUP BY UPPER(TRIM(cl.segment_client))
ORDER BY duree_moyenne_nuits DESC;


-- D6. Quels clients ont fait au moins 8 réservations ?
-- Résultat : 16 clients ; le client 443 arrive en tête avec 10 réservations
SELECT cl.client_id,
       COUNT(*) AS nb_reservations
FROM clients cl
JOIN reservations r ON cl.client_id = r.client_id
GROUP BY cl.client_id
HAVING COUNT(*) >= 8
ORDER BY nb_reservations DESC;


-- ------------------------------------------------------------
-- Anomalies et qualité des données
-- ------------------------------------------------------------

-- D7. Pour combien de clients le pays n'est-il pas renseigné ?
-- Résultat : 15
SELECT COUNT(*) AS nb_clients_sans_pays
FROM clients
WHERE pays IS NULL;


-- D8. Combien de réservations n'ont pas de montant ?
-- COUNT(colonne) ignore les NULL.
-- Résultat : 2000 lignes, 1992 avec montant, soit 8 sans montant (0,4 %)
SELECT COUNT(*) AS toutes_les_lignes,
       COUNT(montant_total) AS lignes_avec_montant
FROM reservations;


-- D9. Combien de réservations par statut ?
-- Résultat : Terminée 1423, Confirmée 385, Annulée 192 (total : 2000)
SELECT statut,
       COUNT(*) AS nb_reservations
FROM reservations
GROUP BY statut
ORDER BY nb_reservations DESC;


-- D10. Quel montant total par statut ?
-- Résultat : Terminée 731 761,68 €, Confirmée 200 939,45 €, Annulée 98 925,88 €
SELECT statut,
       SUM(montant_total) AS montant_total_par_statut
FROM reservations
GROUP BY statut
ORDER BY montant_total_par_statut DESC;


-- D11. Un séjour annulé dure-t-il aussi longtemps qu'un séjour terminé ?
-- Résultat : Terminée 3,29 nuits, Confirmée 3,24, Annulée 3,15
SELECT INITCAP(TRIM(statut)) AS statut,
       ROUND(AVG(date_depart - date_arrivee), 2) AS duree_moyenne_nuits
FROM reservations
GROUP BY INITCAP(TRIM(statut))
ORDER BY duree_moyenne_nuits DESC;


-- D12. Quel taux d'annulation par hôtel ?
-- Résultat : le plus élevé à Bordeaux Quinconces (12,4 %), le plus faible
-- à Marseille Vieux-Port et Lyon Part-Dieu (8,3 %)
SELECT nom_hotel,
       total_reservations,
       nb_annulees,
       ROUND(100.0 * nb_annulees / total_reservations, 1) AS taux_annulation_pct
FROM (
    SELECT h.nom_hotel,
           COUNT(*) AS total_reservations,
           COUNT(*) FILTER (WHERE UPPER(TRIM(r.statut)) LIKE 'ANNUL%') AS nb_annulees
    FROM reservations r
    JOIN chambres c ON r.chambre_id = c.chambre_id
    JOIN hotels h ON c.hotel_id = h.hotel_id
    GROUP BY h.nom_hotel
) AS stats_hotel
ORDER BY taux_annulation_pct DESC;
