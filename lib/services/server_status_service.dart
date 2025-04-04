import 'package:adcda_inspector/models/server_status.dart';
import 'package:adcda_inspector/services/api_service.dart';

/// Service for checking server status and health
class ServerStatusService {
  final ApiService _apiService;
  
  // Endpoints
  static const String _aliveEndpoint = '/api/Alive';
  static const String _detailsEndpoint = '/api/Alive/details';
  static const String _healthEndpoint = '/api/Alive/health';

  ServerStatusService({ApiService? apiService}) 
    : _apiService = apiService ?? ApiService();

  /// Check if server is alive
  Future<AliveResponse> checkServerStatus() async {
    try {
      final response = await _apiService.get(_aliveEndpoint);
      return AliveResponse.fromJson(response);
    } catch (e) {
      return AliveResponse(isAlive: false, message: e.toString());
    }
  }

  /// Get detailed server status information
  Future<DetailedAliveResponse> getDetailedStatus() async {
    try {
      final response = await _apiService.get(_detailsEndpoint);
      return DetailedAliveResponse.fromJson(response);
    } catch (e) {
      return DetailedAliveResponse(isAlive: false, message: e.toString());
    }
  }

  /// Check server health
  Future<HealthCheckResponse> checkServerHealth() async {
    try {
      final response = await _apiService.get(_healthEndpoint);
      return HealthCheckResponse.fromJson(response);
    } catch (e) {
      // Create a default unhealthy response if API call fails
      return HealthCheckResponse(
        status: 'unhealthy',
        checks: {
          'api': HealthCheck(
            status: 'unhealthy',
            description: e.toString(),
          ),
        },
      );
    }
  }
}
