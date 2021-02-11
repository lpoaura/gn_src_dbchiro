# gn_scripts_src_dbchiro

Intégration continue des données dbChiro dans une instance GeoNature
Ce projet contient les scripts pour alimenter automatiquement une instance GeoNature depuis dbChiroWeb.

Le prérequis est que la base de données dbChiro soit intégré dans la base de données GeoNature (dans un schéma spécifique).

Ces scripts alimentent automatiquement les modules suivants:
* Métadonnées : 
    * Création d'un Cadre d'acquisition par défaut pour receuillir les jeux de données orphelins
    * Création des jeux de données à partir des études dbChiro
    
* Observateurs:
    * Création automatique des utilisateurs dbChiro dans UsersHub, sans droits particuliers (création uniquement dans utilisateurs.t_roles).
    
* Synthèse:
    * Création automatique des occurences dans la synthèse (version simplifiée, niveau session/taxon).
