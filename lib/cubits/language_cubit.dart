import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState {
  final Locale locale;

  LanguageState(this.locale);
}

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(LanguageState(const Locale('en'))) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      emit(LanguageState(Locale(languageCode)));
    }
  }

  Future<void> changeLocale(Locale newLocale) async {
    emit(LanguageState(newLocale));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
  }
}
