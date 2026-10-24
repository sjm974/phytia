/// Configuration des mises à jour du catalogue.
///
/// Les fichiers sont publiés en « release » GitHub par le workflow
/// .github/workflows/update-data.yml. Remplacez CHANGER-MOI par votre compte
/// GitHub une fois le dépôt et la première release créés.
///
/// Peut aussi être surchargé au build :
///   `flutter build apk --dart-define=PHYTIA_DATA_BASE=https://github.com/<compte>/<dépôt>/releases/download/data/`
const String kDataReleaseBase = String.fromEnvironment(
  'PHYTIA_DATA_BASE',
  defaultValue: 'https://github.com/CHANGER-MOI/phytia/releases/download/data/',
);

/// Vrai quand l'adresse des mises à jour a été renseignée.
bool get isDataUpdateConfigured =>
    kDataReleaseBase.isNotEmpty && !kDataReleaseBase.contains('CHANGER-MOI');
