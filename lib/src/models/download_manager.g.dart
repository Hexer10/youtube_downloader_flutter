// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_manager.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleTrack _$SingleTrackFromJson(Map<String, dynamic> json) {
  return SingleTrack(
    json['id'] as int,
    json['path'] as String,
    json['title'] as String,
    json['size'] as String,
    json['totalSize'] as int,
    _$enumDecodeNullable(_$StreamTypeEnumMap, json['streamType']) ??
        StreamType.video,
  )
    ..downloadPerc = json['downloadPerc'] as int
    ..downloadStatus =
        _$enumDecode(_$DownloadStatusEnumMap, json['downloadStatus'])
    ..downloadedBytes = json['downloadedBytes'] as int
    ..error = json['error'] as String;
}

Map<String, dynamic> _$SingleTrackToJson(SingleTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'size': instance.size,
      'totalSize': instance.totalSize,
      'streamType': _$StreamTypeEnumMap[instance.streamType],
      'path': instance.path,
      'downloadPerc': instance.downloadPerc,
      'downloadStatus': _$DownloadStatusEnumMap[instance.downloadStatus],
      'downloadedBytes': instance.downloadedBytes,
      'error': instance.error,
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

K? _$enumDecodeNullable<K, V>(
  Map<K, V> enumValues,
  dynamic source, {
  K? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<K, V>(enumValues, source, unknownValue: unknownValue);
}

const _$StreamTypeEnumMap = {
  StreamType.audio: 'audio',
  StreamType.video: 'video',
};

const _$DownloadStatusEnumMap = {
  DownloadStatus.downloading: 'downloading',
  DownloadStatus.success: 'success',
  DownloadStatus.failed: 'failed',
  DownloadStatus.muxing: 'muxing',
  DownloadStatus.canceled: 'canceled',
};

MuxedTrack _$MuxedTrackFromJson(Map<String, dynamic> json) {
  return MuxedTrack(
    json['id'] as int,
    json['path'] as String,
    json['title'] as String,
    json['size'] as String,
    json['totalSize'] as int,
    SingleTrack.fromJson(json['audio'] as Map<String, dynamic>),
    SingleTrack.fromJson(json['video'] as Map<String, dynamic>),
    streamType: _$enumDecode(_$StreamTypeEnumMap, json['streamType']),
  )
    ..downloadPerc = json['downloadPerc'] as int
    ..downloadStatus =
        _$enumDecode(_$DownloadStatusEnumMap, json['downloadStatus'])
    ..downloadedBytes = json['downloadedBytes'] as int
    ..error = json['error'] as String;
}

Map<String, dynamic> _$MuxedTrackToJson(MuxedTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'size': instance.size,
      'totalSize': instance.totalSize,
      'path': instance.path,
      'downloadPerc': instance.downloadPerc,
      'downloadStatus': _$DownloadStatusEnumMap[instance.downloadStatus],
      'downloadedBytes': instance.downloadedBytes,
      'error': instance.error,
      'audio': instance.audio,
      'video': instance.video,
      'streamType': _$StreamTypeEnumMap[instance.streamType],
    };
