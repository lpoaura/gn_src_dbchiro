/* Prérequis, extension postgres_fdw */
create extension if not exists postgres_fdw;
create extension if not exists postgis;

/* info; new "src_dbchiro" schema */
drop schema if exists src_dbchiro cascade;
create schema src_dbchiro;
/* Création d'un rôle spécifique à cet échange offrant la possibilité */

create role share_from_dbchiro1 login encrypted password 'passwordToChange';
grant usage on schema src_dbchiro to share_from_dbchiro1;
alter default privileges in schema src_dbchiro grant select, insert, update, delete on tables to share_from_dbchiro1;

/* info: connection to dbchiro foreign postgresql server */

/* Utilisation temporaire du schéma src_dbchiro comme schéma courant */
set search_path = 'src_dbchiro', 'public';

/* INFO : Tables simplifiée des comptes utilisateurs  */
create table accounts_profile (
    id               integer unique           not null primary key,
    uuid             uuid unique,
    last_login       timestamp with time zone,
    username         varchar(150) unique      not null,
    first_name       varchar(30)              not null,
    last_name        varchar(30)              not null,
    email            varchar(254)             not null,
    is_active        boolean                  not null,
    date_joined      timestamp with time zone not null,
    organism         varchar(255),
    home_phone       varchar(50),
    mobile_phone     varchar(50),
    addr_appt        varchar(50),
    addr_building    varchar(255),
    addr_street      varchar(255),
    addr_city        varchar(255),
    addr_city_code   varchar(10),
    addr_dept        varchar(255),
    addr_country     varchar(255),
    comment          text,
    timestamp_create timestamp with time zone not null,
    timestamp_update timestamp with time zone not null,
    created_by       varchar(100),
    updated_by       varchar(100)
);

alter table accounts_profile
    owner to geonature;

create index on accounts_profile(username);
create index on accounts_profile(created_by);
create index on accounts_profile(updated_by);

/* INFO: Table des études */

-- auto-generated definition
create table management_study (
    id_study              integer                  not null primary key,
    name                  varchar(255)             not null,
    year                  varchar(10)              not null,
    public_funding        boolean                  not null,
    public_report         boolean                  not null,
    public_raw_data       boolean                  not null,
    confidential          boolean                  not null,
    confidential_end_date date,
    type_etude            varchar(255)             not null,
    type_espace           varchar(255),
    comment               text,
    timestamp_create      timestamp with time zone not null,
    timestamp_update      timestamp with time zone not null,
    created_by_id         integer references accounts_profile,
    project_manager_id    integer references accounts_profile,
    updated_by_id         integer references accounts_profile
);

alter table management_study
    owner to geonature;

create index on management_study(timestamp_update desc);
create index on management_study(name);
create index on management_study(created_by_id);
create index on management_study(name);
create index on management_study(name);
create index on management_study(year);
create index on management_study(year);
create index on management_study(created_by_id);
create index on management_study(project_manager_id);
create index on management_study(updated_by_id);


/* INFO: Table des taxons */
-- auto-generated definition
create table dicts_specie (
    id              integer     not null primary key,
    sys_order       integer     not null,
    codesp          varchar(20) not null,
    sp_true         boolean     not null,
    sci_name        varchar(255),
    full_name       varchar(255),
    common_name_fr  varchar(255),
    common_name_eng varchar(255)
);

alter table dicts_specie
    owner to geonature;


/* INFO: Table des localités */
create table sights_place (
    id_place            integer                  not null primary key,
    uuid                uuid unique,
    name                varchar(255)             not null,
    is_hidden           boolean default false    not null,
    is_gite             boolean default false    not null,
    is_managed          boolean default false    not null,
    proprietary         varchar(100),
    convention          boolean                  not null,
    convention_file     varchar(100),
    map_file            varchar(100),
    photo_file          varchar(100),
    habitat             varchar(255),
    altitude            integer,
    id_bdcavite         varchar(15),
    plan_localite       varchar(100),
    comment             text,
    other_imported_data text,
    bdsource            varchar(100),
    id_bdsource         varchar(100),
    x                   double precision,
    y                   double precision,
    geom                geometry(Point, 2154),
    timestamp_create    timestamp with time zone not null,
    timestamp_update    timestamp with time zone not null,
    domain              varchar(50),
    landcover           varchar(250),
    municipality        varchar(10),
    precision           varchar(50)              not null,
    territory           integer,
    type_category       varchar(50),
    type                varchar(50),
    created_by_id       integer references accounts_profile,
    updated_by_id       integer references accounts_profile,
    telemetric_crossaz  boolean default false    not null
);


alter table sights_place
    owner to geonature;

create index on sights_place(timestamp_update desc);
create index on sights_place(name);
create index on sights_place(created_by_id);
create index on sights_place(territory);
create index on sights_place(geom);
create index on sights_place(is_hidden);
create index on sights_place(is_gite);
create index on sights_place(is_managed);
create index on sights_place(proprietary);
create index on sights_place(domain);
create index on sights_place(landcover);
create index on sights_place(municipality);
create index on sights_place(precision);
create index on sights_place(type);
create index on sights_place(updated_by_id);

/* info: Table des sessions */

-- auto-generated definition
create table sights_session (
    id_session       integer                  not null primary key,
    name             varchar(150)             not null,
    date_start       date                     not null,
    time_start       time,
    date_end         date,
    time_end         time,
    data_file        varchar(100),
    is_confidential  boolean                  not null,
    comment          text,
    timestamp_create timestamp with time zone not null,
    timestamp_update timestamp with time zone not null,
    contact          varchar(10),
    created_by_id    integer references accounts_profile,
    main_observer_id integer references accounts_profile,
    place_id         integer                  not null
        references sights_place,
    study_id         integer
        references management_study,
    updated_by_id    integer references accounts_profile
);

alter table sights_session
    owner to geonature;

create index on sights_session(contact);
create index on sights_session(created_by_id);
create index on sights_session(main_observer_id);
create index on sights_session(place_id);
create index on sights_session(study_id);
create index on sights_session(updated_by_id);

/* info; Table des observations */

-- auto-generated definition
create table sights_sighting (
    id_sighting      integer                  not null primary key,
    period           varchar(50),
    total_count      integer,
    breed_colo       boolean,
    is_doubtful      boolean                  not null,
    id_bdsource      text,
    bdsource         varchar(100),
    comment          text,
    timestamp_create timestamp with time zone not null,
    timestamp_update timestamp with time zone not null,
    codesp_id        integer                  not null
        references dicts_specie,
    created_by_id    integer references accounts_profile,
    observer_id      integer references accounts_profile,
    session_id       integer                  not null
        references sights_session,
    updated_by_id    integer references accounts_profile
);

alter table sights_sighting
    owner to geonature;

create index on sights_sighting(codesp_id);
create index on sights_sighting(created_by_id);
create index on sights_sighting(observer_id);
create index on sights_sighting(session_id);
create index on sights_sighting(updated_by_id);


