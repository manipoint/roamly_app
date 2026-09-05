/// Provider-qualified location selected by the user.
///
/// Home location provides recommendation context. It does not imply the
/// user's current GPS position or the departure point of every trip.
final class CanonicalLocation {
  const CanonicalLocation({
    required this.provider,
    required this.providerLocationId,
    required this.canonicalName,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  /// Namespace identifying the location provider.
  final String provider;

  /// Stable identifier within that provider's namespace.
  final String providerLocationId;

  /// Resolved display name, including relevant geographic context.
  final String canonicalName;

  /// Two-letter uppercase country code.
  final String countryCode;

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CanonicalLocation &&
            provider == other.provider &&
            providerLocationId == other.providerLocationId &&
            canonicalName == other.canonicalName &&
            countryCode == other.countryCode &&
            latitude == other.latitude &&
            longitude == other.longitude;
  }

  @override
  int get hashCode => Object.hash(
    provider,
    providerLocationId,
    canonicalName,
    countryCode,
    latitude,
    longitude,
  );
}
