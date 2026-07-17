abstract interface class PreviewMethodHandler {
  Set<String> get supportedMethods;

  Future<Object?> invoke(String method, Object? arguments);
}
