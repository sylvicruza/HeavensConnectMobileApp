import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

import '../utils/app_config.dart';

class AuthService {
  final Logger logger = Logger();
 //final String baseUrl = 'http://192.168.1.174:8085';  // Use base URL
 final String baseUrl = 'https://heavensconnect.onrender.com';  // Use base URL
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  /// Login
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/token/'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'username': username, 'password': password}),
      );

      logger.d('Login Response: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        await _secureStorage.write(key: 'access_token', value: data['access']);
        await _secureStorage.write(key: 'refresh_token', value: data['refresh']);
        await _secureStorage.write(key: 'user_type', value: data['user_type']);
        await _secureStorage.write(key: 'role', value: data['role'] ?? '');
        await _secureStorage.write(key: 'full_name', value: data['full_name'] ?? '');
        await _secureStorage.write(key: 'username', value: username.toLowerCase());

        return true;
      } else {
        return false;
      }
    } catch (e) {
      logger.e('Login Error: $e');
      return false;
    }
  }
  bool isTokenExpired(String token) {
    try {
      // Split JWT (header.payload.signature)
      final parts = token.split('.');
      if (parts.length != 3) {
        return true;  // Invalid token structure
      }

      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final expiry = payload['exp'];  // Get expiry timestamp

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
      final now = DateTime.now();

      return expiryDate.isBefore(now);  // Returns true if expired
    } catch (e) {
      logger.e('Token decode error: $e');
      return true;  // Assume expired on error
    }
  }
  /// Get Access Token
  Future<String?> getToken() async {
    final token = await _secureStorage.read(key: 'access_token');
    logger.d('Retrieved access token: $token');

    if (token != null && isTokenExpired(token)) {
      logger.w('Access token expired.');
      final refreshed = await refreshToken();
      if (refreshed) {
        return await _secureStorage.read(key: 'access_token');
      } else {
        logger.e('Failed to refresh expired token.');
        return null;
      }
    }

    return token;
  }
  Future<bool> refreshToken() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _secureStorage.write(key: 'access_token', value: data['access']);
      return true;
    } else {
      await logout();  // Clear tokens if refresh fails
      return false;
    }
  }


  /// Get Member Profile
  Future<Map<String, dynamic>?> getMemberProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/member/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    logger.d('Profile Response: ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token might be expired, try refreshing
      bool refreshed = await refreshToken();
      if (refreshed) {
        // Retry after refreshing
        return await getMemberProfile();
      } else {
        logger.e('Failed to fetch profile.');
        return null;
      }
    }
    return null;
  }
  Future<bool> updateMemberProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/api/member/profile/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      logger.i('Member profile updated successfully.');
      return true;
    } else {
      logger.e('Failed to update member profile: ${response.body}');
      return false;
    }
  }
  /// Logout (Blacklists token and clears storage)
  Future<void> logout() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');

    if (refreshToken != null) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/logout/'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({'refresh': refreshToken}),
        );
        logger.d('Logout Response: ${response.body}');
      } catch (e) {
        logger.e('Logout Error: $e');
      }
    }

    await _secureStorage.deleteAll();  // Clear tokens and user data
  }
  Future<Map<String, dynamic>?> getAdminDashboard() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/dashboard/'),  // Adjust to your server IP or domain
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token might be expired, try refreshing
      bool refreshed = await refreshToken();
      if (refreshed) {
        // Retry after refreshing
        return await getAdminDashboard();
      } else {
        logger.e('Failed to fetch admin dashboard: ${response.body}');
        return null;
      }
    }
    return null;
  }
  Future<Map<String, dynamic>?> getAdminProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/admin-users/my-profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) return await getAdminProfile();
    }

    logger.e('Failed to fetch admin profile: ${response.body}');
    return null;
  }
  Future<bool> updateAdminProfile(Map<String, dynamic> updatedData) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin-users/my-profile/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updatedData),
    );

    if (response.statusCode == 200) {
      logger.i('Admin profile updated successfully.');
      return true;
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        return await updateAdminProfile(updatedData);
      }
    }

    logger.e('Failed to update admin profile: ${response.body}');
    return false;
  }
  Future<List<dynamic>?> getAllMembers() async {
    String? token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/members/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token might be expired, try refreshing
      bool refreshed = await refreshToken();
      if (refreshed) {
        // Retry after refreshing
        return await getAllMembers();
      } else {
        return null;
      }
    } else {
      logger.e('Failed to fetch members: ${response.body}');
      return null;
    }
  }
  Future<bool> addMember(Map<String, String> memberData) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/members/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(memberData),
    );

    return response.statusCode == 201;
  }

  Future<bool> addMemberWithImage(Map<String, String> memberData, File? imageFile) async {
    final token = await getToken();
    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/api/members/');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(memberData);

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('profile_picture', imageFile.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return response.statusCode == 201;
  }


  Future<bool> deleteMember(int memberId) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/api/members/$memberId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 204;
  }
  Future<bool> editMember(int memberId, Map<String, dynamic> memberData) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/api/members/$memberId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(memberData),  // dynamic allows flexibility for all data types
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      logger.e('Failed to edit member: ${response.body}');
      return false;
    }
  }
  Future<bool> uploadMemberPicture(int memberId, XFile imageFile) async {
    final token = await getToken();
    if (token == null) return false;

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/api/members/$memberId/'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('profile_picture', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      return true;
    } else {
      logger.e('Failed to upload image');
      return false;
    }
  }
  Future<Map<String, dynamic>?> getMemberDashboard(int memberId) async {
    String? token = await getToken();

    Future<http.Response> makeRequest() {
      return http.get(
        Uri.parse('$baseUrl/api/members/$memberId/dashboard/'),
        headers: {'Authorization': 'Bearer $token'},
      );
    }

    http.Response response = await makeRequest();

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token expired, attempt refresh
      final refreshed = await refreshToken();
      if (refreshed) {
        token = await getToken(); // Get the new token
        response = await makeRequest(); // Retry the request

        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
      }
      logger.e('Failed to refresh token or retry request.');
      return null;
    } else {
      logger.e('Failed to fetch member dashboard: ${response.body}');
      return null;
    }
  }
  Future<bool> requestMembership({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
    File? profilePicture,
  }) async {
    final uri = Uri.parse('$baseUrl/api/pending-members/');
    final request = http.MultipartRequest('POST', uri);

    request.fields['full_name'] = fullName;
    request.fields['email'] = email;
    request.fields['phone_number'] = phoneNumber;
    request.fields['address'] = address;

    if (profilePicture != null) {
      request.files.add(await http.MultipartFile.fromPath('profile_picture', profilePicture.path));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    logger.d('Membership Request Response: $respStr');

    if (response.statusCode == 201) {
      return true;
    } else {
      logger.e('Membership Request Failed: $respStr');
      return false;
    }
  }


  Future<List<dynamic>?> getPendingRequests() async {
    var token = await getToken();
    var response = await http.get(
      Uri.parse('$baseUrl/api/pending-members/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token expired/invalid -> Refresh token
      bool refreshed = await refreshToken();
      if (refreshed) {
        token = await getToken();  // Get new token
        response = await http.get(
          Uri.parse('$baseUrl/api/pending-members/'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
      }
    }

    logger.e('Failed to fetch pending requests: ${response.body}');
    return null;
  }


// Approve request
  Future<bool> approveRequest(int requestId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/pending-members/$requestId/approve/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

// Reject request
  Future<bool> rejectRequest(int requestId, String reason) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/pending-members/$requestId/reject/'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'reason': reason}),
    );
    return response.statusCode == 200;
  }

  Future<bool> forgotPassword(String identifier) async {
    const frontendUrl = AppConfig.frontendUrl;

    final response = await http.post(
      Uri.parse('$baseUrl/api/forgot-password/'),
      headers: {
        'Content-Type': 'application/json',
        'X-Frontend-URL': frontendUrl,
      },
      body: json.encode({'identifier': identifier}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      logger.e('Forgot Password Error: ${response.body}');

      return false;
    }
  }


  Future<bool> resetPassword(String uid, String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'token': token, 'new_password': newPassword}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/change-password/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      logger.i('Password changed successfully');
      return true;
    } else {
      logger.e('Failed to change password: ${response.body}');
      return false;
    }
  }


  /// Utility Getters
  Future<String> getUserType() async => await _secureStorage.read(key: 'user_type') ?? 'unknown';
  Future<String?> getUserRole() async => await _secureStorage.read(key: 'role');
  Future<String?> getFullName() async => await _secureStorage.read(key: 'full_name');

  Future<bool> submitWelfareRequest(Map<String, dynamic> data, {File? attachment}) async {
    final token = await getToken();
    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/api/welfare-requests/');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    // Add form fields
    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // Add attachment if available
    if (attachment != null) {
      request.files.add(await http.MultipartFile.fromPath('attachment', attachment.path));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      logger.i('Welfare request submitted successfully.');
      return true;
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        return await submitWelfareRequest(data, attachment: attachment); // Retry after refresh
      }
    }

    logger.e('Failed to submit welfare request: $responseBody');
    return false;
  }

  Future<List<dynamic>?> getWelfareRequestsByUsername(String username) async {
    final token = await getToken();
    if (token == null) return null;

    final uri = Uri.parse('$baseUrl/api/welfare-requests/by-username/$username/');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        return await getWelfareRequestsByUsername(username);
      }
    }
    logger.e('Failed to fetch welfare requests by username: ${response.body}');
    return null;
  }

  Future<bool> deleteWelfareRequest(int requestId) async {
    final token = await getToken();
    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/api/welfare-requests/$requestId/');
    final response = await http.delete(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 204) {
      logger.i('Welfare request deleted successfully.');
      return true;
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        return await deleteWelfareRequest(requestId);  // Retry after refreshing token
      }
    }
    logger.e('Failed to delete welfare request: ${response.body}');
    return false;
  }

  Future<bool> updateWelfareRequest(int requestId, Map<String, dynamic> data, {File? attachment}) async {
    final token = await getToken();
    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/api/welfare-requests/$requestId/');

    var request = http.MultipartRequest('PATCH', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(data.map((key, value) => MapEntry(key, value.toString())));

    if (attachment != null) {
      request.files.add(await http.MultipartFile.fromPath('attachment', attachment.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      logger.i('Welfare request updated successfully');
      return true;
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        return await updateWelfareRequest(requestId, data, attachment: attachment);
      }
    }

    logger.e('Failed to update welfare request: ${response.body}');
    return false;
  }

  Future<List<dynamic>?> getWelfareRequests({
    String? status,
    String? category,
    String? search,
  }) async {
    final token = await getToken();
    if (token == null) return null;

    // Build query parameters
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/api/welfare-requests/').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      logger.i('Fetched welfare requests successfully');
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        return await getWelfareRequests(status: status, category: category, search: search);
      }
    }

    logger.e('Failed to fetch welfare requests: ${response.body}');
    return null;
  }


  Future<bool> updateWelfareRequestStatus(int requestId, String status, String? adminNote) async {
    final token = await getToken();
    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/api/welfare-requests/$requestId/update-status/');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'status': status,
        'admin_note': adminNote,
      }),
    );

    if (response.statusCode == 200) {
      logger.i('Welfare request status updated successfully');
      return true;
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        return await updateWelfareRequestStatus(requestId, status, adminNote);
      }
    }

    logger.e('Failed to update welfare request status: ${response.body}');
    return false;
  }

  Future<bool> addDisbursement(Map<String, dynamic> data, {File? attachment}) async {
    final token = await getToken();
    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/api/disbursements/');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    // Add all fields
    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    // Add attachment if available
    if (attachment != null) {
      request.files.add(await http.MultipartFile.fromPath('attachment', attachment.path));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      logger.i('Disbursement added successfully');
      return true;
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        return await addDisbursement(data, attachment: attachment);
      }
    }

    logger.e('Failed to add disbursement: $responseBody');
    return false;
  }

  Future<List<dynamic>?> getDisbursements({
    String? paymentMethod,
    String? category,
    String? search,
  }) async {
    final token = await getToken();
    if (token == null) return null;

    final queryParams = <String, String>{};
    if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/api/disbursements/').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        return await getDisbursements(paymentMethod: paymentMethod, category: category, search: search);
      }
    }

    logger.e('Failed to fetch disbursements: ${response.body}');
    return null;
  }

  Future<Map<String, dynamic>?> getPendingRecords() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/pending-records/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) return await getPendingRecords();
    }

    logger.e('Failed to fetch pending records');
    return null;
  }

//1 Send verification code to email
  Future<bool> sendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/send-verification-code/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        logger.i('Verification code sent to $email');
        return true;
      } else {
        logger.e('Failed to send code: ${response.body}');
        return false;
      }
    } catch (e) {
      logger.e('Error sending verification code: $e');
      return false;
    }
  }

// 2 Verify the code entered by the user
  Future<bool> verifyEmailCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-email-code/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );

      if (response.statusCode == 200) {
        logger.i('Email verified successfully for $email');
        return true;
      } else {
        logger.e('Verification failed: ${response.body}');
        return false;
      }
    } catch (e) {
      logger.e('Error verifying email code: $e');
      return false;
    }
  }

  Future<bool> createAdminUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
  }) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/admin-users/create_admin/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      logger.i('Admin user created successfully');
      return true;
    } else {
      logger.e('Failed to create admin user: ${response.body}');
      return false;
    }
  }

  Future<List<dynamic>?> getAdminUsers() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/admin-users/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) return await getAdminUsers();
    }

    logger.e('Failed to fetch admin users: ${response.body}');
    return null;
  }

  Future<bool> deleteAdminUser(int adminId) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin-users/$adminId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 204) {
      logger.i('Admin user deleted successfully');
      return true;
    } else {
      logger.e('Failed to delete admin user: ${response.body}');
      return false;
    }
  }


  Future<bool> editAdminUser(int adminId, Map<String, dynamic> adminData) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/api/admin-users/$adminId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(adminData),
    );

    if (response.statusCode == 200) {
      logger.i('Admin user updated successfully');
      return true;
    } else {
      logger.e('Failed to update admin user: ${response.body}');
      return false;
    }
  }

  Future<String> requestAccountStatement({
    required DateTime fromDate,
    required DateTime toDate,
    required String format,
  }) async {
    final token = await getToken();
    if (token == null) return "Authentication error. Please log in again.";

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/member/request-statement/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'from_date': fromDate.toIso8601String().split('T').first,
          'to_date': toDate.toIso8601String().split('T').first,
          'format': format
        }),
      );

      if (response.statusCode == 200) {
        logger.i('Statement request successful');
        return "success";
      } else {
        logger.e('Failed to request statement: ${response.body}');
        // ✅ Try to decode the message nicely
        try {
          final Map<String, dynamic> error = json.decode(response.body);
          return error['detail'] ?? 'Unknown error occurred.';
        } catch (_) {
          return 'Something went wrong. Please try again.';
        }
      }
    } catch (e) {
      logger.e('Error requesting statement: $e');
      return 'Network error. Please check your connection.';
    }
  }


  Future<List<dynamic>?> searchMembers(String query) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/members/?search=$query'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  Future<List<dynamic>?> searchContributions(String query) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/contributions/?search=$query'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  Future<List<dynamic>?> searchWelfareRequests(String query) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/welfare-requests/?search=$query'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }
  
  /// Fetch notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) return await getNotifications();
    }

    logger.e('Failed to fetch notifications: ${response.body}');
    return [];
  }

  /// Mark all notifications as read
  Future<bool> markNotificationsAsRead() async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/notifications/mark-read/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  Future<int> getUnreadNotificationCount() async {
    final token = await getToken();
    if (token == null) return 0;

    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications/unread_count/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['unread'] ?? 0;
    } else {
      return 0;
    }
  }

  Future<bool> exportFinanceStatement({
    required DateTime fromDate,
    required DateTime toDate,
    required String format,
  }) async {
    final token = await getToken();
    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/api/finance/export/');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from_date': fromDate.toIso8601String().split('T')[0],
        'to_date': toDate.toIso8601String().split('T')[0],
        'format': format,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        return await exportFinanceStatement(
            fromDate: fromDate, toDate: toDate, format: format);
      }
    }

    logger.e('Export failed: ${response.body}');
    return false;
  }

  /// Fetches the summary totals: total_income, total_expense, monthly data
  Future<Map<String, dynamic>> getFinanceSummary({int? year, int? month}) async {
    final token = await getToken();
    if (token == null) return {};

    final queryParams = {
      if (year != null) 'year': year.toString(),
      if (month != null) 'month': month.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/finance/summary/').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) return await getFinanceSummary(year: year, month: month);
    }
    return {};
  }


  /// Fetches all finance transactions (both income and expenses), with optional filters
  Future<Map<String, dynamic>> getFinanceTransactions({int? year, int? month}) async {
    final token = await getToken();
    if (token == null) return {};

    final queryParams = {
      if (year != null) 'year': year.toString(),
      if (month != null) 'month': month.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/finance/transactions/').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) return await getFinanceTransactions(year: year, month: month);
    }

    return {};
  }


  Future<Map<String, List<String>>> getSystemSettings() async {
    final token = await getToken();
    if (token == null) return {};

    final uri = Uri.parse('$baseUrl/api/settings/');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return {
        for (var item in list)
          item['key']: (item['value'] as String).split(',').map((e) => e.trim()).toList()
      };
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) return await getSystemSettings();
    }

    return {};
  }


  Future<bool> createSystemSetting(Map<String, dynamic> setting) async {
    final token = await getToken();
    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/api/settings/');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'key': setting['key'],
        'value': (setting['value'] as String),
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) return await createSystemSetting(setting);
    }

    return false;
  }

  Future<bool> updateSystemSetting(int id, Map<String, dynamic> setting) async {
    final token = await getToken();
    if (token == null) return false;

    final uri = Uri.parse('$baseUrl/api/settings/$id/');
    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'value': setting['value'], // assume it's already a String
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) return await updateSystemSetting(id, setting);
    }

    return false;
  }


  Future<Map<String, dynamic>> getRawSystemSettings() async {
    final token = await getToken();
    if (token == null) return {};

    final uri = Uri.parse('$baseUrl/api/settings/');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      final settings = <String, dynamic>{};
      final meta = <String, dynamic>{};

      for (var item in list) {
        final key = item['key'];
        settings[key] = (item['value'] as String).split(',').map((e) => e.trim()).toList();
        meta[key] = {'id': item['id']};
      }

      return {
        'settings': settings,
        'meta': meta,
      };
    } else if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) return await getRawSystemSettings();
    }

    return {};
  }

  Future<http.Response?> authenticatedRequest(
      String method,
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
        bool isJson = true,
      }) async {
    String? token = await getToken();
    if (token == null) return null;

    Uri uri = Uri.parse('$baseUrl$endpoint');
    headers ??= {};
    headers['Authorization'] = 'Bearer $token';
    if (isJson) headers['Content-Type'] = 'application/json';

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: json.encode(body));
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: json.encode(body));
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: json.encode(body));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported method: $method');
      }

      // Handle 401 - Try to refresh token and retry once
      if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          token = await getToken();
          headers['Authorization'] = 'Bearer $token!';

          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(uri, headers: headers);
              break;
            case 'POST':
              response = await http.post(uri, headers: headers, body: json.encode(body));
              break;
            case 'PUT':
              response = await http.put(uri, headers: headers, body: json.encode(body));
              break;
            case 'PATCH':
              response = await http.patch(uri, headers: headers, body: json.encode(body));
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: headers);
              break;
          }
        } else {
          await logout(); // Token invalid, logout
          return null;
        }
      }

      return response;
    } catch (e) {
      logger.e('Authenticated request error: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getPendingContributionBatches() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/contributions/pending-batches/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> verifyContributionBatch(String batchId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/contributions/verify-batch/'),
      headers: {'Authorization': 'Bearer $token'},
      body: {'batch_id': batchId},
    );
    return response.statusCode == 200;
  }

  Future<bool> importLegacyContributions(List<Map<String, dynamic>> contributions) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/api/contributions/import_legacy/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'contributions': contributions}),
    );

    return response.statusCode == 200;
  }

  Future<bool> importLegacyContributionsExcel(File file) async {
    final uri = Uri.parse('$baseUrl/api/contributions/import-legacy-excel/');
    final request = http.MultipartRequest('POST', uri);

    final token = await getToken();
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      return true;
    } else {
      final respStr = await response.stream.bytesToString();
      print('Import failed: $respStr');
      return false;
    }
  }






}
