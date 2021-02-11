BEGIN
;

SET ROLE geonature
;

DELETE
    FROM
        src_lpodatas.t_c_synthese_extended
    WHERE
            id_synthese IN (SELECT
                                id_synthese
                                FROM
                                    gn_synthese.synthese
                                WHERE
                                        id_source = (SELECT
                                                         id_source
                                                         FROM
                                                             gn_synthese.t_sources
                                                         WHERE
                                                             name_source LIKE 'dbChiroGCRA'))
;

DELETE
    FROM
        gn_synthese.synthese
    WHERE
            id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source LIKE 'dbChiroGCRA')
;

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
SELECT DISTINCT
    ss.uuid                                                                AS unique_id_sinp
--   , ses.uuid                                                               AS unique_id_sinp_grp
  , NULL ::UUID                                                            AS unique_id_sinp_grp
  , source.id_source                                                       AS id_source
  , NULL::INT                                                              AS id_module
  , ss.id_sighting                                                         AS entity_source_pk_value
  , dataset.id_dataset                                                     AS id_dataset
  , ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'In')             AS id_nomenclature_geo_object_nature
  , ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'NSP')                AS id_nomenclature_grp_typ
  , CASE
        WHEN c2.code ILIKE 'v%' THEN ref_nomenclatures.get_id_nomenclature('METH_OBS', '0')
        WHEN c2.code ILIKE 'te' THEN ref_nomenclatures.get_id_nomenclature('METH_OBS', '20')
        WHEN c2.code ILIKE 'du' THEN ref_nomenclatures.get_id_nomenclature('METH_OBS', '3')
        ELSE ref_nomenclatures.get_id_nomenclature('METH_OBS', '21')
        END                                                                AS id_nomenclature_obs_meth
  , gn_synthese.get_default_nomenclature_value('TECHNIQUE_OBS')            AS id_nomenclature_obs_technique
  , CASE
        /* Cas des colonie de reproduction > Reproduction */
        WHEN ss.breed_colo IS TRUE
            THEN
            ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '3')
        ELSE
            gn_synthese.get_default_nomenclature_value('STATUT_BIO')
        END                                                                AS id_nomenclature_bio_status
  , ref_nomenclatures.get_id_nomenclature('ETA_BIO', '0')
                                                                           AS id_nomenclature_bio_condition
  , ref_nomenclatures.get_id_nomenclature('NATURALITE', '1')
                                                                           AS id_nomenclature_naturalness
  , ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', 'NSP')           AS id_nomenclature_exist_proof
  , CASE
        WHEN ss.is_doubtful
            THEN
            ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '3')
        ELSE ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '2')
        END                                                                AS id_nomenclature_valid_status
  , ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '5')               AS id_nomenclature_diffusion_level
  , ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0')                AS id_nomenclature_life_stage
  , ref_nomenclatures.get_id_nomenclature('SEXE', '0')                     AS id_nomenclature_sex
  , ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND')              AS id_nomenclature_obj_count
  , ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP')              AS id_nomenclature_type_count
  , ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0')              AS id_nomenclature_sensitivity
  , CASE
        WHEN total_count = 0
            THEN
            ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'No')
        ELSE ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr') END AS id_nomenclature_observation_status
  , ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON')               AS id_nomenclature_blurring
  , ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'NSP')          AS id_nomenclature_source_status
  , ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1')              AS id_nomenclature_info_geo_type
  , total_count                                                            AS count_min
  , total_count                                                            AS count_max
  , cor_tx.cdnom_taxref                                                    AS cd_nom
  , ds.common_name_fr                                                      AS nom_cite
  , 11                                                                     AS meta_v_taxref
  , NULL                                                                   AS sample_number_proof
  , NULL                                                                   AS digital_proof
  , NULL                                                                   AS non_digital_proof
  , s2.altitude                                                            AS altitude_min
  , s2.altitude                                                            AS altitude_max
  , st_transform(s2.geom, 4326)                                            AS the_geom_4326
  , st_transform(s2.geom, 4326)                                            AS the_geom_point
  , st_transform(s2.geom, 2154)                                            AS the_geom_local
  , ses.date_start                                                         AS date_min
  , coalesce(ses.date_end, ses.date_start)                                 AS date_max
  , NULL                                                                   AS validator
  , NULL                                                                   AS validation_comment
  , upper(a.last_name) || ' ' || a.first_name                              AS observers
  , upper(a.last_name) || ' ' || a.first_name                              AS determiner
  , NULL ::INT                                                             AS id_digitiser
  , NULL ::INT                                                             AS id_nomenclature_determination_method
  , NULL                                                                   AS comment_context
  , ss.comment                                                             AS comment_description
  , NULL::TIMESTAMP                                                        AS meta_validation_date
  , ss.timestamp_create                                                    AS meta_create_date
  , ss.timestamp_update                                                    AS meta_update_date
  , 'I'                                                                    AS last_action
    FROM
        src_dbchirogcra.sights_sighting ss
            LEFT JOIN src_dbchirogcra.dicts_specie ds ON ss.codesp_id = ds.id
            LEFT JOIN src_dbchirogcra.sights_session ses ON ss.session_id = ses.id_session
            LEFT JOIN src_dbchirogcra.sights_session_other_observer sos ON sos.session_id = ses.id_session
            LEFT JOIN src_dbchirogcra.accounts_profile a ON ses.main_observer_id = a.id
            LEFT JOIN src_dbchirogcra.accounts_profile a2 ON sos.profile_id = a2.id
            LEFT JOIN src_dbchirogcra.sights_place s2 ON ses.place_id = s2.id_place
            LEFT JOIN src_dbchirogcra.dicts_typeplace typeplace ON s2.type_id = typeplace.id
            LEFT JOIN src_dbchirogcra.dicts_contact c2 ON ses.contact_id = c2.id
            LEFT JOIN src_dbchirogcra.geodata_municipality m2 ON s2.municipality_id = m2.id
            LEFT JOIN src_dbchirogcra.sights_countdetail scd ON ss.id_sighting = scd.sighting_id
            --  jointure pour récupérer les uuid
--             LEFT JOIN src_lpodatas.observations obs ON obs.source_id_data = ss.id_sighting
            LEFT JOIN src_dbchiro.cor_sp_dbchiro_taxref cor_tx ON cor_tx.idsp_dbchiro = ds.id
      , (SELECT id_source FROM gn_synthese.t_sources WHERE name_source LIKE 'dbChiroGCRA') AS source
      , (SELECT id_dataset FROM gn_meta.t_datasets WHERE dataset_shortname LIKE 'Dbchiro') AS dataset
    WHERE
          cor_tx.cdnom_taxref IS NOT NULL
      AND ss.comment NOT ILIKE '%@VN%'
--       AND ss.timestamp_update >= '2020-09-07' and ss.timestamp_update < '2020-11-25'
    ORDER BY
        ses.date_start DESC
;


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
SELECT
    id_synthese                                                                                 AS id_synthese
  , dicts_specie.id                                                                             AS id_sp_source
  , 'Chauves-souris'                                                                            AS taxo_group
  , dicts_specie.sp_true                                                                        AS taxo_real
  , dicts_specie.common_name_fr                                                                 AS common_name
  , encode(hmac(accounts_profile.last_name || ' ' || accounts_profile.first_name, 'cyifoE!A5r', 'sha1'),
           'hex')                                                                               AS pseudo_observer_uid
  , sights_sighting.breed_colo                                                                  AS bat_breed_colo
  , sights_place.is_gite                                                                        AS bat_is_gite
  , sights_sighting.period                                                                      AS bat_period
  , extract(YEAR FROM sights_session.date_start)                                                AS date_year
  , coalesce(coalesce(sights_session.is_confidential, coalesce(sights_place.is_hidden, FALSE))) AS export_excluded
  , management_study.name                                                                       AS study
  , dicts_placeprecision.descr                                                                  AS geo_accuracy
  , sights_place.id_place                                                                       AS id_place
  , sights_place.name                                                                           AS place
  , NOT sights_sighting.is_doubtful                                                             AS is_valid
    FROM
        src_dbchirogcra.sights_sighting
            JOIN gn_synthese.synthese ON sights_sighting.id_sighting = synthese.entity_source_pk_value::INT
            JOIN src_dbchirogcra.dicts_specie ON sights_sighting.codesp_id = dicts_specie.id
            JOIN src_dbchirogcra.sights_session ON sights_sighting.session_id = sights_session.id_session
            LEFT JOIN src_dbchirogcra.management_study ON sights_session.study_id = management_study.id_study
            JOIN src_dbchirogcra.sights_place ON sights_session.place_id = sights_place.id_place
            JOIN src_dbchirogcra.accounts_profile ON sights_session.main_observer_id = accounts_profile.id
            JOIN src_dbchirogcra.dicts_placeprecision ON sights_place.precision_id = dicts_placeprecision.id
    WHERE
            synthese.id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source LIKE 'dbChiroGCRA')
;

COMMIT
;
