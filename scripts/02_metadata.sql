/* Create a default dataset for new studies */

SET ROLE geonature
;

DROP FUNCTION IF EXISTS src_dbchirogcra.fct_c_get_or_insert_basic_acquisition_framework(_name TEXT, _desc TEXT, _startdate DATE)
;

CREATE OR REPLACE FUNCTION src_dbchirogcra.fct_c_get_or_insert_basic_acquisition_framework(_name TEXT, _desc TEXT, _startdate DATE) RETURNS INTEGER
AS
$$
DECLARE
    the_new_id INT ;
BEGIN
    IF (SELECT
            exists(SELECT
                       1
                       FROM
                           gn_meta.t_acquisition_frameworks
                       WHERE
                           acquisition_framework_name LIKE _name)) THEN
        SELECT
            id_acquisition_framework
            INTO the_new_id
            FROM
                gn_meta.t_acquisition_frameworks
            WHERE
                acquisition_framework_name = _name;
        RAISE NOTICE 'Acquisition framework named % already exists', _name;
    ELSE

        INSERT INTO
            gn_meta.t_acquisition_frameworks( acquisition_framework_name
                                            , acquisition_framework_desc
                                            , acquisition_framework_start_date
                                            , meta_create_date)
            VALUES
                (_name, _desc, _startdate, now())
            RETURNING id_acquisition_framework INTO the_new_id;
        RAISE NOTICE 'Acquisition framework named % inserted with id %', _name, the_new_id;
    END IF;
    RETURN the_new_id;
END
$$
    LANGUAGE plpgsql
;

ALTER FUNCTION src_dbchirogcra.fct_c_get_or_insert_basic_acquisition_framework(_name TEXT, _desc TEXT, _startdate DATE) OWNER TO geonature
;

COMMENT ON FUNCTION src_dbchirogcra.fct_c_get_or_insert_basic_acquisition_framework(_name TEXT, _desc TEXT, _startdate DATE) IS 'function to basically create acquisition framework'
;



/* Function to get id_dataset from id_study */

DROP FUNCTION IF EXISTS src_dbchirogcra.fct_c_get_dataset_from_id_study(_id_study INT)
;

CREATE OR REPLACE FUNCTION src_dbchirogcra.fct_c_get_dataset_from_id_study(_id_study INT) RETURNS INTEGER
AS
$$
DECLARE
    the_id_dataset INT ;
BEGIN
    IF (SELECT
            exists(SELECT 1 FROM
            gn_meta.t_datasets
                JOIN src_dbchirogcra.management_study ON unique_dataset_id = uuid
        WHERE
            id_study = _id_study)) THEN
    SELECT
        id_dataset
        INTO the_id_dataset
        FROM
            gn_meta.t_datasets
                JOIN src_dbchirogcra.management_study ON unique_dataset_id = uuid
        WHERE
            id_study = _id_study;
    ELSE
        SELECT id_dataset INTO the_id_dataset
        FROM
            gn_meta.t_datasets where t_datasets.dataset_shortname like gn_commons.get_default_parameter(
            'dbchiro_default_dataset_shortname') ;
        END IF;
    RETURN the_id_dataset;
END
$$ LANGUAGE plpgsql
;

ALTER FUNCTION src_dbchirogcra.fct_c_get_dataset_from_id_study(_id_study INT) OWNER TO geonature
;

COMMENT ON FUNCTION src_dbchirogcra.fct_c_get_dataset_from_id_study(_id_study INT) IS 'function to basically create acquisition framework'
;

/* New function to get acquisition framework id by name */

DROP FUNCTION IF EXISTS src_dbchirogcra.fct_c_get_id_acquisition_framework_by_name(_name TEXT)
;

CREATE OR REPLACE FUNCTION src_dbchirogcra.fct_c_get_id_acquisition_framework_by_name(_name TEXT) RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    theidacquisitionframework INTEGER;
BEGIN
    --Retrouver l'id du module par son code
    SELECT INTO theidacquisitionframework
        id_acquisition_framework
        FROM
            gn_meta.t_acquisition_frameworks
        WHERE
            acquisition_framework_name ILIKE _name
        LIMIT 1;
    RETURN theidacquisitionframework;
END;
$$
;

ALTER FUNCTION src_dbchirogcra.fct_c_get_id_acquisition_framework_by_name(_name TEXT) OWNER TO geonature
;

COMMENT ON FUNCTION src_dbchirogcra.fct_c_get_id_acquisition_framework_by_name(_name TEXT) IS 'function to get acquisition framework id by name'
;

/* Trigger dbChiro Study > GeoNature Datasets */

CREATE UNIQUE INDEX IF NOT EXISTS i_uniq_dataset_uuid ON gn_meta.t_datasets (unique_dataset_id)
;

CREATE OR REPLACE FUNCTION src_dbchirogcra.fct_tri_c_upsert_dataset() RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO
        gn_meta.t_datasets ( id_acquisition_framework
                           , unique_dataset_id
                           , dataset_name
                           , dataset_shortname
                           , dataset_desc
                           , marine_domain
                           , terrestrial_domain
                           , meta_create_date
                           , meta_update_date)
    SELECT
        (src_dbchirogcra.fct_c_get_or_insert_basic_acquisition_framework(
                gn_commons.get_default_parameter(
                        'dbchiro_default_af'), 'Cadre d''acquisition par défaut pour les données dbChiroWeb',
                now()::DATE)) AS id_acquisition_framework
      , new.uuid              AS unique_dataset_id
      , new.name              AS dataset_name
      , new.name              AS dataset_shortname
      , new.comment           AS dataset_desc
      , FALSE                 AS marine_domain
      , TRUE                  AS terrestrial_domain
      , new.timestamp_create  AS meta_create_date
      , new.timestamp_update  AS meta_update_date
    ON CONFLICT (unique_dataset_id)
        DO UPDATE
        SET
            (dataset_name, dataset_shortname, dataset_desc, meta_update_date) = (new.name, new.name, new.comment, new.timestamp_update);
    RETURN new;
END
$$
;

COMMENT ON FUNCTION src_dbchirogcra.fct_tri_c_upsert_dataset() IS 'Trigger function to upsert datasets from dbChiroweb'
;

DROP TRIGGER IF EXISTS tri_c_upsert_dataset ON src_dbchirogcra.management_study
;

CREATE TRIGGER tri_c_upsert_dataset
    AFTER INSERT OR UPDATE
    ON src_dbchirogcra.management_study
    FOR EACH ROW
EXECUTE PROCEDURE src_dbchirogcra.fct_tri_c_upsert_dataset()
;

/* Trigger dbChiro delete Study > GeoNature Datasets */

DROP FUNCTION IF EXISTS src_dbchirogcra.fct_tri_c_delete_study_from_geonature() CASCADE;
CREATE OR REPLACE FUNCTION src_dbchirogcra.fct_tri_c_delete_study_from_geonature() RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN

    DELETE FROM gn_meta.t_datasets WHERE t_datasets.unique_dataset_id = old.uuid;
    IF NOT found
    THEN
        RETURN NULL;
    END IF;
    RETURN old;
END;
$$;

ALTER FUNCTION src_dbchirogcra.fct_tri_c_delete_study_from_geonature() OWNER TO geonature;

COMMENT ON FUNCTION src_dbchirogcra.fct_tri_c_delete_study_from_geonature() IS 'Trigger function to delete dataset from geonature when delete study';

DROP TRIGGER IF EXISTS tri_c_delete_study_from_geonature ON src_dbchirogcra.management_study;

CREATE TRIGGER tri_c_delete_study_from_geonature
    AFTER DELETE
    ON src_dbchirogcra.management_study
    FOR EACH ROW
EXECUTE PROCEDURE src_dbchirogcra.fct_tri_c_delete_study_from_geonature();
