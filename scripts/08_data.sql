INSERT INTO
    gn_commons.t_parameters(id_organism, parameter_name, parameter_desc, parameter_value, parameter_extra_value)
    VALUES
        (0, 'dbchiro_default_af','Cadre d''acquisition par défaut pour les données issues de dbChiroWeb', '<UNCLASSIFIED> from dbChiro', NULL);
;

select * from gn_commons.t_parameters;