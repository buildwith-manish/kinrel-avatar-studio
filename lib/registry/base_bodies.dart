/// Catalog of the 12 base body types supported by V1.
///
/// Each entry corresponds to a folder under `assets/avatars/base/<id>/`
/// containing a `body.png` file. The IDs are stable — they appear in
/// saved [AvatarConfig] JSON — so never rename them.
///
/// The age ranges are display-only metadata used by the editor UI to
/// help users pick the right base; they are not enforced anywhere.
class BaseBody {
  final String id;
  final String label;
  final String ageRange;
  final Gender gender;

  const BaseBody({
    required this.id,
    required this.label,
    required this.ageRange,
    required this.gender,
  });

  /// Folder name under `assets/avatars/base/` that holds this body's
  /// `body.png`. Currently identical to [id], kept as a separate field
  /// so we can later decouple display ID from folder name if needed.
  String get folderName => id;

  /// Whether facial hair layers should be offered for this body.
  bool get supportsFacialHair => gender == Gender.male;
}

enum Gender { male, female }

/// The canonical V1 base-body list, in the order they should appear in
/// the editor's base-body picker (age-ascending, male-then-female
/// within each age band).
const List<BaseBody> kBaseBodies = <BaseBody>[
  BaseBody(
    id: 'child_male',
    label: 'Child Male',
    ageRange: '5-9',
    gender: Gender.male,
  ),
  BaseBody(
    id: 'child_female',
    label: 'Child Female',
    ageRange: '5-9',
    gender: Gender.female,
  ),
  BaseBody(
    id: 'preteen_male',
    label: 'Pre-teen Male',
    ageRange: '10-12',
    gender: Gender.male,
  ),
  BaseBody(
    id: 'preteen_female',
    label: 'Pre-teen Female',
    ageRange: '10-12',
    gender: Gender.female,
  ),
  BaseBody(
    id: 'teen_male',
    label: 'Teen Male',
    ageRange: '13-17',
    gender: Gender.male,
  ),
  BaseBody(
    id: 'teen_female',
    label: 'Teen Female',
    ageRange: '13-17',
    gender: Gender.female,
  ),
  BaseBody(
    id: 'adult_male',
    label: 'Adult Male',
    ageRange: '20-45',
    gender: Gender.male,
  ),
  BaseBody(
    id: 'adult_female',
    label: 'Adult Female',
    ageRange: '20-45',
    gender: Gender.female,
  ),
  BaseBody(
    id: 'middle_male',
    label: 'Middle-aged Male',
    ageRange: '46-59',
    gender: Gender.male,
  ),
  BaseBody(
    id: 'middle_female',
    label: 'Middle-aged Female',
    ageRange: '46-59',
    gender: Gender.female,
  ),
  BaseBody(
    id: 'elderly_male',
    label: 'Elderly Male',
    ageRange: '60+',
    gender: Gender.male,
  ),
  BaseBody(
    id: 'elderly_female',
    label: 'Elderly Female',
    ageRange: '60+',
    gender: Gender.female,
  ),
];

/// Lookup helper.
BaseBody? baseBodyById(String? id) {
  if (id == null) return null;
  for (final b in kBaseBodies) {
    if (b.id == id) return b;
  }
  return null;
}
