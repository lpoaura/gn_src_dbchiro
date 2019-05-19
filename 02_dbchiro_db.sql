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

create server foreign_db1 foreign data wrapper postgres_fdw options (host 'foreigndb_host', dbname 'foreigndb_name', port 'foreigndb_port')
;

create user mapping for dbchirodbuser server foreign_db1 options (user 'foreigndb_user', password 'foreigndb_pwd')
;

grant usage on foreign server foreign_db1 to dbchirodbuser
;

/* Utilisation temporaire du schéma src_dbchiro comme schéma courant */

set role dbchirodbuser
;

set search_path = 'src_dbchiro', 'public'
;

drop foreign table share_with_foreigndb1.sightings
;

import foreign schema src_dbchiro limit to (sightings) from
    server foreign_db1 into share_with_foreigndb1
;


/* création des fonctions d'alimentation des tables distantes */

/* INFO: profiles */

create or replace function update_foreign_observers() returns trigger as
$$
begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from share_with_foreigndb1.observers
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
        update share_with_foreigndb1.observers
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
            insert into share_with_foreigndb1.observers(id, last_login, username, first_name, last_name, email,
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
        insert into share_with_foreigndb1.observers(id, last_login, username, first_name, last_name, email,
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
execute procedure update_foreign_observers()
;

-- set role dbchirodbuser;
update accounts_profile
set addr_appt = addr_appt
;

/* INFO: species */

create or replace function update_foreign_species() returns trigger as
$$
begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from share_with_foreigndb1.species
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
        update share_with_foreigndb1.species
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
            insert into share_with_foreigndb1.species(id, sys_order, codesp, sp_true, sci_name, full_name,
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
        insert into share_with_foreigndb1.species(id, sys_order, codesp, sp_true, sci_name, full_name,
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

drop trigger if exists accounts_to_foreigndb1_trigger on public.dicts_specie
;

create trigger species_to_foreigndb1_trigger
    after insert or update or delete
    on public.dicts_specie
    for each row
execute procedure update_foreign_species()
;

-- set role dbchirodbuser;
update dicts_specie
set common_name_fr = common_name_fr
;


/* info: études */

create or replace function update_foreign_studies() returns trigger as
$$
begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from share_with_foreigndb1.studies
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
        update share_with_foreigndb1.studies
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
            insert into share_with_foreigndb1.studies(id_study, name, year, public_funding, public_report,
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
        insert into share_with_foreigndb1.studies(id_study, name, year, public_funding, public_report,
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
execute procedure update_foreign_studies()
;

update management_study
set year = year
;

/* info : especes */

create or replace function update_foreign_species() returns trigger as
$$
begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from share_with_foreigndb1.species
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
        update share_with_foreigndb1.species
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
            insert into share_with_foreigndb1.species(id, sys_order, codesp, sp_true, sci_name, full_name,
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
        insert into share_with_foreigndb1.species(id, sys_order, codesp, sp_true, sci_name, full_name,
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
execute procedure update_foreign_species()
;

update dicts_specie
set sys_order = sys_order
;

/* info: Localités */


create or replace function update_foreign_places() returns trigger as
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
        from share_with_foreigndb1.places
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
            update share_with_foreigndb1.places
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
                insert into share_with_foreigndb1.places(id_place,
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
            insert into share_with_foreigndb1.places(id_place,
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
execute procedure update_foreign_places()
;

update sights_place
set id_bdcavite = id_bdcavite
;

/* Info : Sessions */


create or replace function update_foreign_sessions() returns trigger as
$$
declare
    the_contactcode varchar(10);

begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from share_with_foreigndb1.sessions
        where id_session = OLD.id_session;
        if not FOUND
        then
            return null;
        end if;
        return old;

    elsif
        (TG_OP = 'UPDATE' or TG_OP = 'INSERT')
    then
        /* populate declarde variables */
        select into the_contactcode code from public.dicts_contact where new.contact_id = dicts_contact.id;

        /* execute update or insert with declared variables */
        if (TG_OP = 'UPDATE')
        then
            -- Updating or inserting data when JSON data is updated
            update share_with_foreigndb1.sessions
            set id_session       = NEW.id_session,
                name             = NEW.name,
                date_start       = NEW.date_start,
                time_start       = NEW.time_start,
                date_end         = NEW.date_end,
                time_end         = NEW.time_end,
                is_confidential  = NEW.is_confidential,
                comment          = NEW.comment,
                contact          = the_contactcode,
                main_observer_id = NEW.main_observer_id,
                place_id         = NEW.place_id,
                study_id         = NEW.study_id,
                timestamp_create = NEW.timestamp_create,
                timestamp_update = NEW.timestamp_update,
                created_by_id    = NEW.created_by_id,
                updated_by_id    = NEW.updated_by_id
            where id_session = OLD.id_session;
            if not FOUND
            then
                -- Inserting data in new row, usually after table re-creation
                insert into share_with_foreigndb1.sessions(id_session,
                                                           name,
                                                           date_start,
                                                           time_start,
                                                           date_end,
                                                           time_end,
                                                           is_confidential,
                                                           comment,
                                                           contact,
                                                           main_observer_id,
                                                           place_id,
                                                           study_id,
                                                           timestamp_create,
                                                           timestamp_update,
                                                           created_by_id,
                                                           updated_by_id)
                values (NEW.id_session,
                        NEW.name,
                        NEW.date_start,
                        NEW.time_start,
                        NEW.date_end,
                        NEW.time_end,
                        NEW.is_confidential,
                        NEW.comment,
                        the_contactcode,
                        NEW.main_observer_id,
                        NEW.place_id,
                        NEW.study_id,
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
            insert into share_with_foreigndb1.sessions(id_session,
                                                       name,
                                                       date_start,
                                                       time_start,
                                                       date_end,
                                                       time_end,
                                                       is_confidential,
                                                       comment,
                                                       contact,
                                                       main_observer_id,
                                                       place_id,
                                                       study_id,
                                                       timestamp_create,
                                                       timestamp_update,
                                                       created_by_id,
                                                       updated_by_id)
            values (NEW.id_session,
                    NEW.name,
                    NEW.date_start,
                    NEW.time_start,
                    NEW.date_end,
                    NEW.time_end,
                    NEW.is_confidential,
                    NEW.comment,
                    the_contactcode,
                    NEW.main_observer_id,
                    NEW.place_id,
                    NEW.study_id,
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

drop trigger if exists session_to_foreigndb1_trigger on public.sights_session
;

create trigger session_to_foreigndb1_trigger
    after insert or update or delete
    on public.sights_session
    for each row
execute procedure update_foreign_sessions()
;

update sights_session
set time_end = time_end
;


/* Info : Sightings */

create or replace function update_foreign_sightings() returns trigger as
$$
declare
    the_codesp     varchar(20);
    the_sciname    varchar(250);
    the_commonname varchar(250);
    the_sptrue     boolean;

begin
    if
        (TG_OP = 'DELETE')
    then
-- Deleting data when original data is deleted
        delete
        from share_with_foreigndb1.sightings
        where id_sighting = OLD.id_sighting;
        if not FOUND
        then
            return null;
        end if;
        return old;

    elsif
        (TG_OP = 'UPDATE' or TG_OP = 'INSERT')
    then
        /* populate declarde variables */
        select codesp, common_name_fr, sci_name, sp_true into the_codesp, the_commonname, the_sciname, the_sptrue
        from public.dicts_specie
        where new.codesp_id = dicts_specie.id;

        /* execute update or insert with declared variables */
        if (TG_OP = 'UPDATE')
        then
            -- Updating or inserting data when JSON data is updated
            update share_with_foreigndb1.sightings
            set id_sighting      = NEW.id_sighting,
                codesp_id        = NEW.codesp_id,
                codesp           = the_codesp,
                common_name      = the_commonname,
                sciname          = the_sciname,
                sptrue           = the_sptrue,
                period           = NEW.period,
                total_count      = NEW.total_count,
                breed_colo       = NEW.breed_colo,
                is_doubtful      = NEW.is_doubtful,
                id_bdsource      = NEW.id_bdsource,
                comment          = NEW.comment,
                bdsource         = NEW.bdsource,
                observer_id      = NEW.observer_id,
                session_id       = NEW.session_id,
                timestamp_create = NEW.timestamp_create,
                timestamp_update = NEW.timestamp_update,
                created_by_id    = NEW.created_by_id,
                updated_by_id    = NEW.updated_by_id
            where id_sighting = OLD.id_sighting;
            if not FOUND
            then
                -- Inserting data in new row, usually after table re-creation
                insert into share_with_foreigndb1.sightings(id_sighting, codesp_id, codesp, common_name, sciname,
                                                            sptrue, period, total_count, breed_colo, is_doubtful,
                                                            id_bdsource, bdsource, comment, observer_id, session_id,
                                                            timestamp_create, timestamp_update, created_by_id,
                                                            updated_by_id)
                values (NEW.id_sighting,
                        NEW.codesp_id,
                        the_codesp,
                        the_commonname,
                        the_sciname,
                        the_sptrue,
                        NEW.period,
                        NEW.total_count,
                        NEW.breed_colo,
                        NEW.is_doubtful,
                        NEW.id_bdsource,
                        NEW.comment,
                        NEW.bdsource,
                        NEW.observer_id,
                        NEW.session_id,
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
            insert into share_with_foreigndb1.sightings(id_sighting, codesp_id, codesp, common_name, sciname,
                                                        sptrue, period, total_count, breed_colo, is_doubtful,
                                                        id_bdsource, bdsource, comment, observer_id, session_id,
                                                        timestamp_create, timestamp_update, created_by_id,
                                                        updated_by_id)
            values (NEW.id_sighting,
                    NEW.codesp_id,
                    the_codesp,
                    the_commonname,
                    the_sciname,
                    the_sptrue,
                    NEW.period,
                    NEW.total_count,
                    NEW.breed_colo,
                    NEW.is_doubtful,
                    NEW.id_bdsource,
                    NEW.comment,
                    NEW.bdsource,
                    NEW.observer_id,
                    NEW.session_id,
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

drop trigger if exists sighting_to_foreigndb1_trigger on public.sights_sighting
;

create trigger sighting_to_foreigndb1_trigger
    after insert or update or delete
    on public.sights_sighting
    for each row
execute procedure update_foreign_sightings()
;

update sights_sighting
set comment = comment
;