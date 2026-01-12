import '../../services/api_client.dart';

String formatApiError(Object error, {required String endpointName}) {
  if (error is ApiRequestException) {
    return error.displayMessage;
  }
  return "Error in $endpointName • $error";
}

String? extractApiMessage(ApiResponse response) {
  if (response.status == 200) return null;
  final json = response.json;
  final message = json?["message"] ?? json?["error"] ?? json?["detail"];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }
  final rawBody = response.rawBody;
  if (rawBody != null && rawBody.trim().isNotEmpty) {
    return rawBody.trim();
  }
  return "HTTP ${response.status}";
}
