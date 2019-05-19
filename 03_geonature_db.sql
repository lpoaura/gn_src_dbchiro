/* Integration scripts in a geonature database (populate synthese table) */


create table src_dbchiro.cor_sp_dbchiro_taxref (
    id           serial primary key,
    idsp_dbchiro integer references src_dbchiro.species(id),
    cdnom_taxref integer references taxonomie.taxref(cd_nom)
)
;

/* TODO: improve matching for non-true taxa (genus, class, order)  */
/* INFO; this is just a simple draft */

insert into src_dbchiro.cor_sp_dbchiro_taxref(idsp_dbchiro,
                                              cdnom_taxref)
select species.id, taxref.cd_nom
from species
         left join taxonomie.taxref on case when species.sp_true
                                                then species.sci_name = taxref.lb_nom
                                            else split_part(sci_name, ' ', 1) = taxref.lb_nom end
;

create or replace function update_synthesis_from_dbchiro() returns trigger as
$$
declare
    the_cdnom     varchar(20);
    the_geom      geometry;
    the_placename varchar(250);
begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from gn_synthese.synthese
        where uuid = OLD.uuid;
        if not FOUND
        then
            return null;
        end if;
        return old;

    elsif
        (TG_OP = 'UPDATE' or TG_OP = 'INSERT')
    then
        select cdnom_taxref into the_cdnom
        from src_dbchiro.cor_sp_dbchiro_taxref
        where new.id_codesp = cor_sp_dbchiro_taxref.idsp_dbchiro;
        /* execute update or insert with declared variables */
        if (TG_OP = 'UPDATE')
        then
            -- Updating or inserting data when JSON data is updated
            update gn_synthese.synthese
            set
                -- TODO, write fields update
                where uuid = OLD.uuid;
            if not FOUND
            then
                -- Inserting data in new row, usually after table re-creation
                insert into gn_synthese.synthese(id_synthese, unique_id_sinp, unique_id_sinp_grp, id_source, id_module,
                                                 entity_source_pk_value, id_dataset, id_nomenclature_geo_object_nature,
                                                 id_nomenclature_grp_typ, id_nomenclature_obs_meth,
                                                 id_nomenclature_obs_technique, id_nomenclature_bio_status,
                                                 id_nomenclature_bio_condition, id_nomenclature_naturalness,
                                                 id_nomenclature_exist_proof, id_nomenclature_valid_status,
                                                 id_nomenclature_diffusion_level, id_nomenclature_life_stage,
                                                 id_nomenclature_sex, id_nomenclature_obj_count,
                                                 id_nomenclature_type_count, id_nomenclature_sensitivity,
                                                 id_nomenclature_observation_status, id_nomenclature_blurring,
                                                 id_nomenclature_source_status, id_nomenclature_info_geo_type,
                                                 count_min, count_max, cd_nom, nom_cite, meta_v_taxref,
                                                 sample_number_proof, digital_proof, non_digital_proof, altitude_min,
                                                 altitude_max, the_geom_4326, the_geom_point, the_geom_local, date_min,
                                                 date_max, validator, validation_comment, observers, determiner,
                                                 id_digitiser, id_nomenclature_determination_method, comment_context,
                                                 comment_description, meta_validation_date, meta_create_date,
                                                 meta_update_date, last_action)
                values (
                    -- TODO, write params fields
                );
            end if;
            return NEW;
        elsif
            (TG_OP = 'INSERT')
        then
-- Inserting row when raw data is inserted
            insert into gn_synthese.synthese(id_synthese, unique_id_sinp, unique_id_sinp_grp, id_source, id_module,
                                             entity_source_pk_value, id_dataset, id_nomenclature_geo_object_nature,
                                             id_nomenclature_grp_typ, id_nomenclature_obs_meth,
                                             id_nomenclature_obs_technique, id_nomenclature_bio_status,
                                             id_nomenclature_bio_condition, id_nomenclature_naturalness,
                                             id_nomenclature_exist_proof, id_nomenclature_valid_status,
                                             id_nomenclature_diffusion_level, id_nomenclature_life_stage,
                                             id_nomenclature_sex, id_nomenclature_obj_count,
                                             id_nomenclature_type_count, id_nomenclature_sensitivity,
                                             id_nomenclature_observation_status, id_nomenclature_blurring,
                                             id_nomenclature_source_status, id_nomenclature_info_geo_type,
                                             count_min, count_max, cd_nom, nom_cite, meta_v_taxref,
                                             sample_number_proof, digital_proof, non_digital_proof, altitude_min,
                                             altitude_max, the_geom_4326, the_geom_point, the_geom_local, date_min,
                                             date_max, validator, validation_comment, observers, determiner,
                                             id_digitiser, id_nomenclature_determination_method, comment_context,
                                             comment_description, meta_validation_date, meta_create_date,
                                             meta_update_date, last_action)
            values (
                -- TODO, write params fields
            );
            return new;
        end if;
    end if;
end;
$$
    language plpgsql
;



