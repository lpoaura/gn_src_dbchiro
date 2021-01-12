UPDATE src_dbchirogcra.management_study
SET
    id_study = id_study
;

UPDATE src_dbchirogcra.accounts_profile
SET
    email = email
;

SELECT *
    FROM
        utilisateurs.t_roles
    WHERE
            email IN (SELECT DISTINCT
                          email
                          FROM
                              utilisateurs.t_roles
                            , gn_synthese.synthese
                          WHERE
                                id_role = synthese.id_digitiser
                            AND id_digitiser IN (
                              SELECT DISTINCT
                                  id_role
                                  FROM
                                      utilisateurs.t_roles
                                  WHERE
                                          email IN
                                          (
                                              SELECT
                                                  email
                                                  FROM
                                                      utilisateurs.t_roles
                                                  GROUP BY email
                                                  HAVING
                                                          count(*)
                                                          > 1)))

;


UPDATE utilisateurs.t_roles
SET
    champs_addi = t2.champs_addi
    FROM
        utilisateurs.t_roles t2
    WHERE
          t2.champs_addi #>> '{email}' = t_roles.email
      AND t_roles.identifiant IS NOT NULL
;

UPDATE gn_synthese.synthese
SET
    id_digitiser = new_id_role
    FROM
        (
            SELECT
                t_roles.id_role AS new_id_role
              , t2.id_role      AS old_id_role
              , t_roles.email   AS new_email
              , t2.email        AS old_email
                FROM
                    utilisateurs.t_roles
                        JOIN
                        (SELECT id_role, email FROM utilisateurs.t_roles WHERE identifiant IS NULL) t2
                        ON t_roles.email = t2.email
                            AND t_roles.identifiant IS NOT NULL) t
    WHERE
        id_digitiser = old_id_role
;


SELECT
    t_roles.id_role AS new_id_role
  , t2.id_role      AS old_id_role
  , t_roles.email   AS new_email
  , t2.email        AS old_email
    FROM
        utilisateurs.t_roles
            JOIN
            (SELECT id_role, email FROM utilisateurs.t_roles WHERE identifiant IS NULL) t2 ON t_roles.email = t2.email
                AND t_roles.identifiant IS NOT NULL
;

SELECT
    jsonb_pretty(champs_addi)
  , champs_addi #>> '{email}'
    FROM
        utilisateurs.t_roles
    WHERE
        champs_addi IS NOT NULL
    LIMIT 1
;
