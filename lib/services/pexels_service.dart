import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:snapalyze/models/photo_model.dart';

const pexelApiKey = 'R6zlLDxunSKmg9400bvwyALMpqv2xCQY8rhz8vVHbil1dP9bvAx5zqPc';
const baseUrl = 'https://api.pexels.com/v1';

class PexelsService {
  final http.Client client;
  PexelsService({http.Client? client}) : client = client ?? http.Client();

  Future<PexelsSearchResponse> curated({int page = 1, int perPage = 40}) async {
    final uri = Uri.parse('$baseUrl/curated?page=$page&per_page=$perPage');
    final r = await client.get(uri, headers: {'Authorization': pexelApiKey});
    return _parse(r);
  }

  Future<PexelsSearchResponse> search(
    String query, {
    int page = 1,
    int perPage = 40,
  }) async {
    final q = Uri.encodeQueryComponent(query);
    final uri = Uri.parse(
      '$baseUrl/search?query=$q&page=$page&per_page=$perPage',
    );
    final http.Response response = await client.get(
      uri,
      headers: {'Authorization': pexelApiKey},
    );
    return _parse(response);
  }

  PexelsSearchResponse _parse(http.Response response) {
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PexelsSearchResponse.fromJson(json);
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded. Try again later.');
    } else {
      throw Exception('Pexels error ${response.statusCode}');
    }
  }
}
