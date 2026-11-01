-- ============================================================
-- UrbanStay (PostgreSQL) : C. Géographie et canaux
-- Tables : reservations, clients, chambres, hotels
-- ============================================================


-- ------------------------------------------------------------
-- Géographie
-- ------------------------------------------------------------

-- C1. Combien de villes différentes compte la table hotels ?
-- Résultat : 8 valeurs brutes, mais 4 villes réelles après harmonisation
SELECT COUNT(DISTINCT ville) AS villes_brut
FROM hotels;

SELECT COUNT(DISTINCT UPPER(TRIM(ville))) AS villes_reelles
FROM hotels;


-- C2. Combien de pays différents chez les clients ?
-- Résultat : 6
SELECT COUNT(DISTINCT pays) AS nb_pays
FROM clients;


-- C3. Combien de clients par pays ?
-- Résultat : France 319, Espagne 39, Royaume-Uni 35, Italie 32,
-- Allemagne 31, Belgique 29, non renseigné 15 (total : 500)
SELECT pays,
       COUNT(*) AS nb_clients
FROM clients
GROUP BY pays
ORDER BY nb_clients DESC;


-- C4. Combien de réservations par pays du client ?
-- Résultat : France 1260, Espagne 149, Royaume-Uni 141, Italie 128,
-- Allemagne 128, Belgique 127, non renseigné 67 (total : 2000)
SELECT UPPER(TRIM(cl.pays)) AS pays_client,
       COUNT(*) AS nb_reservations
FROM reservations r
JOIN clients cl ON r.client_id = cl.client_id
GROUP BY UPPER(TRIM(cl.pays))
ORDER BY nb_reservations DESC;


-- C5. De quels pays viennent plus de 100 réservations ?
-- Résultat attendu : les 6 pays renseignés (requête à relancer)
SELECT UPPER(TRIM(cl.pays)) AS pays_client,
       COUNT(*) AS nb_reservations
FROM reservations r
JOIN clients cl ON r.client_id = cl.client_id
WHERE cl.pays IS NOT NULL
GROUP BY pays_client
HAVING COUNT(*) > 100
ORDER BY nb_reservations DESC;


-- C6. CA, panier moyen, durée de séjour et taux d'annulation par pays
-- Résultat : France en tête (587 937,20 €) ; taux d'annulation de 22,4 %
-- pour les clients sans pays renseigné
SELECT COALESCE(NULLIF(INITCAP(TRIM(cl.pays)), ''), 'Non renseigné') AS pays,
       COUNT(*) AS nb_reservations,
       ROUND(SUM(r.montant_total)
             FILTER (WHERE LOWER(TRIM(r.statut)) NOT LIKE 'annul%'), 2) AS ca_total,
       ROUND(AVG(r.montant_total)
             FILTER (WHERE LOWER(TRIM(r.statut)) NOT LIKE 'annul%'), 2) AS panier_moyen,
       ROUND(AVG(r.date_depart - r.date_arrivee)
             FILTER (WHERE LOWER(TRIM(r.statut)) NOT LIKE 'annul%'), 2) AS duree_moyenne_nuits,
       ROUND(100.0 * COUNT(*) FILTER (WHERE LOWER(TRIM(r.statut)) LIKE 'annul%')
             / COUNT(*), 1) AS taux_annulation_pct
FROM reservations r
JOIN clients cl ON r.client_id = cl.client_id
GROUP BY 1
ORDER BY ca_total DESC;


-- C7. Quels hôtels dépassent 200 réservations non annulées ?
-- Résultat attendu : 6 hôtels (requête à relancer)
SELECT h.nom_hotel,
       COUNT(*) AS nb_reservations
FROM reservations r
JOIN chambres c ON r.chambre_id = c.chambre_id
JOIN hotels h ON c.hotel_id = h.hotel_id
WHERE UPPER(TRIM(r.statut)) NOT LIKE 'ANNUL%'
GROUP BY h.nom_hotel
HAVING COUNT(*) > 200
ORDER BY nb_reservations DESC;


-- C8. CA par ville, catégorie et hôtel (hors annulations)
-- Résultat : dans chaque ville, l'hôtel 4 étoiles réalise le CA le plus élevé
SELECT INITCAP(TRIM(h.ville)) AS ville,
       TRIM(h.categorie) AS categorie,
       h.nom_hotel,
       COUNT(*) AS nb_sejours,
       ROUND(SUM(r.montant_total), 2) AS chiffre_affaires
FROM reservations r
JOIN chambres c ON r.chambre_id = c.chambre_id
JOIN hotels h ON c.hotel_id = h.hotel_id
WHERE LOWER(TRIM(r.statut)) NOT LIKE 'annul%'
GROUP BY ville, categorie, h.nom_hotel
ORDER BY ville, categorie DESC;


-- ------------------------------------------------------------
-- Canaux de réservation
-- ------------------------------------------------------------

-- C9. Combien de réservations par canal ?
-- Le CASE regroupe les différentes écritures d'un même canal.
-- Résultat : Site web 779, Booking 609, Agence 405, Téléphone 207 (total : 2000)
SELECT CASE
         WHEN LOWER(TRIM(canal_reservation)) LIKE '%web%'
           OR LOWER(TRIM(canal_reservation)) LIKE '%site%'   THEN 'Site web'
         WHEN LOWER(TRIM(canal_reservation)) LIKE '%book%'   THEN 'Booking'
         WHEN LOWER(TRIM(canal_reservation)) LIKE '%agen%'   THEN 'Agence'
         WHEN LOWER(TRIM(canal_reservation)) LIKE '%tel%'
           OR LOWER(TRIM(canal_reservation)) LIKE '%tél%'
           OR LOWER(TRIM(canal_reservation)) LIKE '%phone%'  THEN 'Téléphone'
         ELSE 'À vérifier'
       END AS canal,
       COUNT(*) AS nb_reservations
FROM reservations
GROUP BY 1
ORDER BY nb_reservations DESC;


-- C10. Quel montant moyen par canal, avec l'effectif ?
-- Résultat : Agence 558,27 € (402), Site web 522,48 € (777),
-- Téléphone 507,37 € (207), Booking 488,80 € (606)
SELECT CASE
         WHEN LOWER(TRIM(canal_reservation)) LIKE '%web%'
           OR LOWER(TRIM(canal_reservation)) LIKE '%site%'   THEN 'Site web'
         WHEN LOWER(TRIM(canal_reservation)) LIKE '%book%'   THEN 'Booking'
         WHEN LOWER(TRIM(canal_reservation)) LIKE '%agen%'   THEN 'Agence'
         WHEN LOWER(TRIM(canal_reservation)) LIKE '%tel%'
           OR LOWER(TRIM(canal_reservation)) LIKE '%tél%'
           OR LOWER(TRIM(canal_reservation)) LIKE '%phone%'  THEN 'Téléphone'
         ELSE 'À vérifier'
       END AS canal,
       ROUND(AVG(montant_total), 2) AS montant_moyen,
       COUNT(montant_total) AS nb_reservations_calcul
FROM reservations
GROUP BY 1
ORDER BY montant_moyen DESC;


-- C11. Quel taux d'annulation par canal ?
-- Résultat : Téléphone 12,1 %, Agence 9,9 %, Booking 9,7 %, Site web 8,7 %
SELECT canal,
       total_reservations,
       nb_annulees,
       ROUND(100.0 * nb_annulees / total_reservations, 1) AS taux_annulation_pct
FROM (
    SELECT CASE
             WHEN LOWER(TRIM(canal_reservation)) LIKE '%web%'
               OR LOWER(TRIM(canal_reservation)) LIKE '%site%'   THEN 'Site web'
             WHEN LOWER(TRIM(canal_reservation)) LIKE '%book%'   THEN 'Booking'
             WHEN LOWER(TRIM(canal_reservation)) LIKE '%agen%'   THEN 'Agence'
             WHEN LOWER(TRIM(canal_reservation)) LIKE '%tel%'
               OR LOWER(TRIM(canal_reservation)) LIKE '%tél%'
               OR LOWER(TRIM(canal_reservation)) LIKE '%phone%'  THEN 'Téléphone'
             ELSE 'À vérifier'
           END AS canal,
           COUNT(*) AS total_reservations,
           COUNT(*) FILTER (WHERE UPPER(TRIM(statut)) LIKE 'ANNUL%') AS nb_annulees
    FROM reservations
    GROUP BY canal
) AS stats_canal
ORDER BY taux_annulation_pct DESC;
