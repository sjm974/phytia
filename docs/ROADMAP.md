# Phytia — Feuille de route

## Où on en est (24/10/2026)

- Application complète : 25 fichiers, ~5 000 lignes, `dart analyze` propre, **21 tests verts**.
- Catalogue E-Phy du 20/10/2026 embarqué (19 598 usages, 15 168 produits).
- Comparateur, produits équivalents, fiche BBCH.
- **P1 livré** : workflow GitHub Actions hebdomadaire + mise à jour à chaud dans
  l'application (manifeste, SHA-256, cache local, rechargement sans redémarrage).
- **P2 livré** : parcelles, carnet de traitement, date de récolte calculée depuis
  le DAR, export CSV et PDF.
- Reste à faire côté toi : créer le dépôt, lancer le workflow, renseigner l'URL
  dans `lib/data/update_config.dart`, puis le premier lancement.

## P0 — Premier lancement (toi, 10 minutes)

```powershell
cd E:\developpement\Phytia
flutter run -d windows
```

À vérifier : l'accueil s'affiche, la recherche « vigne → mildiou » remonte des
produits, une fiche s'ouvre, le bouton « Équivalents » liste les 7 produits.
Toute erreur (écran rouge, message console) : me la coller, je corrige.

Ensuite, les binaires :

```powershell
flutter build apk --release
flutter build windows --release
```

## P1 — Mise à jour des données sans réinstaller — LIVRÉ

**Le problème** : E-Phy change chaque mardi soir. Aujourd'hui, une nouvelle
version de l'app est nécessaire pour chaque mise à jour.

**La solution retenue : GitHub Releases comme CDN** (gratuit, sans serveur).

1. Workflow GitHub Actions `update-data.yml`, cron le mercredi 4 h UTC :
   - télécharge l'archive CSV Anses ;
   - lance `dart tool/build_dataset.dart` ;
   - calcule les empreintes SHA-256 et publie une release `data-AAAA-MM-JJ`
     avec `phytia_core.json.gz`, `phytia_details.json.gz` et `manifest.json`.
2. Dans l'app : bouton « Vérifier les mises à jour » (écran À propos) :
   - lit `manifest.json` (≈ 0,5 Ko) ;
   - compare la date avec celle du catalogue en mémoire ;
   - télécharge les 2 fichiers (1,6 Mo), vérifie le SHA-256 ;
   - les écrit dans `getApplicationSupportDirectory()/data/` ;
   - recharge le catalogue à chaud.
3. Au démarrage : priorité au fichier local s'il est valide, sinon l'asset
   embarqué (l'app reste utilisable hors ligne même après une mise à jour ratée).

Écarté : reconstruire la base depuis les CSV sur le téléphone (38 Mo à parser,
10-30 s et risque mémoire sur Android d'entrée de gamme).

## P2 — Parcelles et carnet de traitement — LIVRÉ

Ce qui transforme l'app d'annuaire en outil quotidien, et ce qu'E-Phy ne fait pas.

**Modèle**
```
parcelle    (id, nom, culture, surface_ha, note)
traitement  (id, parcelle_id, date, amm, cible, dose, unite,
             surface_traitee_ha, stade_bbch, operateur, certiphyto, note)
```

**Écrans**
- Liste des parcelles, puis historique de chaque parcelle.
- « Nouveau traitement » prérempli depuis une fiche produit (produit, dose,
  cible, stade) : on ne saisit que la parcelle et la date.
- Après enregistrement : **date de récolte possible** calculée à partir du DAR
  (« ne pas récolter avant le … »), et alerte si le produit a été retiré depuis.
- Export **CSV + PDF** du carnet (contrôles, HVE, certification, clients).

## P3 — Confort terrain (≈ 1 jour)

- Ajout au stock en un tap depuis les résultats de recherche.
- Recherche par numéro d'AMM, tri par DAR, filtre biocontrôle.
- Mode sombre (utile le soir), tailles de texte accessibles.
- Derniers produits consultés.

## P4 — Distribution (≈ 1-2 jours + délais)

- APK signé (keystore à générer et conserver), installeur Windows (Inno Setup).
- Fiche Play Store, capture d'écran, politique de confidentialité (aucune donnée).
- Rappel des mentions E-Phy : source « Données E-Phy — Anses », date de mise à
  jour, caractère non opposable.

## P5 — Plus tard

- Alertes météo / BSV (mildiou, septoriose) : nécessite un fournisseur météo.
- Calcul automatique de la dose par parcelle (surface × dose/ha).
- Partage du carnet entre appareils (export/import chiffré, sans compte).
- iOS.

## Recommandation

**P1 d'abord** : sans mise à jour, l'app se périme en quelques semaines et perd
sa crédibilité (un produit retiré reste affiché comme autorisé).
**P2 ensuite** : c'est la brique qui crée l'usage quotidien.

Ce qu'il me faut pour P1 : un dépôt GitHub pour l'Action (public ou privé), et
l'accord pour que l'app appelle `github.com` (seul appel réseau de l'app).