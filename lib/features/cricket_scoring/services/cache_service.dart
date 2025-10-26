// lib\features\cricket_scoring\services\cache_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_model.dart';
import '../models/player_match_stats_model.dart';

class CacheService {
  static const String _currentPlayersKey = 'current_players';
  static const String _matchStateKey = 'match_state';
  static const String _playerStatsKey = 'player_stats';
  static const String _dismissedPlayersKey = 'dismissed_players';
  static const String _drsReviewsKey = 'drs_reviews';

  static Future<void> saveCurrentPlayers({
    required String matchId,
    PlayerModel? striker,
    PlayerModel? nonStriker,
    PlayerModel? bowler,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final playersData = {
      'matchId': matchId,
      'striker': striker?.toMap(),
      'nonStriker': nonStriker?.toMap(),
      'bowler': bowler?.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_currentPlayersKey, jsonEncode(playersData));
  }

  static Future<Map<String, dynamic>?> loadCurrentPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final playersData = prefs.getString(_currentPlayersKey);
    if (playersData != null) {
      return jsonDecode(playersData);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> loadCurrentPlayersForMatch(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final playersData = prefs.getString(_currentPlayersKey);
    if (playersData != null) {
      final data = jsonDecode(playersData);

      if (data['matchId'] == matchId) {
        return data;
      } else {

        await prefs.remove(_currentPlayersKey);
        print('Cleared cache data from different match');
      }
    }
    return null;
  }

  static Future<void> saveMatchState({
    required String matchId,
    required int currentOver,
    required int currentBall,
    required int totalRuns,
    required int totalWickets,
    required double runRate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stateData = {
      'matchId': matchId,
      'currentOver': currentOver,
      'currentBall': currentBall,
      'totalRuns': totalRuns,
      'totalWickets': totalWickets,
      'runRate': runRate,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_matchStateKey, jsonEncode(stateData));
  }

  static Future<Map<String, dynamic>?> loadMatchState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateData = prefs.getString(_matchStateKey);
    if (stateData != null) {
      return jsonDecode(stateData);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> loadMatchStateForMatch(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final stateData = prefs.getString(_matchStateKey);
    if (stateData != null) {
      final data = jsonDecode(stateData);

      if (data['matchId'] == matchId) {
        return data;
      } else {

        await prefs.remove(_matchStateKey);
        print('Cleared match state cache from different match');
      }
    }
    return null;
  }

  static Future<void> savePlayerStats({
    required String matchId,
    required List<PlayerMatchStatsModel> battingStats,
    required List<PlayerMatchStatsModel> bowlingStats,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final statsData = {
      'matchId': matchId,
      'battingStats': battingStats.map((s) => s.toMap()).toList(),
      'bowlingStats': bowlingStats.map((s) => s.toMap()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_playerStatsKey, jsonEncode(statsData));
  }

  static Future<Map<String, dynamic>?> loadPlayerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsData = prefs.getString(_playerStatsKey);
    if (statsData != null) {
      return jsonDecode(statsData);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> loadPlayerStatsForMatch(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final statsData = prefs.getString(_playerStatsKey);
    if (statsData != null) {
      final data = jsonDecode(statsData);

      if (data['matchId'] == matchId) {
        return data;
      } else {

        await prefs.remove(_playerStatsKey);
        print('Cleared player stats cache from different match');
      }
    }
    return null;
  }

  static Future<void> saveDismissedPlayers({
    required String matchId,
    required List<String> dismissedPlayers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedData = {
      'matchId': matchId,
      'dismissedPlayers': dismissedPlayers,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_dismissedPlayersKey, jsonEncode(dismissedData));
  }

  static Future<List<String>> loadDismissedPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedData = prefs.getString(_dismissedPlayersKey);
    if (dismissedData != null) {
      final data = jsonDecode(dismissedData);
      return List<String>.from(data['dismissedPlayers'] ?? []);
    }
    return [];
  }

  static Future<void> saveDRSReviews({
    required String matchId,
    required int teamAReviews,
    required int teamBReviews,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final drsData = {
      'matchId': matchId,
      'teamAReviews': teamAReviews,
      'teamBReviews': teamBReviews,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_drsReviewsKey, jsonEncode(drsData));
  }

  static Future<Map<String, int>> loadDRSReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final drsData = prefs.getString(_drsReviewsKey);
    if (drsData != null) {
      final data = jsonDecode(drsData);
      return {
        'teamA': data['teamAReviews'] ?? 2,
        'teamB': data['teamBReviews'] ?? 2,
      };
    }
    return {'teamA': 2, 'teamB': 2};
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentPlayersKey);
    await prefs.remove(_matchStateKey);
    await prefs.remove(_playerStatsKey);
    await prefs.remove(_dismissedPlayersKey);
    await prefs.remove(_drsReviewsKey);
    print('🧹 [CacheService] All cache data cleared');
  }

  static Future<void> clearAllCacheData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentPlayersKey);
    await prefs.remove(_matchStateKey);
    await prefs.remove(_playerStatsKey);
    await prefs.remove(_dismissedPlayersKey);
    await prefs.remove(_drsReviewsKey);
    print('🧹 [CacheService] All cache data cleared (nuclear option)');
  }

  static Future<void> clearMatchCache(String matchId) async {
    final prefs = await SharedPreferences.getInstance();

    print('🧹 [CacheService] Clearing cache for match: $matchId');

    final playersData = prefs.getString(_currentPlayersKey);
    if (playersData != null) {
      try {
        final data = jsonDecode(playersData);
        if (data['matchId'] == matchId) {
          await prefs.remove(_currentPlayersKey);
          print('✅ [CacheService] Cleared current players cache for match: $matchId');
        }
      } catch (e) {

        await prefs.remove(_currentPlayersKey);
        print('⚠️ [CacheService] Cleared corrupted current players cache');
      }
    }

    final stateData = prefs.getString(_matchStateKey);
    if (stateData != null) {
      try {
        final data = jsonDecode(stateData);
        if (data['matchId'] == matchId) {
          await prefs.remove(_matchStateKey);
          print('✅ [CacheService] Cleared match state cache for match: $matchId');
        }
      } catch (e) {

        await prefs.remove(_matchStateKey);
        print('⚠️ [CacheService] Cleared corrupted match state cache');
      }
    }

    final statsData = prefs.getString(_playerStatsKey);
    if (statsData != null) {
      try {
        final data = jsonDecode(statsData);
        if (data['matchId'] == matchId) {
          await prefs.remove(_playerStatsKey);
          print('✅ [CacheService] Cleared player stats cache for match: $matchId');
        }
      } catch (e) {

        await prefs.remove(_playerStatsKey);
        print('⚠️ [CacheService] Cleared corrupted player stats cache');
      }
    }

    final dismissedData = prefs.getString(_dismissedPlayersKey);
    if (dismissedData != null) {
      try {
        final data = jsonDecode(dismissedData);
        if (data['matchId'] == matchId) {
          await prefs.remove(_dismissedPlayersKey);
          print('✅ [CacheService] Cleared dismissed players cache for match: $matchId');
        }
      } catch (e) {

        await prefs.remove(_dismissedPlayersKey);
        print('⚠️ [CacheService] Cleared corrupted dismissed players cache');
      }
    }

    final drsData = prefs.getString(_drsReviewsKey);
    if (drsData != null) {
      try {
        final data = jsonDecode(drsData);
        if (data['matchId'] == matchId) {
          await prefs.remove(_drsReviewsKey);
          print('✅ [CacheService] Cleared DRS reviews cache for match: $matchId');
        }
      } catch (e) {

        await prefs.remove(_drsReviewsKey);
        print('⚠️ [CacheService] Cleared corrupted DRS reviews cache');
      }
    }

    print('🎯 [CacheService] Cache clearing completed for match: $matchId');
  }
}