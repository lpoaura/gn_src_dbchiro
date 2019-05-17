/* Prérequis, extension postgres_fdw */
create extension if not exists postgres_fdw
;

create extension if not exists postgis
;

/* info; new "src_dbchiro" schema */
drop schema if exists src_dbchiro cascade
;

create schema src_dbchiro
;
/* Création d'un rôle spécifique à cet échange offrant la possibilité */

create role share_from_dbchiro1 login encrypted password 'passwordToChange'
;

grant usage on schema src_dbchiro to share_from_dbchiro1
;

alter default privileges in schema src_dbchiro grant select, insert, update, delete on tables to share_from_dbchiro1
;

/* info: connection to dbchiro foreign postgresql server */

/* Utilisation temporaire du schéma src_dbchiro comme schéma courant */

set search_path = 'src_dbchiro', 'public'
;

/* INFO : Tables simplifiée des comptes utilisateurs  */
create table observers (
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
)
;

alter table observers
    owner to geonature
;

create index on observers(username)
;

create index on observers(created_by)
;

create index on observers(updated_by)
;

/* INFO: Table des études */

-- auto-generated definition
create table studies (
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
    created_by_id         integer references observers,
    project_manager_id    integer references observers,
    updated_by_id         integer references observers
)
;


alter table studies
    owner to geonature
;

create index on studies(timestamp_update desc)
;

create index on studies(name)
;

create index on studies(created_by_id)
;

create index on studies(name)
;

create index on studies(name)
;

create index on studies(year)
;

create index on studies(year)
;

create index on studies(created_by_id)
;

create index on studies(project_manager_id)
;

create index on studies(updated_by_id)
;


/* INFO: Table des taxons */
-- auto-generated definition
create table species (
    id              integer     not null primary key,
    sys_order       integer     not null,
    codesp          varchar(20) not null,
    sp_true         boolean     not null,
    sci_name        varchar(255),
    full_name       varchar(255),
    common_name_fr  varchar(255),
    common_name_eng varchar(255)
)
;

alter table species
    owner to geonature
;


/* INFO: Table des localités */
create table places (
    id_place           integer                  not null primary key,
    uuid               uuid unique,
    name               varchar(255)             not null,
    is_hidden          boolean default false    not null,
    is_gite            boolean default false    not null,
    is_managed         boolean default false    not null,
    proprietary        varchar(100),
    convention         boolean                  not null,
    altitude           integer,
    id_bdcavite        varchar(15),
    comment            text,
    bdsource           varchar(100),
    id_bdsource        varchar(100),
    x                  double precision,
    y                  double precision,
    geom               geometry(Point, 2154),
    timestamp_create   timestamp with time zone not null,
    timestamp_update   timestamp with time zone not null,
    domain             varchar(50),
    landcover          varchar(250),
    municipality       varchar(10),
    precision          varchar(50)              not null,
    territory          varchar(50),
    type_category      varchar(50),
    type               varchar(50),
    created_by_id      integer references observers,
    updated_by_id      integer references observers,
    telemetric_crossaz boolean default false    not null
)
;


alter table places
    owner to geonature
;

create index on places(timestamp_update desc)
;

create index on places(name)
;

create index on places(created_by_id)
;

create index on places(territory)
;

create index on places(geom)
;

create index on places(is_hidden)
;

create index on places(is_gite)
;

create index on places(is_managed)
;

create index on places(proprietary)
;

create index on places(domain)
;

create index on places(landcover)
;

create index on places(municipality)
;

create index on places(precision)
;

create index on places(type)
;

create index on places(updated_by_id)
;

/* info: Table des sessions */

-- auto-generated definition
create table sessions (
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
    created_by_id    integer references observers,
    main_observer_id integer references observers,
    place_id         integer                  not null
        references places,
    study_id         integer
        references studies,
    updated_by_id    integer references observers
)
;

alter table sessions
    owner to geonature
;

create index on sessions(contact)
;

create index on sessions(created_by_id)
;

create index on sessions(main_observer_id)
;

create index on sessions(place_id)
;

create index on sessions(study_id)
;

create index on sessions(updated_by_id)
;

/* info; Table des observations */

-- auto-generated definition

create table sightings (
    id_sighting      integer                  not null primary key,
    codesp_id        integer                  not null references species,
    codesp           varchar(20),
    common_name      varchar(250),
    sciname          varchar(250),
    sptrue           boolean,
    period           varchar(50),
    total_count      integer,
    breed_colo       boolean,
    is_doubtful      boolean                  not null,
    id_bdsource      text,
    bdsource         text,
    comment          text,
    observer_id      integer references observers,
    session_id       integer                  not null
        references sessions,
    timestamp_create timestamp with time zone not null,
    timestamp_update timestamp with time zone not null,
    created_by_id    integer references observers,
    updated_by_id    integer references observers
)
;

alter table sightings
    owner to geonature
;

create index on sightings(codesp_id)
;

create index on sightings(created_by_id)
;

create index on sightings(observer_id)
;

create index on sightings(session_id)
;

create index on sightings(updated_by_id)
;


