// lib\features\cricket_scoring\services\points_table_service.dart

import 'package:appwrite/appwrite.dart';
import '../models/match_model.dart';
import '../models/team_points_model.dart';
import '../models/team_match_model.dart';
import '../models/innings_model.dart';
import '../api/appwrite_constants.dart';
import '../models/team_model.dart';

class PointsTableService {
  final Databases databases;

  PointsTableService({required this.databases});

  Future<void> updatePointsTableAfterMatch(MatchModel match) async {
    try {
      print('🎯 Updating points table for match: ${match.id}');

      final teamAPoints = await _getTeamPointsForMatch(match.teamAId);
      final teamBPoints = await _getTeamPointsForMatch(match.teamBId);

      if (teamAPoints == null || teamBPoints == null) {
        print('⚠️ Could not find team points for teams: ${match.teamAId}, ${match.teamBId}');
        return;
      }

      await _updateBasicStats(teamAPoints, teamBPoints, match);

      final teamAInnings = await _getInningsForTeam(match.id, match.teamAId);
      final teamBInnings = await _getInningsForTeam(match.id, match.teamBId);

      if (teamAInnings != null && teamBInnings != null) {
        await _updateNetRunRate(teamAPoints, teamBPoints, teamAInnings, teamBInnings);
      }

      await _createTeamMatchLogs(teamAPoints.id, teamBPoints.id, match);

      await _saveTeamPoints(teamAPoints);
      await _saveTeamPoints(teamBPoints);

      print('✅ Points table updated successfully');
    } catch (e) {
      print('❌ Error updating points table: $e');
      rethrow;
    }
  }

  Future<void> createTeamMatchLog({
    required String pointsTableId,
    required String teamId,
    required String matchId,
    required String opponentId,
    required String opponentName,
    required String result,
    required String description,
    required DateTime matchDate,
  }) async {
    try {
      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.teamMatchesCollection,
        documentId: ID.unique(),
        data: {
          'teamPointsId': pointsTableId,
          'matchId': matchId,
          'opponentId': opponentId,
          'opponentName': opponentName,
          'result': result,
          'description': description,
          'matchDate': matchDate.toIso8601String(),
          'isCompleted': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error creating team match log: $e');
    }
  }

  Future<TeamPointsModel?> _getTeamPointsForMatch(String teamId) async {
    try {

      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.teamPointsCollection,
        queries: [
          Query.equal('teamId', teamId),
        ],
      );

      if (response.documents.isNotEmpty) {
        return TeamPointsModel.fromMap(response.documents.first.data);
      }
      return null;
    } catch (e) {
      print('Error getting team points for team $teamId: $e');
      return null;
    }
  }

  Future<void> _updateBasicStats(
    TeamPointsModel teamA,
    TeamPointsModel teamB,
    MatchModel match,
  ) async {

    final updatedTeamA = teamA.copyWith(
      matchesPlayed: teamA.matchesPlayed + 1,
      updatedAt: DateTime.now(),
    );

    final updatedTeamB = teamB.copyWith(
      matchesPlayed: teamB.matchesPlayed + 1,
      updatedAt: DateTime.now(),
    );

    final isTie = match.resultSummary?.toLowerCase().contains('tie') ?? false;
    final isNoResult = match.resultSummary?.toLowerCase().contains('no result') ?? false;
    final winnerId = match.winnerTeamId;

    if (isNoResult) {

      await _saveTeamPoints(updatedTeamA.copyWith(
        noResult: teamA.noResult + 1,
        points: teamA.points + 1,
      ));
      await _saveTeamPoints(updatedTeamB.copyWith(
        noResult: teamB.noResult + 1,
        points: teamB.points + 1,
      ));
    } else if (isTie) {

      await _saveTeamPoints(updatedTeamA.copyWith(
        matchesTied: teamA.matchesTied + 1,
        points: teamA.points + 1,
      ));
      await _saveTeamPoints(updatedTeamB.copyWith(
        matchesTied: teamB.matchesTied + 1,
        points: teamB.points + 1,
      ));
    } else if (winnerId == match.teamAId) {

      await _saveTeamPoints(updatedTeamA.copyWith(
        matchesWon: teamA.matchesWon + 1,
        points: teamA.points + 2,
      ));
      await _saveTeamPoints(updatedTeamB.copyWith(
        matchesLost: teamB.matchesLost + 1,
      ));
    } else if (winnerId == match.teamBId) {

      await _saveTeamPoints(updatedTeamA.copyWith(
        matchesLost: teamA.matchesLost + 1,
      ));
      await _saveTeamPoints(updatedTeamB.copyWith(
        matchesWon: teamB.matchesWon + 1,
        points: teamB.points + 2,
      ));
    }
  }

  Future<void> _updateNetRunRate(
    TeamPointsModel teamA,
    TeamPointsModel teamB,
    InningsModel teamAInnings,
    InningsModel teamBInnings,
  ) async {

    final newRunsScoredA = teamA.totalRunsScored + teamAInnings.runs;
    final newOversFacedA = teamA.totalOversFaced + teamAInnings.overs;
    final newRunsConcededA = teamA.totalRunsConceded + teamBInnings.runs;
    final newOversBowledA = teamA.totalOversBowled + teamBInnings.overs;

    final newRunsScoredB = teamB.totalRunsScored + teamBInnings.runs;
    final newOversFacedB = teamB.totalOversFaced + teamBInnings.overs;
    final newRunsConcededB = teamB.totalRunsConceded + teamAInnings.runs;
    final newOversBowledB = teamB.totalOversBowled + teamAInnings.overs;

    final nrrA = newOversFacedA > 0 && newOversBowledA > 0
        ? (newRunsScoredA / newOversFacedA) - (newRunsConcededA / newOversBowledA)
        : 0.0;

    final nrrB = newOversFacedB > 0 && newOversBowledB > 0
        ? (newRunsScoredB / newOversFacedB) - (newRunsConcededB / newOversBowledB)
        : 0.0;

    await _saveTeamPoints(teamA.copyWith(
      totalRunsScored: newRunsScoredA,
      totalOversFaced: newOversFacedA,
      totalRunsConceded: newRunsConcededA,
      totalOversBowled: newOversBowledA,
      netRunRate: nrrA,
      updatedAt: DateTime.now(),
    ));

    await _saveTeamPoints(teamB.copyWith(
      totalRunsScored: newRunsScoredB,
      totalOversFaced: newOversFacedB,
      totalRunsConceded: newRunsConcededB,
      totalOversBowled: newOversBowledB,
      netRunRate: nrrB,
      updatedAt: DateTime.now(),
    ));

    print('📊 NRR updated - Team A: ${nrrA.toStringAsFixed(3)}, Team B: ${nrrB.toStringAsFixed(3)}');
    print('📊 Cumulative totals - A: ${newRunsScoredA}r/${newOversFacedA}ov, B: ${newRunsScoredB}r/${newOversFacedB}ov');
  }

  Future<InningsModel?> _getInningsForTeam(String matchId, String teamId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.inningsCollection,
        queries: [
          Query.equal('matchId', matchId),
          Query.equal('battingTeamId', teamId),
        ],
      );

      if (response.documents.isNotEmpty) {
        final data = response.documents.first.data;
        return InningsModel.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error getting innings for team $teamId: $e');
      return null;
    }
  }

  Future<List<TeamMatchModel>> getTeamMatchesFromTeamPoints(String teamPointsId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.teamMatchesCollection,
        queries: [
          Query.equal('teamPointsId', teamPointsId),
          Query.orderDesc('matchDate'),
        ],
      );

      return response.documents
          .map((doc) => TeamMatchModel.fromMap(doc.data))
          .toList();
    } catch (e) {
      print('Error getting team matches: $e');
      return [];
    }
  }

  Future<void> _createTeamMatchLogs(
    String teamAPointsId,
    String teamBPointsId,
    MatchModel match,
  ) async {
    try {
      final isTie = match.resultSummary?.toLowerCase().contains('tie') ?? false;
      final isNoResult = match.resultSummary?.toLowerCase().contains('no result') ?? false;
      final winnerId = match.winnerTeamId;

      final teamA = await _getTeamById(match.teamAId);
      final teamB = await _getTeamById(match.teamBId);

      final teamAName = teamA?.name ?? 'Unknown';
      final teamBName = teamB?.name ?? 'Unknown';

      String resultA;
      if (isTie) {
        resultA = 'T';
      } else if (isNoResult) {
        resultA = 'NR';
      } else if (winnerId == match.teamAId) {
        resultA = 'W';
      } else {
        resultA = 'L';
      }

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.teamMatchesCollection,
        documentId: ID.unique(),
        data: {
          'teamPointsId': teamAPointsId,
          'matchId': match.id,
          'opponentId': match.teamBId,
          'opponentName': teamBName,
          'result': resultA,
          'description': match.resultSummary ?? '',
          'matchDate': match.matchDateTime.toIso8601String(),
          'isCompleted': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      String resultB;
      if (isTie) {
        resultB = 'T';
      } else if (isNoResult) {
        resultB = 'NR';
      } else if (winnerId == match.teamBId) {
        resultB = 'W';
      } else {
        resultB = 'L';
      }

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.teamMatchesCollection,
        documentId: ID.unique(),
        data: {
          'teamPointsId': teamBPointsId,
          'matchId': match.id,
          'opponentId': match.teamAId,
          'opponentName': teamAName,
          'result': resultB,
          'description': match.resultSummary ?? '',
          'matchDate': match.matchDateTime.toIso8601String(),
          'isCompleted': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Team match logs created');
    } catch (e) {
      print('Error creating team match logs: $e');
    }
  }

  Future<void> _saveTeamPoints(TeamPointsModel teamPoints) async {
    try {
      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.teamPointsCollection,
        documentId: teamPoints.id,
        data: teamPoints.toMap(),
      );
    } catch (e) {
      print('Error saving team points: $e');
      rethrow;
    }
  }

  Future<TeamModel?> _getTeamById(String teamId) async {
    try {
      final response = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.teamsCollection,
        documentId: teamId,
      );
      return TeamModel.fromMap(response.data);
    } catch (e) {
      print('Error getting team $teamId: $e');
      return null;
    }
  }

  Future<List<String>> getQualifiedTeams(String pointsTableId, int qualifiedTeamsCount) async {
    try {

      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.teamPointsCollection,
        queries: [
          Query.equal('pointsTableId', pointsTableId),
          Query.orderDesc('points'),
          Query.orderDesc('netRunRate'),
        ],
      );

      final teamPointsList = response.documents
          .map((doc) => TeamPointsModel.fromMap(doc.data))
          .toList();

      final qualifiedTeamIds = <String>[];
      for (int i = 0; i < teamPointsList.length; i++) {
        final teamPoints = teamPointsList[i];
        if (i < qualifiedTeamsCount) {

          qualifiedTeamIds.add(teamPoints.teamId);
          await _saveTeamPoints(teamPoints.copyWith(
            qualificationStatus: 'Q',
            updatedAt: DateTime.now(),
          ));
        } else {

          await _saveTeamPoints(teamPoints.copyWith(
            qualificationStatus: 'E',
            updatedAt: DateTime.now(),
          ));
        }
      }

      print('✅ Qualified teams: $qualifiedTeamIds');
      return qualifiedTeamIds;
    } catch (e) {
      print('❌ Error getting qualified teams: $e');
      rethrow;
    }
  }

  Future<List<TeamMatchModel>> getTeamRecentMatches(String teamPointsId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.teamMatchesCollection,
        queries: [
          Query.equal('teamPointsId', teamPointsId),
          Query.orderDesc('matchDate'),
          Query.limit(5),
        ],
      );

      return response.documents
          .map((doc) => TeamMatchModel.fromMap(doc.data))
          .toList();
    } catch (e) {
      print('Error getting team recent matches: $e');
      return [];
    }
  }

  Future<String> endGroupAndQualifyTeams({
    required String tournamentId,
    required String groupName,
    required String pointsTableId,
    int? qualifiedTeamsCount,
  }) async {
    try {
      print('🏁 Ending group: $groupName');

      int teamsToQualify = qualifiedTeamsCount ?? 2;

      final qualifiedTeamIds = await getQualifiedTeams(pointsTableId, teamsToQualify);

      if (qualifiedTeamIds.isEmpty) {
        throw Exception('No teams qualified from group');
      }

      print('✅ Qualified teams from $groupName: ${qualifiedTeamIds.length}');

      if (qualifiedTeamIds.length == 2) {

        return await _createFinalStage(
          tournamentId: tournamentId,
          qualifiedTeamIds: qualifiedTeamIds,
        );
      } else {

        return await _createNextStage(
          tournamentId: tournamentId,
          qualifiedTeamIds: qualifiedTeamIds,
          currentStageName: groupName,
        );
      }
    } catch (e) {
      print('❌ Error ending group: $e');
      rethrow;
    }
  }

  Future<String> _createFinalStage({
    required String tournamentId,
    required List<String> qualifiedTeamIds,
  }) async {
    try {
      print('🏆 Creating FINAL stage');

      final finalStageId = ID.unique();

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tournamentStagesCollection,
        documentId: finalStageId,
        data: {
          'tournamentId': tournamentId,
          'name': 'Final',
          'type': 'final',
          'teamIds': qualifiedTeamIds,
          'isCompleted': false,
          'nextStageId': null,
          'qualifiedTeamsCount': 2,
          'maxQualifiedTeams': 2,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      final pointsTableId = ID.unique();
      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.pointsTablesCollection,
        documentId: pointsTableId,
        data: {
          'groupName': 'Final',
          'tournamentName': '',
          'teamIds': qualifiedTeamIds,
          'createdBy': 'system',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      for (final teamId in qualifiedTeamIds) {
        final team = await _getTeamById(teamId);
        if (team != null) {
          await databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.teamPointsCollection,
            documentId: ID.unique(),
            data: {
              'pointsTableId': pointsTableId,
              'teamId': teamId,
              'teamName': team.name,
              'matchesPlayed': 0,
              'matchesWon': 0,
              'matchesLost': 0,
              'matchesTied': 0,
              'noResult': 0,
              'points': 0,
              'netRunRate': 0.0,
              'qualificationStatus': '',
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            },
          );
        }
      }

      print('✅ Final stage created with ID: $finalStageId');
      return finalStageId;
    } catch (e) {
      print('❌ Error creating Final stage: $e');
      rethrow;
    }
  }

  Future<String> _createNextStage({
    required String tournamentId,
    required List<String> qualifiedTeamIds,
    required String currentStageName,
  }) async {
    try {
      print('🏁 Creating next stage for ${qualifiedTeamIds.length} teams');

      final nextStageId = ID.unique();
      final stageName = _getNextStageName(currentStageName, qualifiedTeamIds.length);

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tournamentStagesCollection,
        documentId: nextStageId,
        data: {
          'tournamentId': tournamentId,
          'name': stageName,
          'type': _getStageType(qualifiedTeamIds.length),
          'teamIds': qualifiedTeamIds,
          'isCompleted': false,
          'nextStageId': null,
          'qualifiedTeamsCount': _getNextQualifiedCount(qualifiedTeamIds.length),
          'maxQualifiedTeams': _getNextQualifiedCount(qualifiedTeamIds.length),
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      final pointsTableId = ID.unique();
      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.pointsTablesCollection,
        documentId: pointsTableId,
        data: {
          'groupName': stageName,
          'tournamentName': '',
          'teamIds': qualifiedTeamIds,
          'createdBy': 'system',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      for (final teamId in qualifiedTeamIds) {
        final team = await _getTeamById(teamId);
        if (team != null) {
          await databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.teamPointsCollection,
            documentId: ID.unique(),
            data: {
              'pointsTableId': pointsTableId,
              'teamId': teamId,
              'teamName': team.name,
              'matchesPlayed': 0,
              'matchesWon': 0,
              'matchesLost': 0,
              'matchesTied': 0,
              'noResult': 0,
              'points': 0,
              'netRunRate': 0.0,
              'qualificationStatus': '',
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            },
          );
        }
      }

      print('✅ Next stage created: $stageName with ID: $nextStageId');
      return nextStageId;
    } catch (e) {
      print('❌ Error creating next stage: $e');
      rethrow;
    }
  }

  String _getNextStageName(String currentStage, int teamCount) {
    if (teamCount == 2) {
      return 'Final';
    } else if (teamCount == 4) {
      return 'Semi-Finals';
    } else if (teamCount == 8) {
      return 'Quarter-Finals';
    } else {
      return 'Stage ${teamCount} Teams';
    }
  }

  String _getStageType(int teamCount) {
    if (teamCount == 2) {
      return 'final';
    } else if (teamCount <= 4) {
      return 'knockout';
    } else {
      return 'round-robin';
    }
  }

  int _getNextQualifiedCount(int currentTeamCount) {
    if (currentTeamCount <= 4) {
      return (currentTeamCount / 2).ceil();
    } else {
      return (currentTeamCount / 2).ceil();
    }
  }

  Future<String?> endStageAndProgress({
    required String tournamentId,
    required String stageId,
    required String pointsTableId,
  }) async {
    try {
      print('🏁 Ending stage: $stageId');

      final stageDoc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tournamentStagesCollection,
        documentId: stageId,
      );

      final stageType = stageDoc.data['type'] as String;
      final teamIds = (stageDoc.data['teamIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

      print('Stage type: $stageType, Teams: ${teamIds.length}');

      final qualifiedTeamIds = await getQualifiedTeams(pointsTableId, teamIds.length ~/ 2);

      if (qualifiedTeamIds.isEmpty) {
        throw Exception('No teams qualified from stage');
      }

      print('✅ Qualified teams: ${qualifiedTeamIds.length}');

      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tournamentStagesCollection,
        documentId: stageId,
        data: {
          'isCompleted': true,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      if (qualifiedTeamIds.length == 2) {
        return await _createFinalStage(
          tournamentId: tournamentId,
          qualifiedTeamIds: qualifiedTeamIds,
        );
      } else {

        return await _createNextStage(
          tournamentId: tournamentId,
          qualifiedTeamIds: qualifiedTeamIds,
          currentStageName: stageDoc.data['name'] as String,
        );
      }
    } catch (e) {
      print('❌ Error ending stage: $e');
      rethrow;
    }
  }

  Future<bool> isGroupCompleted(String pointsTableId) async {
    try {
      final response = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.pointsTablesCollection,
        documentId: pointsTableId,
      );

      final teamIds = (response.data['teamIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

      final totalMatches = (teamIds.length * (teamIds.length - 1)) ~/ 2;

      int completedCount = 0;
      for (int i = 0; i < teamIds.length; i++) {
        for (int j = i + 1; j < teamIds.length; j++) {
          final matches = await databases.listDocuments(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.matchesCollection,
            queries: [
              Query.or([
                Query.and([
                  Query.equal('teamAId', teamIds[i]),
                  Query.equal('teamBId', teamIds[j]),
                ]),
                Query.and([
                  Query.equal('teamAId', teamIds[j]),
                  Query.equal('teamBId', teamIds[i]),
                ]),
              ]),
              Query.equal('status', ['Completed', 'Finished']),
            ],
          );

          if (matches.documents.isNotEmpty) {
            completedCount++;
          }
        }
      }

      return completedCount >= totalMatches;
    } catch (e) {
      print('Error checking group completion: $e');
      return false;
    }
  }
}
