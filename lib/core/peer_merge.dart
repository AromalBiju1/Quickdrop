import '../models/device_peer.dart';
import '../models/link.dart';

/// Merges one link observation into the stored peer for the same device.
///
/// The same phone can answer over Wi-Fi and a USB tether at the same time. It
/// must stay one card, with the faster link's address.
DevicePeer mergePeerObservation(
  DevicePeer? existing,
  DevicePeer incoming,
  LinkKind link,
) {
  final observed = incoming.copyWith(
    link: link,
    lastSeen: DateTime.now(),
  );
  if (existing == null) return observed;

  final manual = existing.isManual || observed.isManual;
  if (link.rank >= existing.link.rank) {
    // Faster link wins; equal rank means the newest observation is freshest.
    return observed.copyWith(isManual: manual);
  }

  return existing.copyWith(
    isManual: manual,
    lastSeen: observed.lastSeen,
  );
}
