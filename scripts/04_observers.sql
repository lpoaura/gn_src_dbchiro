/*
  Manage observers from VisioNature observers datas
*/

/* Fonction to create observers if not already registered */

DROP FUNCTION IF EXISTS src_dbchirogcra.fct_c_create_geonature_observer_from_dbchiro() CASCADE
;

CREATE OR REPLACE FUNCTION src_dbchirogcra.fct_c_create_geonature_observer_from_dbchiro() RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO
        utilisateurs.t_roles(nom_role, prenom_role, email, active, date_insert, date_update)
        VALUES
        (new.last_name, new.first_name, new.email, FALSE, new.timestamp_create, new.timestamp_update)
    ON CONFLICT (email)
        DO UPDATE SET
        (nom_role, prenom_role, date_update) = (new.last_name, new.first_name, new.timestamp_update);
    RAISE NOTICE '%', new;
    RETURN new;
END
$$
;

COMMENT ON FUNCTION src_dbchirogcra.fct_c_create_geonature_observer_from_dbchiro() IS 'Fonction trigger pour générer les observateurs GeoNature depuis dbChiro'
;

DROP TRIGGER IF EXISTS tri_c_upsert_observer ON src_dbchirogcra.accounts_profile
;

CREATE TRIGGER tri_c_upsert_observer
    AFTER INSERT OR UPDATE
    ON src_dbchirogcra.accounts_profile
    FOR EACH ROW
EXECUTE PROCEDURE src_dbchirogcra.fct_c_create_geonature_observer_from_dbchiro()
;

CREATE UNIQUE INDEX IF NOT EXISTS i_uniq_roles_email ON utilisateurs.t_roles (email)
;

CREATE UNIQUE INDEX IF NOT EXISTS i_uniq_roles_uuid_role ON utilisateurs.t_roles (uuid_role)
;


/* Function that returns id_role from VisioNature user universal id */

DROP FUNCTION IF EXISTS src_dbchirogcra.fct_c_get_id_role_from_dbchiro(_id INT)
;

CREATE FUNCTION src_dbchirogcra.fct_c_get_id_role_from_dbchiro(_id INT) RETURNS INT
AS
$$
DECLARE
    theroleid INT ;
BEGIN
    SELECT
        id_role
        INTO theroleid
        FROM
            utilisateurs.t_roles
                JOIN src_dbchirogcra.accounts_profile ON accounts_profile.email = t_roles.email
        WHERE
            accounts_profile.id = _id;
    RETURN theroleid;
END
$$
    LANGUAGE plpgsql
;

COMMENT ON FUNCTION src_dbchirogcra.fct_c_get_id_role_from_dbchiro(_id INT) IS 'Retourne un id_role à partir d''un id_universal de visionature'
;
