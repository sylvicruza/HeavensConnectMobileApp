import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'auth_service.dart';

extension ContributionService on AuthService {
  /// Get Contributions (Admin)
  Future<List<dynamic>?> getContributions({
    String? status,
    int? memberId,
    String? paymentMethod,
    int? month,
    int? year,
    String? search,  // <-- Add search here
  }) async {
    final token = await getToken();
    if (token == null) return null;

    Map<String, String> queryParams = {};
    if (status != null) queryParams['status'] = status;
    if (memberId != null) queryParams['member'] = memberId.toString();
    if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();
    if (search != null) queryParams['search'] = search;  // <-- Add search filter here

    final uri = Uri.parse('$baseUrl/api/contributions/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        return await getContributions(
          status: status,
          memberId: memberId,
          paymentMethod: paymentMethod,
          month: month,
          year: year,
          search: search,  // <-- Pass search on retry too
        );
      }
    }
    logger.e('Failed to fetch contributions: ${response.body}');
    return null;
  }


  /// Add Contribution (Admin)
  Future<bool> addContribution(Map<String, dynamic> data, {File? proofOfPayment}) async {
    final token = await getToken();
    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/api/contributions/');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    if (proofOfPayment != null) {
      request.files.add(await http.MultipartFile.fromPath('proof_of_payment', proofOfPayment.path));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    logger.d('Add Contribution Response: $respStr');
    return response.statusCode == 201;
  }

  Future<Map<String, dynamic>?> getContributionDetail(int id) async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/contributions/$id/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) return await getContributionDetail(id);
    }
    logger.e('Failed to fetch contribution detail: ${response.body}');
    return null;
  }


  /// Verify Contribution
  Future<bool> verifyContribution(int contributionId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/contributions/$contributionId/verify/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  /// Reject Contribution
  Future<bool> rejectContribution(int contributionId, String reason) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/contributions/$contributionId/reject/'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'reason': reason}),
    );
    return response.statusCode == 200;
  }


  Future<List<Map<String, dynamic>>?> searchMembers(String query) async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/members/?search=$query'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> raw = json.decode(response.body);
      return raw.cast<Map<String, dynamic>>();  // 👈 Cast properly
    } else {
      logger.e('Failed to search members: ${response.body}');
      return null;
    }
  }

  Future<List<dynamic>?> getMyContributions({
    String? status,
    String? paymentMethod,
    int? month,
    int? year,
  }) async {
    final token = await getToken();
    if (token == null) return null;

    Map<String, String> queryParams = {};
    if (status != null) queryParams['status'] = status;
    if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse('$baseUrl/api/contributions/my/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        return await getMyContributions(
          status: status,
          paymentMethod: paymentMethod,
          month: month,
          year: year,
        );
      }
    }
    logger.e('Failed to fetch member contributions: ${response.body}');
    return null;
  }

  Future<List<dynamic>?> getContributionsByUsername(String username, {
    String? status,
    String? paymentMethod,
    int? month,
    int? year,
  }) async {
    final token = await getToken();
    if (token == null) return null;

    Map<String, String> queryParams = {};
    if (status != null) queryParams['status'] = status;
    if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse('$baseUrl/api/contributions/by-username/$username/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        return await getContributionsByUsername(username, status: status, paymentMethod: paymentMethod, month: month, year: year);
      }
    }
    logger.e('Failed to fetch contributions by username: ${response.body}');
    return null;
  }



}
