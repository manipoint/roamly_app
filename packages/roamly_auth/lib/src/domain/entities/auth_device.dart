/// Identifies the current Roamly app installation.
final class AuthDevice {
  /// Stable identifier generated for this app installation.
  final String id;

  /// Best-effort human-readable device label.
  final String? name;

  const AuthDevice({required this.id, this.name});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthDevice && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}
