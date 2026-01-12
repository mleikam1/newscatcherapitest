import '../../services/api_client.dart';

String formatApiError(Object error, {required String endpointName}) {
  if (error is ApiRequestException) {
    return error.displayMessage;
  }
  return "Error in $endpointName • $error";
}
