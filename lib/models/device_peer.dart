class DevicePeer {
  final String id;
  final String name;
  final String deviceType; // 'desktop' or 'mobile'
  final String ip;
  final int httpPort;
  DateTime lastSeen;

  DevicePeer({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.ip,
    required this.httpPort,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'protocol': 'quickdrop_v1',
        'id': id,
        'name': name,
        'device_type': deviceType,
        'ip': ip,
        'http_port': httpPort,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

  factory DevicePeer.fromJson(Map<String, dynamic> json, String fallbackIp) {
    return DevicePeer(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Device',
      deviceType: json['device_type'] as String? ?? 'mobile',
      ip: (json['ip'] as String?)?.isNotEmpty == true ? json['ip'] as String : fallbackIp,
      httpPort: json['http_port'] as int? ?? 53318,
      lastSeen: DateTime.now(),
    );
  }

  bool get isDesktop => deviceType == 'desktop';
  bool get isMobile => deviceType == 'mobile';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevicePeer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class TransferItem {
  final String id;
  final String fileName;
  final int fileSize;
  final String filePath;
  final String senderName;
  final bool isIncoming;
  final DateTime timestamp;
  final bool success;

  TransferItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.filePath,
    required this.senderName,
    required this.isIncoming,
    required this.timestamp,
    required this.success,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
