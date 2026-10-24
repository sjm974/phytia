# Phytia

**Le bon produit phytosanitaire, sur la bonne culture.**

Phytia est une application Flutter (Android + Windows) qui indique à l'agriculteur
quel produit phytosanitaire **homologué** utiliser sur sa culture, contre quelle
maladie ou quel ravageur, avec sa **dose**, son **délai avant récolte (DAR)** et ses
**zones non traitées (ZNT)**.

Les données proviennent exclusivement du catalogue officiel **E-Phy de l'Anses**
(licence ouverte), embarqué dans l'application : elle fonctionne **100 % hors ligne**,
aucun compte, aucune donnée envoyée.

## Fonctionnalités (V1)

- Recherche **culture → maladie/ravageur → produits homologués** (19 598 usages, 130 cultures).
- Fiche produit complète : dose, nombre d'applications, intervalle, DAR, ZNT,
  conditions d'emploi, phrases de risque, mentions de danger, substances actives, AMM.
- **Mon stock** : enregistrez les produits de votre cabane ; ils passent en tête
  des résultats, et la fonction « Avec mon stock, que puis-je traiter ? » croise
  votre stock avec les usages autorisés.
- **Favoris**, **cultures récentes**, recherche globale tolérante aux accents.
- **Comparateur** : deux produits côte à côte, usages communs et usages propres,
  avec un verdict — deux spécialités à composition identique n'ont pas forcément
  les mêmes usages autorisés (cas Essen'ciel / Limocide J).
- **Produits équivalents** : depuis une fiche, les substituts à composition
  déclarée identique (même substance, même dose), avec ceux réellement autorisés
  pour l'usage consulté et ceux qui ne le sont pas.
- **Carnet de traitement** : parcelles (culture, **mode de conduite**, **position
  GPS** relevée au champ), traitements horodatés (**heures**, dose, **volume de
  bouillie** calculé depuis un volume/ha, stade BBCH, opérateur), **date de récolte possible calculée depuis
  le DAR**, alerte si le produit a été retiré depuis, export **CSV** et **PDF**.

## Démarrer

```powershell
flutter pub get
flutter run -d windows      # ou -d <appareil Android>
```

## Mise à jour du catalogue (sans réinstaller)

Le workflow .github/workflows/update-data.yml tourne chaque mercredi à 4 h UTC
(et à la demande) : il télécharge l'archive E-Phy, régénère les fichiers, puis les
publie dans la release au tag fixe « data ».

L'application lit alors :

```
https://github.com/<compte>/<dépôt>/releases/download/data/manifest.json
```

puis phytia_core.json.gz et phytia_details.json.gz. Le manifeste contient les
tailles et les empreintes SHA-256 : un fichier corrompu est refusé et l'ancien
catalogue reste en place. Les fichiers téléchargés sont stockés dans le dossier de
données de l'application et chargés au démarrage en priorité sur les assets.

### Mise en service (une fois)

1. Créer le dépôt GitHub et pousser le projet :

```powershell
git init
git add .
git commit -m "Phytia 0.1.0"
git branch -M main
git remote add origin https://github.com/<compte>/phytia.git
git push -u origin main
```

2. Onglet Actions, workflow « Catalogue E-Phy », bouton Run workflow.
3. Une release « data » apparaît avec les trois fichiers.
4. Renseigner l'adresse dans lib/data/update_config.dart :

```dart
const String kDataReleaseBase =
    'https://github.com/<compte>/phytia/releases/download/data/';
```

ou garder CHANGER-MOI et compiler avec le dart-define PHYTIA_DATA_BASE pointant
sur la même adresse.

5. Recompiler l'application : le bouton « Vérifier les mises à jour » de l'écran
   À propos télécharge la nouvelle version et recharge le catalogue à chaud.

Tant que CHANGER-MOI est présent, l'écran À propos indique que les mises à jour ne
sont pas configurées et n'effectue aucun appel réseau.

## Construire

```powershell
flutter build apk --release
flutter build windows --release
```

## Régénérer le catalogue

Les fichiers sources ne sont pas versionnés (dossier _data/, ignoré par git).

1. Télécharger l'archive CSV UTF-8 depuis
   [data.gouv.fr — Données ouvertes du catalogue E-Phy](https://www.data.gouv.fr/datasets/donnees-ouvertes-du-catalogue-e-phy-des-produits-phytopharmaceutiques-matieres-fertilisantes-et-supports-de-culture-adjuvants-produits-mixtes-et-melanges)
   et la décompresser dans _data/csv/.
2. Régénérer les assets :

```powershell
dart tool/build_dataset.dart
```

Le script produit assets/data/phytia_core.json.gz (produits + usages) et
assets/data/phytia_details.json.gz (conditions d'emploi, phrases de risque,
mentions de danger), chargé à la demande.

## Architecture

```
lib/
  main.dart              démarrage : catalogue, stock, écran d'accueil
  app.dart               MaterialApp, thème, localisation française
  data/
    models.dart          Product, Usage, ProductResult, normalisation des accents
    dataset.dart         chargement gzippé + index mémoire (cultures, cibles, recherche)
    details.dart         conditions d'emploi / risques, chargés à la demande
    store.dart           stock, favoris, cultures récentes (JSON local)
    journal_models.dart  parcelles, traitements, carnet (pur Dart, testable)
    journal.dart         persistance et notifications du carnet
    journal_export.dart  export CSV et PDF du carnet
    scope.dart           injection du catalogue et du stock dans l'arbre
  ui/
    home_screen.dart     accueil, recherche, mon stock, favoris
    culture_screen.dart  choix de la culture
    target_screen.dart   choix de la maladie / du ravageur
    results_screen.dart  produits homologués, filtres, tri stock d'abord
    product_screen.dart  fiche produit + usage détaillé
    stock_screen.dart    mon stock, favoris, ajout de produit
    search_screen.dart   recherche globale
    compare_screen.dart  comparaison de deux produits (usages communs / propres)
    equivalents_screen.dart  substituts à composition identique
    about_screen.dart    source, avertissement, mentions légales
  ui/journal/           parcelles, saisie de traitement, export (sous-écrans)
tool/
  build_dataset.dart     CSV E-Phy → assets JSON gzippés
test/
  dataset_test.dart      tests sur le catalogue réel embarqué
```

Aucune dépendance native : le catalogue est un JSON gzippé chargé en mémoire
(19 600 usages, ~0,7 Mo compressé). Le même code tourne à l'identique sur Android
et Windows, et les tests s'exécutent avec dart test.

## Données et mentions légales

- Source : « Données E-Phy — Anses », mise à jour du 20/10/2026.
- Les données d'E-Phy **ne sont pas opposables** : seules les décisions publiées au
  registre électronique des autorisations de mise sur le marché font foi.
- L'application ne remplace ni l'étiquette du produit, ni le certiphyto, ni la
  réglementation locale (arrêtés préfectoraux, zones protégées).