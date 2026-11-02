import '../core/file_utils.dart';
import 'link.dart';

class DevicePeer {
  final String id;
  final String name;
  final String deviceType; // 'desktop' or 'mobile'
  final String ip;
  final int httpPort;
  final bool isManual;

  /// How this peer was observed. Local metadata only; never advertised.
  final LinkKind link;
  DateTime lastSeen;

  DevicePeer({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.ip,
    required this.httpPort,
    this.isManual = false,
    this.link = LinkKind.unknown,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'protocol': 'quickdrop_v1',
        'id': id,
        'name': name,
        'device_type': deviceType,
        'ip': ip,
        'http_port': httpPort,
        'manual': isManual,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

  factory DevicePeer.fromJson(Map<String, dynamic> json, String fallbackIp) {
    return DevicePeer(
      id: json['id'] as String? ?? 'device_$fallbackIp',
      name: json['name'] as String? ?? 'Device',
      deviceType: json['device_type'] as String? ?? 'mobile',
      ip: fallbackIp,
      httpPort: (json['http_port'] as num?)?.toInt() ?? 53318,
      isManual: json['manual'] as bool? ?? false,
      lastSeen: DateTime.now(),
    );
  }

  bool get isDesktop => deviceType == 'desktop';
  bool get isMobile => deviceType == 'mobile';

  String get address => '$ip:$httpPort';

  DevicePeer copyWith({
    String? name,
    String? deviceType,
    String? ip,
    int? httpPort,
    bool? isManual,
    LinkKind? link,
    DateTime? lastSeen,
  }) {
    return DevicePeer(
      id: id,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      ip: ip ?? this.ip,
      httpPort: httpPort ?? this.httpPort,
      isManual: isManual ?? this.isManual,
      link: link ?? this.link,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevicePeer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class TransferItem {
  final String id;
  final String fileName;
  final int fileSize;
  final String filePath;
  final String? contentUri;
  final String senderName;
  final bool isIncoming;
  final DateTime timestamp;
  final bool success;
  final String? batchId;

  TransferItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.filePath,
    required this.senderName,
    required this.isIncoming,
    required this.timestamp,
    required this.success,
    this.contentUri,
    this.batchId,
  });

  bool get isImage => FileUtils.isImage(fileName);

  String get formattedSize => FileUtils.formatBytes(fileSize);

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'file_size': fileSize,
        'file_path': filePath,
        'content_uri': contentUri,
        'sender_name': senderName,
        'is_incoming': isIncoming,
        'timestamp': timestamp.toIso8601String(),
        'success': success,
        'batch_id': batchId,
      };

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      id: json['id'] as String? ?? 'tx_${DateTime.now().microsecondsSinceEpoch}',
      fileName: json['file_name'] as String? ?? 'file',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      filePath: json['file_path'] as String? ?? '',
      contentUri: json['content_uri'] as String?,
      senderName: json['sender_name'] as String? ?? 'Unknown',
      isIncoming: json['is_incoming'] as bool? ?? true,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      success: json['success'] as bool? ?? true,
      batchId: json['batch_id'] as String?,
    );
  }
}
