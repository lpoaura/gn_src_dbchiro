reset role
;

/* Prérequis, extension postgres_fdw */
create extension if not exists postgres_fdw
;

create extension if not exists postgis
;

create extension if not exists "uuid-ossp"
;

/* Création d'un rôle spécifique à cette échange offrant la possibilité, si besoin de restreindre l'accès aux données
   via les fonctions de ROW POLICY */
drop schema share_with_foreigndb1 cascade
;

create schema share_with_foreigndb1
;

grant usage on schema share_with_foreigndb1 to dbchirodbuser
;

grant create on schema share_with_foreigndb1 to dbchirodbuser
;

alter default privileges in schema share_with_foreigndb1 grant all privileges on tables to dbchirodbuser
;


/* Création du serveur distant GeoNature */

drop server if exists foreign_db1 cascade
;

create server foreign_db1 foreign data wrapper postgres_fdw options (host 'foreign_host', dbname 'foreign_dbname', port 'foreign_dbport')
;

create user mapping for dbchirodbuser server foreign_db1 options (user 'dbuser', password 'dbpasswd')
;

grant usage on foreign server foreign_db1 to dbchirodbuser
;

/* Utilisation temporaire du schéma src_dbchiro comme schéma courant */
set search_path = 'src_dbchiro', 'public'
;

set role dbchirodbuser
;

drop foreign table share_with_foreigndb1.sights_place;

import foreign schema src_dbchiro from server foreign_db1 into share_with_foreigndb1
;


/* création des fonctions d'alimentation des tables distantes */

/* INFO: profiles */

create or replace function update_foreign_account_profile() returns trigger as
$$
begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from share_with_foreigndb1.accounts_profile
        where id = OLD.id;
        if not FOUND
        then
            return null;
        end if;
        return old;

    elsif
        (TG_OP = 'UPDATE')
    then
-- Updating or inserting data when JSON data is updated
        update share_with_foreigndb1.accounts_profile
        set id               = NEW.id,
            last_login       = NEW.last_login,
            username         = NEW.username,
            first_name       = NEW.first_name,
            last_name        = NEW.last_name,
            email            = NEW.email,
            is_active        = NEW.is_active,
            date_joined      = NEW.date_joined,
            organism         = NEW.organism,
            home_phone       = NEW.home_phone,
            mobile_phone     = NEW.mobile_phone,
            addr_appt        = NEW.addr_appt,
            addr_building    = NEW.addr_building,
            addr_street      = NEW.addr_street,
            addr_city        = NEW.addr_city,
            addr_city_code   = NEW.addr_city_code,
            addr_dept        = NEW.addr_dept,
            addr_country     = NEW.addr_country,
            comment          = NEW.comment,
            timestamp_create = NEW.timestamp_create,
            timestamp_update = NEW.timestamp_update,
            created_by       = NEW.created_by,
            updated_by       = NEW.updated_by
        where id = OLD.id;
        if not FOUND
        then
            -- Inserting data in new row, usually after table re-creation
            insert into share_with_foreigndb1.accounts_profile(id, last_login, username, first_name, last_name, email,
                                                               is_active, date_joined, organism, home_phone,
                                                               mobile_phone,
                                                               addr_appt, addr_building, addr_street, addr_city,
                                                               addr_city_code,
                                                               addr_dept, addr_country, comment, timestamp_create,
                                                               timestamp_update, created_by, updated_by)
            values (NEW.id,
                    NEW.last_login,
                    NEW.username,
                    NEW.first_name,
                    NEW.last_name,
                    NEW.email,
                    NEW.is_active,
                    NEW.date_joined,
                    NEW.organism,
                    NEW.home_phone,
                    NEW.mobile_phone,
                    NEW.addr_appt,
                    NEW.addr_building,
                    NEW.addr_street,
                    NEW.addr_city,
                    NEW.addr_city_code,
                    NEW.addr_dept,
                    NEW.addr_country,
                    NEW.comment,
                    NEW.timestamp_create,
                    NEW.timestamp_update,
                    NEW.created_by,
                    NEW.updated_by);
        end if;
        return NEW;
    elsif
        (TG_OP = 'INSERT')
    then
-- Inserting row when raw data is inserted
        insert into share_with_foreigndb1.accounts_profile(id, last_login, username, first_name, last_name, email,
                                                           is_active, date_joined, organism, home_phone, mobile_phone,
                                                           addr_appt, addr_building, addr_street, addr_city,
                                                           addr_city_code,
                                                           addr_dept, addr_country, comment, timestamp_create,
                                                           timestamp_update, created_by, updated_by)
        values (NEW.id,
                NEW.last_login,
                NEW.username,
                NEW.first_name,
                NEW.last_name,
                NEW.email,
                NEW.is_active,
                NEW.date_joined,
                NEW.organism,
                NEW.home_phone,
                NEW.mobile_phone,
                NEW.addr_appt,
                NEW.addr_building,
                NEW.addr_street,
                NEW.addr_city,
                NEW.addr_city_code,
                NEW.addr_dept,
                NEW.addr_country,
                NEW.comment,
                NEW.timestamp_create,
                NEW.timestamp_update,
                NEW.created_by,
                NEW.updated_by);
        return new;
    end if;
end;
$$
    language plpgsql
;

drop trigger if exists accounts_to_foreigndb1_trigger on public.accounts_profile
;

create trigger accounts_to_foreigndb1_trigger
    after insert or update or delete
    on public.accounts_profile
    for each row
execute procedure update_foreign_account_profile()
;

-- set role dbchirodbuser;
-- update accounts_profile
-- set addr_appt = addr_appt;

/* info: études */

create or replace function update_foreign_management_study() returns trigger as
$$
begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from share_with_foreigndb1.management_study
        where id_study = OLD.id_study;
        if not FOUND
        then
            return null;
        end if;
        return old;

    elsif
        (TG_OP = 'UPDATE')
    then
-- Updating or inserting data when JSON data is updated
        update share_with_foreigndb1.management_study
        set id_study              = NEW.id_study,
            name                  = NEW.name,
            year                  = NEW.year,
            public_funding        = NEW.public_funding,
            public_report         = NEW.public_report,
            public_raw_data       = NEW.public_raw_data,
            confidential          = NEW.confidential,
            confidential_end_date = NEW.confidential_end_date,
            type_etude            = NEW.type_etude,
            type_espace           = NEW.type_espace,
            comment               = NEW.comment,
            timestamp_create      = NEW.timestamp_create,
            timestamp_update      = NEW.timestamp_update,
            created_by_id         = NEW.created_by_id,
            project_manager_id    = NEW.project_manager_id,
            updated_by_id         = NEW.updated_by_id
        where id_study = OLD.id_study;
        if not FOUND
        then
            -- Inserting data in new row, usually after table re-creation
            insert into share_with_foreigndb1.management_study(id_study, name, year, public_funding, public_report,
                                                               public_raw_data, confidential, confidential_end_date,
                                                               type_etude, type_espace, comment, timestamp_create,
                                                               timestamp_update, created_by_id, project_manager_id,
                                                               updated_by_id)
            values (NEW.id_study,
                    NEW.name,
                    NEW.year,
                    NEW.public_funding,
                    NEW.public_report,
                    NEW.public_raw_data,
                    NEW.confidential,
                    NEW.confidential_end_date,
                    NEW.type_etude,
                    NEW.type_espace,
                    NEW.comment,
                    NEW.timestamp_create,
                    NEW.timestamp_update,
                    NEW.created_by_id,
                    NEW.project_manager_id,
                    NEW.updated_by_id);
        end if;
        return NEW;
    elsif
        (TG_OP = 'INSERT')
    then
-- Inserting row when raw data is inserted
        insert into share_with_foreigndb1.management_study(id_study, name, year, public_funding, public_report,
                                                           public_raw_data, confidential, confidential_end_date,
                                                           type_etude, type_espace, comment, timestamp_create,
                                                           timestamp_update, created_by_id, project_manager_id,
                                                           updated_by_id)
        values (NEW.id_study,
                NEW.name,
                NEW.year,
                NEW.public_funding,
                NEW.public_report,
                NEW.public_raw_data,
                NEW.confidential,
                NEW.confidential_end_date,
                NEW.type_etude,
                NEW.type_espace,
                NEW.comment,
                NEW.timestamp_create,
                NEW.timestamp_update,
                NEW.created_by_id,
                NEW.project_manager_id,
                NEW.updated_by_id);
        return new;
    end if;
end;
$$
    language plpgsql
;

drop trigger if exists study_to_foreigndb1_trigger on public.management_study
;

create trigger study_to_foreigndb1_trigger
    after insert or update or delete
    on public.management_study
    for each row
execute procedure update_foreign_management_study()
;

update management_study
set year = year
;

/* info : especes */

create or replace function update_foreign_dicts_specie() returns trigger as
$$
begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from share_with_foreigndb1.dicts_specie
        where id = OLD.id;
        if not FOUND
        then
            return null;
        end if;
        return old;

    elsif
        (TG_OP = 'UPDATE')
    then
-- Updating or inserting data when JSON data is updated
        update share_with_foreigndb1.dicts_specie
        set id              = NEW.id,
            sys_order       = NEW.sys_order,
            codesp          = NEW.codesp,
            sp_true         = NEW.sp_true,
            sci_name        = NEW.sci_name,
            full_name       = NEW.full_name,
            common_name_fr  = NEW.common_name_fr,
            common_name_eng = NEW.common_name_eng
        where id = OLD.id;
        if not FOUND
        then
            -- Inserting data in new row, usually after table re-creation
            insert into share_with_foreigndb1.dicts_specie(id, sys_order, codesp, sp_true, sci_name, full_name,
                                                           common_name_fr, common_name_eng)
            values (NEW.id,
                    NEW.sys_order,
                    NEW.codesp,
                    NEW.sp_true,
                    NEW.sci_name,
                    NEW.full_name,
                    NEW.common_name_fr,
                    NEW.common_name_eng);
        end if;
        return NEW;
    elsif
        (TG_OP = 'INSERT')
    then
-- Inserting row when raw data is inserted
        insert into share_with_foreigndb1.dicts_specie(id, sys_order, codesp, sp_true, sci_name, full_name,
                                                       common_name_fr, common_name_eng)
        values (NEW.id,
                NEW.sys_order,
                NEW.codesp,
                NEW.sp_true,
                NEW.sci_name,
                NEW.full_name,
                NEW.common_name_fr,
                NEW.common_name_eng);
        return new;
    end if;
end;
$$
    language plpgsql
;

drop trigger if exists specie_to_foreigndb1_trigger on public.dicts_specie
;

create trigger specie_to_foreigndb1_trigger
    after insert or update or delete
    on public.dicts_specie
    for each row
execute procedure update_foreign_dicts_specie()
;

update dicts_specie
set sys_order = sys_order
;

/* info: Localités */

set role dbchirodbuser
;

create or replace function update_foreign_sights_place() returns trigger as
$$
declare
    the_category_type varchar(50);
    the_type_code     varchar(10);
    the_domain        varchar(50);
    the_landcover     varchar(250);
    the_municipality  varchar(10);
    the_precision     varchar(50);
    the_territory     varchar(50);
begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from share_with_foreigndb1.sights_place
        where id_place = OLD.id_place;
        if not FOUND
        then
            return null;
        end if;
        return old;

    elsif
        (TG_OP = 'UPDATE' or TG_OP = 'INSERT')
    then
        /* populate declarde variables */
        select into the_category_type category from public.dicts_typeplace where new.type_id = dicts_typeplace.id;
        select into the_type_code code from public.dicts_typeplace where new.type_id = dicts_typeplace.id;
        select into the_domain domain from public.dicts_propertydomain where new.domain_id = dicts_propertydomain.id;
        select into the_landcover dicts_landcoverclc.label_lev3
        from public.geodata_landcover
                 join public.dicts_landcoverclc on geodata_landcover.code_id = dicts_landcoverclc.code_lev3
        where new.landcover_id = geodata_landcover.id;
        select into the_municipality code
        from public.geodata_municipality
        where new.municipality_id = geodata_municipality.id;
        select into the_precision code
        from public.dicts_placeprecision
        where new.precision_id = dicts_placeprecision.id;
        select into the_territory geodata_territory.name
        from public.geodata_territory
        where new.territory_id = geodata_territory.id;
        /* execute update or insert with declared variables */
        if (TG_OP = 'UPDATE')
        then
            -- Updating or inserting data when JSON data is updated
            update share_with_foreigndb1.sights_place
            set id_place           = NEW.id_place,
                name               = NEW.name,
                is_hidden          = NEW.is_hidden,
                is_gite            = NEW.is_gite,
                is_managed         = NEW.is_managed,
                proprietary        = NEW.proprietary,
                convention         = NEW.convention,
                altitude           = NEW.altitude,
                id_bdcavite        = NEW.id_bdcavite,
                comment            = NEW.comment,
                telemetric_crossaz = NEW.telemetric_crossaz,
                landcover          = the_landcover,
                municipality       = the_municipality,
                precision          = the_precision,
                territory          = the_territory,
                type_category      = the_category_type,
                type               = the_type_code,
                geom               = st_transform(NEW.geom, 2154),
                timestamp_create   = NEW.timestamp_create,
                timestamp_update   = NEW.timestamp_update,
                created_by_id      = NEW.created_by_id,
                updated_by_id      = NEW.updated_by_id
            where id_place = OLD.id_place;
            if not FOUND
            then
                -- Inserting data in new row, usually after table re-creation
                insert into share_with_foreigndb1.sights_place(id_place,
                                                               name,
                                                               is_hidden,
                                                               is_gite,
                                                               is_managed,
                                                               proprietary,
                                                               convention,
                                                               altitude,
                                                               id_bdcavite,
                                                               comment,
                                                               telemetric_crossaz,
                                                               landcover,
                                                               municipality,
                                                               precision,
                                                               territory,
                                                               type_category,
                                                               type,
                                                               geom,
                                                               timestamp_create,
                                                               timestamp_update,
                                                               created_by_id,
                                                               updated_by_id)
                values (NEW.id_place,
                        NEW.name,
                        NEW.is_hidden,
                        NEW.is_gite,
                        NEW.is_managed,
                        NEW.proprietary,
                        NEW.convention,
                        NEW.altitude,
                        NEW.id_bdcavite,
                        NEW.comment,
                        NEW.telemetric_crossaz,
                        the_landcover,
                        the_municipality,
                        the_precision,
                        the_territory,
                        the_category_type,
                        the_type_code,
                        st_transform(NEW.geom, 2154),
                        NEW.timestamp_create,
                        NEW.timestamp_update,
                        NEW.created_by_id,
                        NEW.updated_by_id);
            end if;
            return NEW;
        elsif
            (TG_OP = 'INSERT')
        then
-- Inserting row when raw data is inserted
            insert into share_with_foreigndb1.sights_place(id_place,
                                                           name,
                                                           is_hidden,
                                                           is_gite,
                                                           is_managed,
                                                           proprietary,
                                                           convention,
                                                           altitude,
                                                           id_bdcavite,
                                                           comment,
                                                           telemetric_crossaz,
                                                           landcover,
                                                           municipality,
                                                           precision,
                                                           territory,
                                                           type_category,
                                                           type,
                                                           geom,
                                                           timestamp_create,
                                                           timestamp_update,
                                                           created_by_id,
                                                           updated_by_id)
            values (NEW.id_place,
                    NEW.name,
                    NEW.is_hidden,
                    NEW.is_gite,
                    NEW.is_managed,
                    NEW.proprietary,
                    NEW.convention,
                    NEW.altitude,
                    NEW.id_bdcavite,
                    NEW.comment,
                    NEW.telemetric_crossaz,
                    the_landcover,
                    the_municipality,
                    the_precision,
                    the_territory,
                    the_category_type,
                    the_type_code,
                    st_transform(NEW.geom, 2154),
                    NEW.timestamp_create,
                    NEW.timestamp_update,
                    NEW.created_by_id,
                    NEW.updated_by_id);
            return new;
        end if;
    end if;
end;
$$
    language plpgsql
;

drop trigger if exists place_to_foreigndb1_trigger on public.sights_place
;

create trigger place_to_foreigndb1_trigger
    after insert or update or delete
    on public.sights_place
    for each row
execute procedure update_foreign_sights_place()
;

update sights_place set id_bdcavite = id_bdcavite;