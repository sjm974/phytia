# Phytia — Proposition technique (V1)

> **Note d'implémentation (24/10/2026)** — L'application est livrée. Un écart
> assumé par rapport à la proposition initiale : plutôt qu'une base SQLite
> (drift + sqlite3_flutter_libs), le catalogue est un **JSON gzippé chargé en
> mémoire** (0,66 Mo pour les 19 598 usages, 0,96 Mo pour les détails).
> Raisons : zéro dépendance native donc un binaire strictement identique sur
> Android et Windows, démarrage instantané, et une couche données testable en
> pur Dart (`dart test`). Le comportement fonctionnel décrit ci-dessous est
> inchangé. Voir `README.md` pour l'état réel du code.


Application Flutter (Android + Windows) qui indique à l'agriculteur **quel produit phytosanitaire homologué utiliser sur sa culture, contre quelle maladie ou quel ravageur**, d'après le catalogue officiel **E-Phy de l'Anses**.

## 1. Données — vérifiées le 24/10/2026

Source : [data.gouv.fr — Données ouvertes du catalogue E-Phy](https://www.data.gouv.fr/datasets/donnees-ouvertes-du-catalogue-e-phy-des-produits-phytopharmaceutiques-matieres-fertilisantes-et-supports-de-culture-adjuvants-produits-mixtes-et-melanges) (Anses, Licence Ouverte, mise à jour hebdomadaire le mardi soir).

Archive UTF-8 téléchargée : **3,8 Mo zippée**, 38 Mo décompressée.

| Fichier | Lignes | Rôle dans l'app |
|---|---|---|
| `produits` | 15 169 | fiche produit : AMM, titulaire, substances actives, fonction, formulation, état |
| `usages_des_produits_autorises` | 19 600 | **cœur** : culture × cible × dose × DAR × ZNT |
| `produits_usages` | 81 619 | historique complet (usages retirés inclus) |
| `produits_condition_emploi` | 29 715 | EPI, restrictions, mentions |
| `produits_phrases_de_risque` | 9 464 | H226, H302… |
| `produits_classe_et_mention_danger` | 10 877 | classement CLP |
| `substance_active` | 1 339 | substances actives + n° CAS |

Clé de jointure : `numero AMM`. L'identifiant d'usage est une chaîne structurée :

```
"Blé tendre d'hiver*Trt Part.Aer.*Maladies des épis"
 culture            type de traitement   cible (maladie / ravageur)
```

→ séparateur `*`, exploitable directement pour l'arbre **culture → cible → produits**.

## 2. Modèle de données (SQLite embarquée)

```
produits(amm PK, nom, titulaire, type_commercial, gamme, etat,
         substances_actives, fonctions, formulation, date_autorisation)
usages(id PK, amm FK, culture, type_traitement, cible,
       stade_min_bbch, stade_max_bbch, etat, dose, dose_unite,
       dar_jours, dar_bbch, nb_max_applications, intervalle_min_j,
       znt_aquatique_m, znt_arthropodes_m, znt_plantes_m, conditions)
conditions_emploi(amm, categorie, libelle)
phrases_risque(amm, code, libelle)
mentions_danger(amm, classe, mention)
substances_actives(nom, cas, etat)
usages_fts  -- FTS5 : recherche plein texte culture/cible/produit
meta(key, value)  -- version du jeu, date MAJ, source
stock(amm PK, quantite, unite, ajoute_le)   -- local, jamais synchronisé
favoris(amm PK)
```

Taille estimée de la base : **6 à 8 Mo** (≈ 2-3 Mo compressée dans l'APK).

## 3. Architecture Flutter

- **drift + sqlite3_flutter_libs** : une seule API SQL typée, fonctionne sur Android *et* Windows (DLL embarquée).
- La base `assets/db/phytia.db` est **livrée pré-construite** : premier lancement instantané, zéro réseau.
- Copie dans le dossier documents au premier lancement, puis ouverture en lecture seule.
- État : `flutter_riverpod` (léger, testable). Navigation : `go_router`.
- UI : Material 3, palette verte « terrain », typographie large (lisible au soleil, avec gants).
- 100 % français, aucun compte, aucune donnée envoyée.

## 4. Écrans V1

1. **Accueil** — recherche immédiate : *« Que dois-je traiter ? »* (culture) ou nom de produit ; accès à Mon stock, Favoris.
2. **Culture → cible** — autocomplétion sur ~300 cultures, puis liste des maladies/ravageurs réellement présents dans E-Phy pour cette culture, groupés par type de traitement (parties aériennes, sol, semences).
3. **Résultats** — cartes produits triées : **★ mes produits en stock d'abord**, puis biocontrôle, puis le reste. Badges dose / DAR / ZNT. Filtres : bio, DAR max, ZNT.
4. **Fiche produit-usage** — dose retenue + unité, nombre max d'applications, intervalle, DAR (jours et BBCH), ZNT aquatique / arthropodes / plantes, conditions d'emploi complètes, phrases de risque, substances actives, n° AMM, date de décision, lien vers E-Phy.
5. **Mon stock** — j'ajoute les produits que j'ai dans ma cabane (recherche nom ou AMM). Deux usages : (a) savoir quoi faire d'un produit, (b) **« Avec mon stock, que puis-je traiter sur cette culture ? »** — la fonctionnalité qui te distingue.
6. **Favoris / À propos** — source Anses, date du jeu de données, avertissement « données non opposables, la décision d'AMM fait foi ».

## 5. Mise à jour des données

- V1 : base régénérée à chaque version de l'app (script `tool/build_db.dart`, exécutable sur PC).
- V2 : bouton « Vérifier les mises à jour » → téléchargement du zip Anses, reconstruction incrémentale en tâche de fond.

## 6. Plan de travail

| Jalon | Contenu |
|---|---|
| **M1** | `flutter create` + dépendances + script CSV → SQLite + base réelle vérifiée (19 600 usages) |
| **M2** | Écrans 1-2-3 + recherche FTS, fiches produit (écran 4) |
| **M3** | Stock, favoris, filtres, écran À propos |
| **M4** | Icône/splash, tests, build APK release + installeur Windows, mode d'emploi |

## 7. À faire côté utilisateur (une fois)

```powershell
cd E:\developpement\Phytia
flutter create --empty --org fr.phytia --project-name phytia --platforms=android,windows .
```

Ensuite je prends le relais : `pubspec.yaml`, base de données, écrans, tests.

## 8. Points juridiques

- Citation obligatoire : « Données E-Phy — Anses », avec la date de mise à jour.
- Mention « Les données présentes dans E-Phy ne sont pas opposables ; seules les décisions publiées au registre électronique des AMM font foi ».
- L'app ne remplace ni le certiphyto ni la lecture de l'étiquette.