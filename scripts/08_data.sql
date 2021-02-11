INSERT INTO
    gn_commons.t_parameters(id_organism, parameter_name, parameter_desc, parameter_value, parameter_extra_value)
    VALUES
        ( 0
        , 'dbchiro_default_af_uuid'
        , 'Cadre d''acquisition par défaut pour les données issues de dbChiroWeb'
        , '<UNCLASSIFIED> from dbChiro'
        , NULL)
      , ( 0
        , 'dbchiro_default_dataset_shortname'
        , 'Jeu de données par défaut pour les données issues de dbChiroWeb'
        , 'OpportunisticDbChiroData'
        , NULL)
ON CONFLICT (id_organism, parameter_name)
    DO NOTHING
;

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
            now()::DATE))                               AS id_acquisition_framework
  , uuid_generate_v4()                                  AS unique_dataset_id
  , 'Données oppportunistes dbChiro'                    AS dataset_name
  , gn_commons.get_default_parameter(
            'dbchiro_default_dataset_shortname')                  AS dataset_shortname
  , 'Jeu de données par défault des données dbChiroWeb' AS dataset_desc
  , FALSE                                               AS marine_domain
  , TRUE                                                AS terrestrial_domain
  , now()                                               AS meta_create_date
  , now()                                               AS meta_update_date
ON CONFLICT DO NOTHING
;

