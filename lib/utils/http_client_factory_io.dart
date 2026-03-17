import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createHttpClient() {
  final client = HttpClient();

  // Dev-only: accept self-signed certificates for local backend.
  if (!kReleaseMode) {
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
  }

  return IOClient(client);
}
