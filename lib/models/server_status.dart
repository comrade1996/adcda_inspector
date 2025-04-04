/// Models for the server status endpoints

/// Basic alive response
class AliveResponse {
  final bool isAlive;
  final String? version;
  final String? message;

  AliveResponse({
    required this.isAlive,
    this.version,
    this.message,
  });

  factory AliveResponse.fromJson(Map<String, dynamic> json) {
    return AliveResponse(
      isAlive: json['isAlive'] ?? false,
      version: json['version'],
      message: json['message'],
    );
  }
}

/// Detailed alive response with additional info
class DetailedAliveResponse {
  final bool isAlive;
  final String? version;
  final String? environment;
  final String? serverTime;
  final String? message;
  final int? apiVersion;

  DetailedAliveResponse({
    required this.isAlive,
    this.version,
    this.environment,
    this.serverTime,
    this.message,
    this.apiVersion,
  });

  factory DetailedAliveResponse.fromJson(Map<String, dynamic> json) {
    return DetailedAliveResponse(
      isAlive: json['isAlive'] ?? false,
      version: json['version'],
      environment: json['environment'],
      serverTime: json['serverTime'],
      message: json['message'],
      apiVersion: json['apiVersion'],
    );
  }
}

/// Health check status
enum HealthStatus {
  healthy,
  unhealthy,
  degraded,
  unknown,
}

/// Individual health check result
class HealthCheck {
  final String status;
  final String? description;
  final Map<String, dynamic>? data;

  HealthCheck({
    required this.status,
    this.description,
    this.data,
  });

  factory HealthCheck.fromJson(Map<String, dynamic> json) {
    return HealthCheck(
      status: json['status'] ?? 'Unknown',
      description: json['description'],
      data: json['data'],
    );
  }

  HealthStatus get healthStatus {
    switch (status.toLowerCase()) {
      case 'healthy':
        return HealthStatus.healthy;
      case 'unhealthy':
        return HealthStatus.unhealthy;
      case 'degraded':
        return HealthStatus.degraded;
      default:
        return HealthStatus.unknown;
    }
  }
}

/// Overall health check response
class HealthCheckResponse {
  final String status;
  final Map<String, HealthCheck> checks;
  final String? totalDuration;

  HealthCheckResponse({
    required this.status,
    required this.checks,
    this.totalDuration,
  });

  factory HealthCheckResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, HealthCheck> checksMap = {};
    if (json['checks'] != null) {
      json['checks'].forEach((key, value) {
        checksMap[key] = HealthCheck.fromJson(value);
      });
    }

    return HealthCheckResponse(
      status: json['status'] ?? 'Unknown',
      checks: checksMap,
      totalDuration: json['totalDuration'],
    );
  }

  HealthStatus get healthStatus {
    switch (status.toLowerCase()) {
      case 'healthy':
        return HealthStatus.healthy;
      case 'unhealthy':
        return HealthStatus.unhealthy;
      case 'degraded':
        return HealthStatus.degraded;
      default:
        return HealthStatus.unknown;
    }
  }
}
