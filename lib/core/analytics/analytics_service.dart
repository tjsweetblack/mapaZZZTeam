import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Ponto unico de registo de metricas de utilizacao.
///
/// Todas as chamadas sao "best effort": se o Analytics falhar, a app continua
/// a funcionar normalmente. Os eventos aqui definidos sao os que alimentam os
/// numeros de adesao e participacao do piloto.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> _log(String name,
      [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics: falha ao registar "$name": $e');
    }
  }

  /// Utilizador criou conta.
  static Future<void> signUp(String method) =>
      _log('sign_up', {'method': method});

  /// Utilizador autenticou-se.
  static Future<void> login(String method) => _log('login', {'method': method});

  /// Reporte de foco submetido com sucesso. `riskLevel` 1-3 vem da analise IA.
  static Future<void> reportCreated({
    required int riskLevel,
    String? location,
  }) =>
      _log('report_created', {
        'risk_level': riskLevel,
        if (location != null && location.isNotEmpty) 'location': location,
      });

  /// Quiz educativo concluido.
  static Future<void> quizCompleted({required int score}) =>
      _log('quiz_completed', {'score': score});

  /// Utilizador entrou no raio de uma zona de risco e foi alertado.
  static Future<void> zoneAlert({required int riskLevel}) =>
      _log('zone_alert', {'risk_level': riskLevel});

  /// Rastreio do teste de epaludismo concluido.
  static Future<void> epaludismoCompleted() => _log('epaludismo_completed');

  /// Associa o uid ao perfil de analytics, para distinguir utilizadores.
  static Future<void> setUser(String? uid) async {
    try {
      await _analytics.setUserId(id: uid);
    } catch (e) {
      debugPrint('Analytics: falha ao definir utilizador: $e');
    }
  }
}
