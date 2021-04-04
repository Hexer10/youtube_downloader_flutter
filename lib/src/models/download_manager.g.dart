// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_manager.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DownloadVideo _$DownloadVideoFromJson(Map<String, dynamic> json) {
  return DownloadVideo(
    json['id'] as int,
    json['path'] as String,
    json['title'] as String,
    json['size'] as String,
  )
    ..downloadPerc = json['downloadPerc'] as int
    ..downloadStatus =
        _$enumDecode(_$DownloadStatusEnumMap, json['downloadStatus']);
}

Map<String, dynamic> _$DownloadVideoToJson(DownloadVideo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'title': instance.title,
      'size': instance.size,
      'downloadPerc': instance.downloadPerc,
      'downloadStatus': _$DownloadStatusEnumMap[instance.downloadStatus],
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

const _$DownloadStatusEnumMap = {
  DownloadStatus.downloading: 'downloading',
  DownloadStatus.success: 'success',
  DownloadStatus.failed: 'failed',
};
