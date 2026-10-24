/// Configuration des mises à jour du catalogue.
///
/// Les fichiers sont publiés en « release » GitHub par le workflow
/// .github/workflows/update-data.yml. L'adresse pointe sur le compte sjm974 ;
/// adaptez-la si le dépôt change de nom ou de propriétaire.
///
/// Peut aussi être surchargé au build :
///   `flutter build apk --dart-define=PHYTIA_DATA_BASE=<autre adresse>`
const String kDataReleaseBase = String.fromEnvironment(
  'PHYTIA_DATA_BASE',
  defaultValue: 'https://github.com/sjm974/phytia/releases/download/data/',
);

/// Vrai quand l'adresse des mises à jour a été renseignée.
bool get isDataUpdateConfigured =>
    kDataReleaseBase.isNotEmpty && !kDataReleaseBase.contains('CHANGER-MOI');
