/*
  Manage observers from VisioNature observers datas
*/

/* Fonction to create observers if not already registered */

DROP FUNCTION IF EXISTS src_dbchirogcra.fct_c_create_geonature_observer_from_dbchiro()
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
    RETURN new;
END
$$
;

COMMENT ON FUNCTION  src_dbchirogcra.fct_c_create_geonature_observer_from_dbchiro() IS 'Fonction trigger pour générer les observateurs GeoNature depuis dbChiro'
;

DROP TRIGGER IF EXISTS tri_c_upsert_observer ON src_dbchirogcra.accounts_profile
;

CREATE TRIGGER tri_c_upsert_observer
    AFTER INSERT OR UPDATE
    ON src_dbchirogcra.accounts_profile
    FOR EACH ROW
EXECUTE PROCEDURE src_dbchirogcra.fct_c_create_geonature_observer_from_dbchiro()
;

CREATE UNIQUE INDEX IF NOT EXISTS i_uniq_roles_email ON utilisateurs.t_roles(email);
CREATE UNIQUE INDEX IF NOT EXISTS i_uniq_roles_uuid_role ON utilisateurs.t_roles(uuid_role);
alter table utilisateurs.t_roles

/* Function that returns id_role from VisioNature user universal id */

DROP FUNCTION IF EXISTS src_lpodatas.fct_c_get_id_role_from_visionature_uid(_uid TEXT)
;

CREATE FUNCTION src_lpodatas.fct_c_get_id_role_from_visionature_uid(_uid TEXT) RETURNS INT
AS
$$
DECLARE
    theroleid INT ;
BEGIN
    SELECT id_role INTO theroleid FROM utilisateurs.t_roles WHERE champs_addi ->> 'id_universal' = _uid;
    RETURN theroleid;
END
$$
    LANGUAGE plpgsql
;

COMMENT ON FUNCTION src_lpodatas.fct_c_get_id_role_from_visionature_uid(_uid TEXT) IS 'Retourne un id_role à partir d''un id_universal de visionature'
;


/* TESTS */


-- WITH
--     titem AS
--         (SELECT
--              jsonb_set(item, '{name}', '"test2"') AS item
--              FROM
--                  src_vn_json.observers_json
--              LIMIT 1)
--
-- SELECT
--     src_lpodatas.fct_create_observer_from_visionature(item)
--     FROM
--         titem;


-- WITH
--     titem AS
--         (SELECT
--              jsonb_set(item, '{name}', '"test2"') AS item
--              FROM
--                  src_vn_json.observers_json
--              LIMIT 1)
--
-- SELECT
--     src_lpodatas.fct_get_id_role_from_visionature_uid(item ->> 'id_universal')
--     FROM
--         titem;

/* Trigger pour peupler automatiquement la table t_roles à partir des entrées observateurs de VisioNature*/

DROP TRIGGER IF EXISTS tri_upsert_synthese_extended ON src_vn_json.observers_json
;

DROP FUNCTION IF EXISTS src_lpodatas.fct_tri_c_vn_observers_to_geonature()
;

CREATE OR REPLACE FUNCTION src_lpodatas.fct_tri_c_vn_observers_to_geonature() RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    PERFORM src_lpodatas.fct_c_create_geonature_observer_from_visionature(new.item);
    RETURN new;
END;
$$
;

ALTER FUNCTION src_lpodatas.fct_tri_c_vn_observers_to_geonature() OWNER TO geonature
;

COMMENT ON FUNCTION src_lpodatas.fct_tri_c_vn_observers_to_geonature() IS 'Function de trigger permettant de peupler automatiquement la table des observateurs utilisateurs.t_roles à partir des données VisioNature'
;

CREATE TRIGGER tri_upsert_vn_observers_to_geonature
    AFTER INSERT OR UPDATE
    ON src_vn_json.observers_json
    FOR EACH ROW
EXECUTE PROCEDURE src_lpodatas.fct_tri_c_vn_observers_to_geonature()
;

COMMENT ON TRIGGER tri_upsert_vn_observers_to_geonature ON src_vn_json.observers_json IS 'Trigger permettant de peupler automatiquement la table des observateurs utilisateurs.t_roles à partir des données VisioNature'
