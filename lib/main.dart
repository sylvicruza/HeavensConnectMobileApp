import 'package:flutter/material.dart';
import 'package:heavens_connect/screens/accounts/change_password_screen.dart';
import 'package:heavens_connect/screens/accounts/forgot_password_screen.dart';
import 'package:heavens_connect/screens/accounts/login_screen.dart';
import 'package:heavens_connect/screens/accounts/pending_request_screen.dart';
import 'package:heavens_connect/screens/accounts/reset_password_screen.dart';
import 'package:heavens_connect/screens/admin/contributions/legacy_contribution_screen.dart';
import 'package:heavens_connect/screens/admin/disbursements/add_disbursement_screen.dart';
import 'package:heavens_connect/screens/admin/adminusers/add_adminuser_screen.dart';
import 'package:heavens_connect/screens/admin/adminusers/admin_dashboard.dart';
import 'package:heavens_connect/screens/admin/adminusers/admin_financial_dashboard.dart';
import 'package:heavens_connect/screens/admin/requests/admin_welfare_details_screen.dart';
import 'package:heavens_connect/screens/admin/requests/admin_welfare_list_screen.dart';
import 'package:heavens_connect/screens/admin/adminusers/all_adminuser_screen.dart';
import 'package:heavens_connect/screens/admin/contributions/contribution_batch_detail_screen.dart';
import 'package:heavens_connect/screens/admin/contributions/contribution_batch_list_screen.dart';
import 'package:heavens_connect/screens/admin/disbursements/disbursement_details_screen.dart';
import 'package:heavens_connect/screens/admin/disbursements/disbursement_list_screen.dart';
import 'package:heavens_connect/screens/admin/adminusers/edit_adminuser_screen.dart';
import 'package:heavens_connect/screens/admin/requests/pending_record_screen.dart';

import 'package:heavens_connect/screens/member/memberusers/member_account_statement_screen.dart';
import 'package:heavens_connect/screens/member/contributions/member_contribution_list_screen.dart';
import 'package:heavens_connect/screens/member/contributions/member_contribution_screen.dart';
import 'package:heavens_connect/screens/member/memberusers/member_dashboard.dart';
import 'package:heavens_connect/screens/member/memberusers/member_profile_screen.dart';

import 'package:heavens_connect/screens/member/requests/welfare_request_details_screen.dart';
import 'package:heavens_connect/screens/member/requests/welfare_request_edit_screen.dart';
import 'package:heavens_connect/screens/member/requests/welfare_request_list_screen.dart';
import 'package:heavens_connect/screens/member/requests/welfare_request_screen.dart';
import 'package:heavens_connect/screens/accounts/splash_screen.dart';
import 'package:heavens_connect/utils/app_theme.dart';

import 'screens/admin/contributions/add_contribution_screen.dart';
import 'screens/admin/members/add_member_screen.dart';
import 'screens/admin/members/all_members_screen.dart';
import 'screens/admin/contributions/contribution_details_screen.dart';
import 'screens/admin/contributions/contribution_list_screen.dart';
import 'screens/admin/members/edit_member_screen.dart';
import 'screens/member/memberusers/request_membership_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const Color primarySeed = AppTheme.themeColor; // Faithful Purple

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primarySeed),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/editMember': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return EditMemberScreen(member: args);
        },
        '/allMembers': (context) => const AllMembersScreen(),
        '/addMember': (context) => const AddMemberScreen(),
        '/profile': (context) => const MemberProfileScreen(memberData: {}),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/memberDashboard': (context) => const MemberDashboard(),
        '/requestMembership': (context) => const RequestMembershipScreen(),
        '/pendingRequests': (context) => const PendingRequestsScreen(),
        '/pendingRecords': (context) => const PendingRecordsScreen(),
        '/contributions': (context) => const ContributionListScreen(),
        '/addContribution': (context) => const AddContributionScreen(),
        '/memberAddContribution': (context) => const MemberContributionScreen(),
        '/memberContributionList': (context) => const MemberContributionListScreen(),
        '/memberWelfareRequests': (context) => const MemberWelfareRequestListScreen(),
        '/memberSubmitWelfareRequest': (context) => const MemberWelfareRequestScreen(),
        '/memberWelfareRequestDetail': (context) {
          final request = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MemberWelfareRequestDetailScreen(request: request);
        },
        '/editWelfareRequest': (context) {
          final request = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return EditWelfareRequestScreen(request: request);
        },
        '/contributionDetail': (context) {
          final int id = ModalRoute.of(context)!.settings.arguments as int;
          return ContributionDetailScreen(contributionId: id);
        },
        '/welfareRequests': (context) => const AdminWelfareRequestListScreen(),
        '/adminWelfareRequestDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as dynamic;  // <-- Accept arguments
          return AdminWelfareRequestDetailScreen(request: args);
        },
        '/disbursements': (context) => const AdminDisbursementListScreen(),
        '/adminDisbursementDetail': (context) {
            final disb = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return AdminDisbursementDetailScreen(disbursement: disb);
          },
        '/createAdminUser': (context) => const AdminCreateUserScreen(),
        '/adminUsersList': (context) => const AdminUsersListScreen(),
        '/editAdminUser': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as dynamic;
          return EditAdminUserScreen(adminData: args);
        },
        '/addDisbursement': (context) => const AddDisbursementScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),

        '/member-account-statement': (context) => const MemberAccountStatementScreen(),
        '/adminFinanceAnalysis': (context) => const AdminFinanceDashboardScreen(),
        '/batchList': (context) => const ContributionBatchListScreen(),
        '/batchDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ContributionBatchDetailScreen(batch: args);
        },
        '/importLegacy': (context) => const ImportLegacyContributionsScreen(),

      },
      home: const SplashScreen(),

    );
  }
}


