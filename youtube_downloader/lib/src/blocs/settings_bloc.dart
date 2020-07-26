import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class SettingsModel extends Equatable {
  final bool darkMode;
  final String savePath;

  SettingsModel({this.darkMode = false, this.savePath});

  SettingsModel copyWith({bool darkMode, String savePath}) {
    return SettingsModel(
        darkMode: darkMode ?? this.darkMode,
        savePath: savePath ?? this.savePath);
  }

  @override
  List<Object> get props => [darkMode, savePath];
}

class SettingsBloc extends HydratedBloc<SettingsEvent, SettingsModel> {
  SettingsBloc() : super(SettingsModel());

  @override
  SettingsModel fromJson(Map<String, dynamic> json) {
    return SettingsModel(
        darkMode: json['darkMode'] as bool,
        savePath: json['savePath'] as String);
  }

  @override
  Map<String, dynamic> toJson(SettingsModel state) {
    var j = <String, dynamic>{'darkMode': state.darkMode};
    if (state.savePath != null) {
      j['savePath'] = state.savePath;
    }
    return j;
  }

  @override
  Stream<SettingsModel> mapEventToState(SettingsEvent event) async* {
    if (event is ToggleDarkMode) {
      yield state.copyWith(darkMode: event.value);
    }
    if (event is SetSavePath) {
      yield state.copyWith(savePath: event.path);
    }
  }
}

/* Events */
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
}

//class FetchSettings extends SettingsEvent {
//  const FetchSettings();
//
//  @override
//  List<Object> get props => [];
//}

class ToggleDarkMode extends SettingsEvent {
  final bool value;

  const ToggleDarkMode(this.value);

  @override
  List<Object> get props => [value];
}

class SetSavePath extends SettingsEvent {
  final String path;

  const SetSavePath(this.path);

  @override
  List<Object> get props => [path];
}

/* State */
//abstract class SettingsState extends Equatable {
//  const SettingsState();
//
//  List<Object> get props => [];
//}
//
//class SearchInitial extends SettingsState {
//  const SearchInitial();
//}
//
//class SearchLoading extends SettingsState {}
//
//class SearchSuccess extends SettingsState {
//  final List<Video> videos;
//
//  SearchSuccess({@required this.videos});
//
//  List<Object> get props => [videos];
//}

//class SearchFailure extends SettingsState {}
