/* Peuplement auto de la synthèse étendue LPO */

/* Générer les sources si absentes */

DROP TRIGGER IF EXISTS tri_c_upsert_dbchiro_observation_to_geonature ON src_dbchirogcra.sights_sighting
;

DROP FUNCTION IF EXISTS src_dbchirogcra.fct_tri_c_upsert_dbchiro_observation_to_geonature() CASCADE
;

CREATE OR REPLACE FUNCTION src_dbchirogcra.fct_tri_c_upsert_dbchiro_observation_to_geonature() RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    the_record      RECORD;
    the_id_synthese INTEGER;
BEGIN

    SELECT
        r.*
        INTO the_record
        FROM
            (WITH
                 obs AS (SELECT
                             ss.*
                           , taxref.lb_nom
                             FROM
                                 src_dbchirogcra.sights_sighting ss
                                     JOIN src_dbchirogcra.dicts_specie ds ON ss.codesp_id = ds.id
                                     JOIN src_dbchirogcra.cor_sp_dbchiro_taxref cor_tx ON cor_tx.idsp_dbchiro = ds.id
                                     JOIN taxonomie.taxref ON cor_tx.cdnom_taxref = taxref.cd_nom
                             WHERE
                                   cor_tx.cdnom_taxref IS NOT NULL
                               AND ss.comment NOT ILIKE '%@VN%'
                               AND ss.id_sighting = new.id_sighting)
                 /*  , sobs AS (SELECT
                                  ss.id_sighting
                                , string_agg(upper(a.last_name) || ' ' || a.first_name, ', ') AS observers
                                  FROM
                                      src_dbchirogcra.sights_sighting ss
                                          JOIN src_dbchirogcra.dicts_specie ds ON ss.codesp_id = ds.id
                                          JOIN src_dbchirogcra.sights_session ses ON ss.session_id = ses.id_session
                                          LEFT JOIN src_dbchirogcra.sights_session_other_observer sos
                                                    ON sos.session_id = ses.id_session
                                          JOIN src_dbchirogcra.accounts_profile a ON ses.main_observer_id = a.id
                                          LEFT JOIN src_dbchirogcra.accounts_profile a2 ON sos.profile_id = a2.id
                                  GROUP BY ss.id_sighting)*/
             SELECT DISTINCT
                 obs.uuid                                                                AS unique_id_sinp
               , ses.uuid                                                                AS unique_id_sinp_grp
               , source.id_source                                                        AS id_source
               , NULL::INT                                                               AS id_module
               , obs.id_sighting                                                         AS entity_source_pk_value
               , src_dbchirogcra.fct_c_get_dataset_from_id_study(ses.study_id)           AS id_dataset
               , ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'In')              AS id_nomenclature_geo_object_nature
               , ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'NSP')                 AS id_nomenclature_grp_typ
               , CASE
                     WHEN c2.code ILIKE 'v%' THEN ref_nomenclatures.get_id_nomenclature('METH_OBS', '0')
                     WHEN c2.code ILIKE 'te' THEN ref_nomenclatures.get_id_nomenclature('METH_OBS', '20')
                     WHEN c2.code ILIKE 'du' THEN ref_nomenclatures.get_id_nomenclature('METH_OBS', '3')
                     ELSE ref_nomenclatures.get_id_nomenclature('METH_OBS', '21')
                     END                                                                 AS id_nomenclature_obs_meth
               , gn_synthese.get_default_nomenclature_value('TECHNIQUE_OBS')             AS id_nomenclature_obs_technique
               , CASE
                     /* Cas des colonie de reproduction > Reproduction */
                     WHEN obs.breed_colo IS TRUE
                         THEN
                         ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '3')
                     ELSE
                         gn_synthese.get_default_nomenclature_value('STATUT_BIO')
                     END                                                                 AS id_nomenclature_bio_status
               , ref_nomenclatures.get_id_nomenclature('ETA_BIO', '0')
                                                                                         AS id_nomenclature_bio_condition
               , ref_nomenclatures.get_id_nomenclature('NATURALITE', '1')
                                                                                         AS id_nomenclature_naturalness
               , ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', 'NSP')            AS id_nomenclature_exist_proof
               , CASE
                     WHEN obs.is_doubtful
                         THEN
                         ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '3')
                     ELSE ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '2')
                     END                                                                 AS id_nomenclature_valid_status
               , ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '5')                AS id_nomenclature_diffusion_level
               , ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0')                 AS id_nomenclature_life_stage
               , ref_nomenclatures.get_id_nomenclature('SEXE', '0')                      AS id_nomenclature_sex
               , ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND')               AS id_nomenclature_obj_count
               , ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP')               AS id_nomenclature_type_count
               , ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0')               AS id_nomenclature_sensitivity
               , CASE
                     WHEN total_count = 0
                         THEN
                         ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'No')
                     ELSE ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr') END  AS id_nomenclature_observation_status
               , ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON')                AS id_nomenclature_blurring
               , ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'NSP')           AS id_nomenclature_source_status
               , ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1')               AS id_nomenclature_info_geo_type
               , total_count                                                             AS count_min
               , total_count                                                             AS count_max
               , cor_tx.cdnom_taxref                                                     AS cd_nom
               , coalesce(ds.common_name_fr, obs.lb_nom)                                 AS nom_cite
               , 11                                                                      AS meta_v_taxref
               , NULL                                                                    AS sample_number_proof
               , NULL                                                                    AS digital_proof
               , NULL                                                                    AS non_digital_proof
               , spl.altitude                                                            AS altitude_min
               , spl.altitude                                                            AS altitude_max
               , st_transform(spl.geom, 4326)                                            AS the_geom_4326
               , st_transform(spl.geom, 4326)                                            AS the_geom_point
               , st_transform(spl.geom, 2154)                                            AS the_geom_local
               , ses.date_start                                                          AS date_min
               , coalesce(ses.date_end, ses.date_start)                                  AS date_max
               , NULL                                                                    AS validator
               , NULL                                                                    AS validation_comment
               , upper(a.last_name) || ' ' || a.first_name                               AS observers
/*               , CASE
                     WHEN sobs.observers IS NOT NULL THEN
                         upper(a.last_name) || ' ' || a.first_name || ', ' || sobs.observers
                     ELSE upper(a.last_name) || ' ' || a.first_name
                     END                                                                 AS observers*/
               , upper(a.last_name) || ' ' || a.first_name                               AS determiner
               , src_dbchirogcra.fct_c_get_id_role_from_dbchiro(a.id)                    AS id_digitiser
               , NULL ::INT                                                              AS id_nomenclature_determination_method
               , NULL                                                                    AS comment_context
               , obs.comment                                                             AS comment_description
               , NULL::TIMESTAMP                                                         AS meta_validation_date
               , obs.timestamp_create                                                    AS meta_create_date
               , obs.timestamp_update                                                    AS meta_update_date
                 -- Extended synthese part
               , ds.id                                                                   AS id_sp_source
               , 'Chauves-souris'                                                        AS taxo_group
               , ds.sp_true                                                              AS taxo_real
               , ds.common_name_fr                                                       AS common_name
               , encode(hmac(a.last_name || ' ' || a.first_name, 'cyifoE!A5r', 'sha1'),
                        'hex')                                                           AS pseudo_observer_uid
               , obs.breed_colo                                                          AS bat_breed_colo
               , spl.is_gite                                                             AS bat_is_gite
               , obs.period                                                              AS bat_period
               , extract(YEAR FROM ses.date_start)                                       AS date_year
               , coalesce(coalesce(ses.is_confidential, coalesce(spl.is_hidden, FALSE))) AS export_excluded
               , mst.name                                                                AS study
               , dplp.descr                                                              AS geo_accuracy
               , spl.id_place                                                            AS id_place
               , spl.name                                                                AS place
               , NOT obs.is_doubtful                                                     AS is_valid
                 FROM
                     obs
                         JOIN src_dbchirogcra.dicts_specie ds ON obs.codesp_id = ds.id
                         JOIN src_dbchirogcra.sights_session ses ON obs.session_id = ses.id_session
--                          LEFT JOIN sobs ON sobs.id_sighting = obs.id_sighting
                         JOIN src_dbchirogcra.accounts_profile a ON ses.main_observer_id = a.id
                         LEFT JOIN src_dbchirogcra.sights_place spl ON ses.place_id = spl.id_place
                         LEFT JOIN src_dbchirogcra.dicts_typeplace typeplace ON spl.type_id = typeplace.id
                         LEFT JOIN src_dbchirogcra.dicts_placeprecision dplp ON spl.precision_id = dplp.id
                         LEFT JOIN src_dbchirogcra.dicts_contact c2 ON ses.contact_id = c2.id
                         LEFT JOIN src_dbchirogcra.geodata_municipality m2 ON spl.municipality_id = m2.id
                         LEFT JOIN src_dbchirogcra.sights_countdetail scd ON obs.id_sighting = scd.sighting_id
                         LEFT JOIN src_dbchirogcra.cor_sp_dbchiro_taxref cor_tx ON cor_tx.idsp_dbchiro = ds.id
                         LEFT JOIN src_dbchirogcra.management_study mst ON ses.study_id = mst.id_study
                   , (SELECT id_source FROM gn_synthese.t_sources WHERE name_source LIKE 'dbChiroGCRA') AS source
            ) AS r;
    IF found THEN
        RAISE NOTICE '<fct_tri_c_upsert_dbchiro_observation_to_geonature> UPSERT sighting %', new.id_sighting;
        INSERT INTO
            gn_synthese.synthese( unique_id_sinp
                                , unique_id_sinp_grp
                                , id_source
                                , id_module
                                , entity_source_pk_value
                                , id_dataset
                                , id_nomenclature_geo_object_nature
                                , id_nomenclature_grp_typ
                                , id_nomenclature_obs_meth
                                , id_nomenclature_obs_technique
                                , id_nomenclature_bio_status
                                , id_nomenclature_bio_condition
                                , id_nomenclature_naturalness
                                , id_nomenclature_exist_proof
                                , id_nomenclature_valid_status
                                , id_nomenclature_diffusion_level
                                , id_nomenclature_life_stage
                                , id_nomenclature_sex
                                , id_nomenclature_obj_count
                                , id_nomenclature_type_count
                                , id_nomenclature_sensitivity
                                , id_nomenclature_observation_status
                                , id_nomenclature_blurring
                                , id_nomenclature_source_status
                                , id_nomenclature_info_geo_type
                                , count_min
                                , count_max
                                , cd_nom
                                , nom_cite
                                , meta_v_taxref
                                , sample_number_proof
                                , digital_proof
                                , non_digital_proof
                                , altitude_min
                                , altitude_max
                                , the_geom_4326
                                , the_geom_point
                                , the_geom_local
                                , date_min
                                , date_max
                                , validator
                                , validation_comment
                                , observers
                                , determiner
                                , id_digitiser
                                , id_nomenclature_determination_method
                                , comment_context
                                , comment_description
                                , meta_validation_date
                                , meta_create_date
                                , meta_update_date
                                , last_action)
            VALUES
            ( the_record.unique_id_sinp
            , the_record.unique_id_sinp_grp
            , the_record.id_source
            , the_record.id_module
            , the_record.entity_source_pk_value
            , the_record.id_dataset
            , the_record.id_nomenclature_geo_object_nature
            , the_record.id_nomenclature_grp_typ
            , the_record.id_nomenclature_obs_meth
            , the_record.id_nomenclature_obs_technique
            , the_record.id_nomenclature_bio_status
            , the_record.id_nomenclature_bio_condition
            , the_record.id_nomenclature_naturalness
            , the_record.id_nomenclature_exist_proof
            , the_record.id_nomenclature_valid_status
            , the_record.id_nomenclature_diffusion_level
            , the_record.id_nomenclature_life_stage
            , the_record.id_nomenclature_sex
            , the_record.id_nomenclature_obj_count
            , the_record.id_nomenclature_type_count
            , the_record.id_nomenclature_sensitivity
            , the_record.id_nomenclature_observation_status
            , the_record.id_nomenclature_blurring
            , the_record.id_nomenclature_source_status
            , the_record.id_nomenclature_info_geo_type
            , the_record.count_min
            , the_record.count_max
            , the_record.cd_nom
            , the_record.nom_cite
            , the_record.meta_v_taxref
            , the_record.sample_number_proof
            , the_record.digital_proof
            , the_record.non_digital_proof
            , the_record.altitude_min
            , the_record.altitude_max
            , the_record.the_geom_4326
            , the_record.the_geom_point
            , the_record.the_geom_local
            , the_record.date_min
            , the_record.date_max
            , the_record.validator
            , the_record.validation_comment
            , the_record.observers
            , the_record.determiner
            , the_record.id_digitiser
            , the_record.id_nomenclature_determination_method
            , the_record.comment_context
            , the_record.comment_description
            , the_record.meta_validation_date
            , the_record.meta_create_date
            , the_record.meta_update_date
            , 'I')

        ON CONFLICT ( unique_id_sinp)
            DO UPDATE SET
                          unique_id_sinp_grp=the_record.unique_id_sinp_grp
                        , id_source = the_record.id_source
                        , id_module = the_record.id_module
                        , entity_source_pk_value = the_record.entity_source_pk_value
                        , id_dataset = the_record.id_dataset
                        , id_nomenclature_geo_object_nature = the_record.id_nomenclature_geo_object_nature
                        , id_nomenclature_grp_typ = the_record.id_nomenclature_grp_typ
                        , id_nomenclature_obs_meth = the_record.id_nomenclature_obs_meth
                        , id_nomenclature_obs_technique = the_record.id_nomenclature_obs_technique
                        , id_nomenclature_bio_status = the_record.id_nomenclature_bio_status
                        , id_nomenclature_bio_condition = the_record.id_nomenclature_bio_condition
                        , id_nomenclature_naturalness = the_record.id_nomenclature_naturalness
                        , id_nomenclature_exist_proof = the_record.id_nomenclature_exist_proof
                        , id_nomenclature_valid_status = the_record.id_nomenclature_valid_status
                        , id_nomenclature_diffusion_level = the_record.id_nomenclature_diffusion_level
                        , id_nomenclature_life_stage = the_record.id_nomenclature_life_stage
                        , id_nomenclature_sex = the_record.id_nomenclature_sex
                        , id_nomenclature_obj_count = the_record.id_nomenclature_obj_count
                        , id_nomenclature_type_count = the_record.id_nomenclature_type_count
                        , id_nomenclature_sensitivity = the_record.id_nomenclature_sensitivity
                        , id_nomenclature_observation_status = the_record.id_nomenclature_observation_status
                        , id_nomenclature_blurring = the_record.id_nomenclature_blurring
                        , id_nomenclature_source_status = the_record.id_nomenclature_source_status
                        , id_nomenclature_info_geo_type = the_record.id_nomenclature_info_geo_type
                        , count_min = the_record.count_min
                        , count_max = the_record.count_max
                        , cd_nom = the_record.cd_nom
                        , nom_cite = the_record.nom_cite
                        , meta_v_taxref = the_record.meta_v_taxref
                        , sample_number_proof = the_record.sample_number_proof
                        , digital_proof = the_record.digital_proof
                        , non_digital_proof = the_record.non_digital_proof
                        , altitude_min = the_record.altitude_min
                        , altitude_max = the_record.altitude_max
                        , the_geom_4326 = the_record.the_geom_4326
                        , the_geom_point = the_record.the_geom_point
                        , the_geom_local = the_record.the_geom_local
                        , date_min = the_record.date_min
                        , date_max = the_record.date_max
                        , validator = the_record.validator
                        , validation_comment = the_record.validation_comment
                        , observers = the_record.observers
                        , determiner = the_record.determiner
                        , id_digitiser = the_record.id_digitiser
                        , id_nomenclature_determination_method = the_record.id_nomenclature_determination_method
                        , comment_context = the_record.comment_context
                        , comment_description = the_record.comment_description
                        , meta_validation_date = the_record.meta_validation_date
                        , meta_create_date = the_record.meta_create_date
                        , meta_update_date = the_record.meta_update_date
                        , last_action = 'U'
            RETURNING id_synthese INTO the_id_synthese;

        INSERT INTO
            src_lpodatas.t_c_synthese_extended ( id_synthese
                                               , id_sp_source
                                               , taxo_group
                                               , taxo_real
                                               , common_name
                                               , pseudo_observer_uid
                                               , bat_breed_colo
                                               , bat_is_gite
                                               , bat_period
                                               , date_year
                                               , export_excluded
                                               , project_code
                                               , geo_accuracy
                                               , id_place
                                               , place
                                               , is_valid)
            VALUES
            ( the_id_synthese
            , the_record.id_sp_source
            , the_record.taxo_group
            , the_record.taxo_real
            , the_record.common_name
            , the_record.pseudo_observer_uid
            , the_record.bat_breed_colo
            , the_record.bat_is_gite
            , the_record.bat_period
            , the_record.date_year
            , the_record.export_excluded
            , the_record.study
            , the_record.geo_accuracy
            , the_record.id_place
            , the_record.place
            , the_record.is_valid)
        ON CONFLICT (id_synthese)
            DO UPDATE SET

                          id_sp_source        = the_record.id_sp_source
                        , taxo_group          = the_record.taxo_group
                        , taxo_real           = the_record.taxo_real
                        , common_name         = the_record.common_name
                        , pseudo_observer_uid = the_record.pseudo_observer_uid
                        , bat_breed_colo      = the_record.bat_breed_colo
                        , bat_is_gite         = the_record.bat_is_gite
                        , bat_period          = the_record.bat_period
                        , date_year           = the_record.date_year
                        , export_excluded     = the_record.export_excluded
                        , project_code        = the_record.study
                        , geo_accuracy        = the_record.geo_accuracy
                        , id_place            = the_record.id_place
                        , place               = the_record.place
                        , is_valid            = the_record.is_valid;
    ELSE
        RAISE NOTICE '<fct_tri_c_upsert_dbchiro_observation_to_geonature> sighting % excluded from UPSERT', new.id_sighting;

    END IF;
    RETURN new;
END;
$$
;

ALTER FUNCTION src_dbchirogcra.fct_tri_c_upsert_dbchiro_observation_to_geonature() OWNER TO geonature
;

COMMENT ON FUNCTION src_dbchirogcra.fct_tri_c_upsert_dbchiro_observation_to_geonature() IS 'Trigger function to upsert datas from dbChiro to synthese and custom child table'
;

DROP TRIGGER IF EXISTS fct_tri_c_upsert_dbchiro_observation_to_geonature ON src_dbchirogcra.sights_sighting
;

CREATE TRIGGER fct_tri_c_upsert_dbchiro_observation_to_geonature
    AFTER INSERT OR UPDATE
    ON src_dbchirogcra.sights_sighting
    FOR EACH ROW
EXECUTE PROCEDURE src_dbchirogcra.fct_tri_c_upsert_dbchiro_observation_to_geonature()
;


/* DELETE Trigger */

DROP FUNCTION IF EXISTS src_dbchirogcra.fct_tri_c_delete_dbchiro_observation_from_geonature() CASCADE
;

CREATE OR REPLACE FUNCTION src_dbchirogcra.fct_tri_c_delete_dbchiro_observation_from_geonature() RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    the_id_synthese    INT;
    the_unique_id_sinp UUID;
BEGIN
    RAISE NOTICE '<fct_tri_c_delete_dbchiro_observation_from_geonature> Delete sighting % with uuid %', old.id_sighting, old.uuid;
    SELECT
        id_synthese
        INTO the_id_synthese
        FROM
            gn_synthese.synthese
        WHERE
            unique_id_sinp = old.uuid;

    DELETE FROM src_lpodatas.t_c_synthese_extended WHERE t_c_synthese_extended.id_synthese = the_id_synthese;
    DELETE FROM gn_synthese.synthese WHERE synthese.id_synthese = the_id_synthese;
    IF NOT found
    THEN
        RETURN NULL;
    END IF;
    RETURN old;
END;
$$
;

ALTER FUNCTION src_dbchirogcra.fct_tri_c_delete_dbchiro_observation_from_geonature() OWNER TO geonature
;

COMMENT ON FUNCTION src_dbchirogcra.fct_tri_c_delete_dbchiro_observation_from_geonature() IS 'Trigger function to delete datas from geonature synthese and extended table when DELETE on dbChiro'
;

DROP TRIGGER IF EXISTS tri_c_delete_dbchiro_observation_from_geonature ON src_dbchirogcra.sights_sighting
;
;

CREATE TRIGGER tri_c_delete_dbchiro_observation_from_geonature
    AFTER DELETE
    ON src_dbchirogcra.sights_sighting
    FOR EACH ROW
EXECUTE PROCEDURE src_dbchirogcra.fct_tri_c_delete_dbchiro_observation_from_geonature()
;
