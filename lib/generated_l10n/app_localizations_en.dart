// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_exit => 'Exit';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_back => 'Back';

  @override
  String get common_confirm_question => 'Do you want to continue?';

  @override
  String get role_administrator => 'Administrator';

  @override
  String get role_employee => 'Employee';

  @override
  String get role_resident => 'Resident';

  @override
  String get role_syndic => 'Syndic';

  @override
  String get role_doorman => 'Doorman';

  @override
  String get role_visitor => 'Visitor';

  @override
  String get login_app_name => 'Owany';

  @override
  String get login_welcome => 'Welcome back!';

  @override
  String get login_identifier_label => 'Phone or Username';

  @override
  String get login_password_label => 'Password';

  @override
  String get login_sign_in => 'Sign In';

  @override
  String get login_need_access =>
      'Need access? Contact the system administrator.';

  @override
  String get login_forgot_password => 'Forgot password?';

  @override
  String get login_required_field => 'Required field';

  @override
  String get login_error_connection => 'Unable to connect to server';

  @override
  String get login_error_credentials => 'Invalid credentials';

  @override
  String get login_error_generic => 'An error occurred. Please try again';

  @override
  String get login_processing => 'Processing...';

  @override
  String get login_language_pt => 'Portuguese';

  @override
  String get login_language_en => 'English';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_account_preferences => 'Account Preferences';

  @override
  String get settings_account_subtitle => 'Manage your experience and security';

  @override
  String get settings_security => 'Security';

  @override
  String get settings_change_password => 'Change Password';

  @override
  String get settings_change_password_subtitle =>
      'Update your password regularly';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_notifications_push => 'Push Notifications';

  @override
  String get settings_notifications_push_subtitle => 'Real-time alerts';

  @override
  String get settings_notifications_email => 'Email Notifications';

  @override
  String get settings_notifications_email_subtitle => 'Weekly activity summary';

  @override
  String get settings_notifications_sms => 'SMS Notifications';

  @override
  String get settings_notifications_sms_subtitle =>
      'Receive alerts via text message';

  @override
  String get settings_sms_enabled => 'SMS notifications enabled';

  @override
  String get settings_sms_disabled => 'SMS notifications disabled';

  @override
  String get settings_sms_update_failed => 'Failed to update SMS preference';

  @override
  String get settings_appearance => 'Appearance';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_language_subtitle => 'Portuguese • English';

  @override
  String get settings_about => 'About';

  @override
  String get settings_about_description =>
      'Modern building management system to facilitate apartment management, maintenance requests, and resident communication.';

  @override
  String get settings_logout => 'Sign Out';

  @override
  String get settings_logout_confirm_title => 'Confirm Sign Out';

  @override
  String get settings_logout_confirm_body =>
      'Are you sure you want to sign out? You will need to log in again.';

  @override
  String get settings_language_apply_restart =>
      'Language will be applied on next restart';

  @override
  String get mp_details_title => 'Maintenance Details';

  @override
  String get mp_not_found => 'Maintenance not found';

  @override
  String get mp_status_overdue => 'Overdue';

  @override
  String get mp_status_alert => 'Alert';

  @override
  String get mp_status_active => 'Active';

  @override
  String get mp_info_general => 'General Information';

  @override
  String get mp_title => 'Title';

  @override
  String get mp_type => 'Type';

  @override
  String get mp_frequency => 'Frequency';

  @override
  String get mp_status => 'Status';

  @override
  String get mp_active => 'Active';

  @override
  String get mp_inactive => 'Inactive';

  @override
  String get mp_schedule => 'Schedule';

  @override
  String get mp_next_maintenance => 'Next Maintenance';

  @override
  String get mp_last_maintenance => 'Last Maintenance';

  @override
  String get mp_never_executed => 'Never executed';

  @override
  String get mp_total_executions => 'Total Executions';

  @override
  String get mp_costs_supplier => 'Costs and Supplier';

  @override
  String get mp_estimated_cost => 'Estimated Cost';

  @override
  String get mp_supplier => 'Supplier';

  @override
  String get mp_phone => 'Phone';

  @override
  String get mp_responsible => 'Responsible';

  @override
  String get mp_name => 'Name';

  @override
  String get mp_not_assigned => 'Not assigned';

  @override
  String get mp_created_by => 'Created by';

  @override
  String get mp_last_update => 'Last update';

  @override
  String get mp_description => 'Description';

  @override
  String get mp_notes => 'Notes';

  @override
  String get mp_edit => 'Edit';

  @override
  String get mp_conclude => 'Complete';

  @override
  String get mp_history_empty => 'No execution recorded';

  @override
  String get mp_last_executions => 'Latest Executions';

  @override
  String get mp_last_execution => 'Last Execution';

  @override
  String get mp_next_execution => 'Next Execution';

  @override
  String get mp_total_times => 'times';

  @override
  String get mp_conclude_execution => 'Complete Execution';

  @override
  String get mp_detailed_history => 'Detailed History';

  @override
  String get mp_conclude_title => 'Complete execution';

  @override
  String get mp_done_what => 'What was done?';

  @override
  String get mp_done_hint => 'Ex: Part replacement and final tests';

  @override
  String get mp_additional_comments => 'Additional comments';

  @override
  String get mp_comments_hint => 'Ex: Follow-up needed for next 2 weeks';

  @override
  String get mp_real_cost_optional => 'Actual cost (optional)';

  @override
  String get mp_execution_saved => 'Execution saved successfully';

  @override
  String get mp_execution_error => 'Error saving execution';

  @override
  String get mp_alerts_title => 'Maintenance Alerts';

  @override
  String get mp_alerts_overdue => 'Overdue';

  @override
  String get mp_alerts_overdue_subtitle => 'Overdue and awaiting action';

  @override
  String get mp_alerts_in_alert => 'In Alert';

  @override
  String get mp_alerts_in_alert_subtitle => 'Critical deadline approaching';

  @override
  String get mp_alerts_upcoming => 'Upcoming';

  @override
  String get mp_alerts_upcoming_subtitle => 'Due within 30 days';

  @override
  String get mp_alerts_planned => 'Planned';

  @override
  String get mp_alerts_planned_subtitle => 'Normally scheduled';

  @override
  String get mp_alerts_alerts => 'Alerts';

  @override
  String get mp_alerts_none_registered => 'No maintenance registered';

  @override
  String get mp_alerts_none_overdue => 'No overdue maintenance';

  @override
  String get mp_alerts_none_in_alert => 'No maintenance in alert';

  @override
  String get mp_alerts_none_upcoming => 'No upcoming maintenance';

  @override
  String get mp_alerts_general_condo => 'GENERAL/CONDO';

  @override
  String get mp_alerts_apartment => 'APARTMENT';

  @override
  String get mp_alerts_next => 'Next';

  @override
  String get mp_alerts_cost => 'Cost';

  @override
  String get mp_alerts_hero_title => 'Preventive Maintenance';

  @override
  String get mp_alerts_hero_subtitle => 'Continuous monitoring of assets';

  @override
  String get mp_alerts_assets_label => 'assets';

  @override
  String get mp_alerts_overdue_suffix => 'overdue';

  @override
  String get mp_alerts_loading => 'Loading maintenance...';

  @override
  String mp_alerts_urgent_items(int count) {
    return '$count item(s) need immediate attention';
  }

  @override
  String get mp_list_title => 'Preventive Maintenance';

  @override
  String get mp_list_filters => 'Filters';

  @override
  String get mp_list_filter_status_title => 'By Status';

  @override
  String get mp_list_filter_location_title => 'By Location';

  @override
  String get mp_list_filter_all => 'All';

  @override
  String get mp_list_filter_general => '🏢 General/Condo';

  @override
  String get mp_list_filter_apartment => '🏠 Apartment';

  @override
  String get mp_list_search_hint => 'Search maintenance...';

  @override
  String get mp_list_status_active => 'Active';

  @override
  String get mp_list_status_alert => 'With Alert';

  @override
  String get mp_list_status_overdue => 'Overdue';

  @override
  String get mp_list_total => 'Total';

  @override
  String get mp_list_summary => 'Summary';

  @override
  String get mp_list_general_title => '🏢 GENERAL/CONDO MAINTENANCE';

  @override
  String get mp_list_general_subtitle => 'Affect the whole building';

  @override
  String get mp_list_apartment_title => '🏠 APARTMENT MAINTENANCE';

  @override
  String get mp_list_apartment_subtitle => 'Unit-specific';

  @override
  String get mp_list_status_badge_overdue => 'OVERDUE';

  @override
  String get mp_list_status_badge_alert => 'ALERT';

  @override
  String get mp_list_status_badge_active => 'ACTIVE';

  @override
  String get mp_list_type_general_badge => 'GENERAL';

  @override
  String get mp_list_type_apartment_badge => 'APARTMENT';

  @override
  String get mp_list_location_condo => 'Condominium';

  @override
  String get mp_list_location_apartment => 'Apartment';

  @override
  String get mp_list_type_label => 'Type:';

  @override
  String get mp_list_frequency_label => 'Frequency:';

  @override
  String get mp_list_responsible_label => 'Responsible:';

  @override
  String get mp_list_next_in => 'Next in';

  @override
  String get mp_list_estimated_cost => 'Estimated Cost';

  @override
  String get mp_list_conclude_execution => 'Complete Execution';

  @override
  String get mp_list_dialog_title => 'Complete execution';

  @override
  String get mp_list_dialog_description_label =>
      'Describe what was done (optional)';

  @override
  String get mp_list_dialog_description_hint =>
      'e.g. Part replacement and final tests';

  @override
  String get mp_list_dialog_cost_label => 'Actual cost (optional)';

  @override
  String get mp_list_dialog_cost_hint => '0.00';

  @override
  String get mp_list_dialog_confirm => 'Complete';

  @override
  String get mp_list_empty_title => 'No maintenance found';

  @override
  String get mp_list_empty_subtitle => 'Adjust filters to see results';

  @override
  String get mp_list_days_late_prefix => 'Late';

  @override
  String get mp_list_days_today => 'Today';

  @override
  String get mp_list_days_tomorrow => 'Tomorrow';

  @override
  String get mp_list_days_in_prefix => 'In';

  @override
  String get mp_list_days_suffix => 'days';

  @override
  String get manage_items_title => 'Manage Items';

  @override
  String get manage_items_subtitle => 'Add heritage items to apartments';

  @override
  String get apartment => 'Apartment';

  @override
  String get select_apartment => 'Choose an apartment...';

  @override
  String get item_name => 'Item Name';

  @override
  String get description_optional => 'Description (optional)';

  @override
  String get save_item => 'Save Item';

  @override
  String get required_field => 'Required field';

  @override
  String get item_success => 'Item added successfully!';

  @override
  String get item_error => 'Error saving item';

  @override
  String get loading_apartments => 'Loading apartments...';

  @override
  String get no_apartments => 'No apartments available';

  @override
  String get link_apartment_subtitle => 'Link a user to an apartment';

  @override
  String get link_apartment => 'Link Apartment';

  @override
  String get link_success => 'Apartment linked successfully!';

  @override
  String get link_error => 'Error linking apartment';

  @override
  String get user => 'User';

  @override
  String get register_create_account => 'Create Account';

  @override
  String get register_fill_data => 'Fill in the data below to register';

  @override
  String get register_full_name => 'Full Name';

  @override
  String get register_username => 'Username';

  @override
  String get register_phone => 'Phone';

  @override
  String get register_password => 'Password';

  @override
  String get register_confirm_password => 'Confirm Password';

  @override
  String get register_accept_terms => 'You must accept the terms of service';

  @override
  String get register_success => 'Registration successful!';

  @override
  String get register_error => 'Registration error';

  @override
  String get register_name_required => 'Name is required';

  @override
  String get register_name_min_length => 'Name must have at least 3 characters';

  @override
  String get register_button => 'Register';

  @override
  String get register_already_have_account => 'Already have an account?';

  @override
  String get register_login_link => 'Login here';

  @override
  String get forgot_password_title => 'Recover Password';

  @override
  String get forgot_password_step1_label => 'Username or Phone';

  @override
  String get forgot_password_step1_button => 'Request Code';

  @override
  String get forgot_password_step2_title => 'Code Verification';

  @override
  String get forgot_password_step2_label => 'Verification Code';

  @override
  String get forgot_password_step2_button => 'Verify Code';

  @override
  String get forgot_password_step3_title => 'New Password';

  @override
  String get forgot_password_step3_password => 'New Password';

  @override
  String get forgot_password_step3_confirm => 'Confirm Password';

  @override
  String get forgot_password_step3_button => 'Change Password';

  @override
  String forgot_password_resend(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get forgot_password_sms_sent => 'SMS sent';

  @override
  String get forgot_password_error_invalid_login => 'Enter a valid username';

  @override
  String get forgot_password_login_required => 'Login name is required';

  @override
  String get forgot_password_login_too_short => 'Login name too short';

  @override
  String get forgot_password_passwords_dont_match => 'Passwords don\'t match';

  @override
  String get forgot_password_success => 'Password reset successfully!';

  @override
  String get forgot_password_step_verification => 'Verification';

  @override
  String get forgot_password_step_code => 'Code';

  @override
  String get forgot_password_step_new_password => 'New Password';

  @override
  String get forgot_password_step1_heading => 'Step 1: Verification';

  @override
  String get forgot_password_step1_subtitle =>
      'Enter your login name to receive a code via SMS';

  @override
  String get forgot_password_login_label => 'Login Name';

  @override
  String get forgot_password_login_hint => 'john.smith';

  @override
  String get forgot_password_login_helper =>
      'Use the same login name from registration';

  @override
  String get forgot_password_sms_will_be_sent =>
      'SMS will be sent to the registered phone';

  @override
  String get forgot_password_step2_heading => 'Step 2: OTP Code';

  @override
  String get forgot_password_step2_subtitle =>
      'Enter the code you received via SMS';

  @override
  String forgot_password_phone_label(String phone) {
    return 'Phone: $phone';
  }

  @override
  String get forgot_password_otp_label => 'OTP Code (6 digits)';

  @override
  String forgot_password_resend_in(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get forgot_password_resend_button => 'Resend Code';

  @override
  String get forgot_password_step3_heading => 'Step 3: New Password';

  @override
  String get forgot_password_step3_subtitle => 'Set your new password';

  @override
  String get forgot_password_reset_button => 'Reset Password';

  @override
  String forgot_password_sms_sent_to(String destination) {
    return 'SMS sent $destination. You will receive it shortly with your name.';
  }

  @override
  String get forgot_password_to_registered_phone => 'to the registered phone';

  @override
  String get common_next => 'Next';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_services => 'Services';

  @override
  String get nav_properties => 'Properties';

  @override
  String get nav_profile => 'Profile';

  @override
  String get drawer_main => 'Main';

  @override
  String get drawer_administration => 'Administration';

  @override
  String get drawer_resident_management => 'Resident Management';

  @override
  String get drawer_account => 'Account';

  @override
  String get drawer_new => 'New';

  @override
  String get drawer_logout => 'Sign Out';

  @override
  String get drawer_logout_confirm_title => 'Confirm Sign Out';

  @override
  String get drawer_logout_confirm_body => 'Are you sure you want to sign out?';

  @override
  String get drawer_user_default => 'User';

  @override
  String get drawer_resident_default => 'Resident';

  @override
  String get drawer_asset_management => 'Asset Management';

  @override
  String get drawer_request_types => 'Request Types';

  @override
  String get fab_add => 'Add';

  @override
  String get fab_apartment_maintenance_title => 'Apartment Maintenance';

  @override
  String get fab_apartment_maintenance_subtitle =>
      'Schedule maintenance in an apartment';

  @override
  String get fab_preventive_maintenance_title => 'Preventive Maintenance';

  @override
  String get fab_preventive_maintenance_subtitle =>
      'Schedule preventive maintenance';

  @override
  String get fab_new_request => 'New Request';

  @override
  String get fab_new_request_subtitle => 'Report an issue';

  @override
  String get fab_new_user => 'New User';

  @override
  String get fab_new_user_subtitle => 'Invite someone';

  @override
  String get fab_new_apartment => 'New Apartment';

  @override
  String get fab_new_apartment_subtitle => 'Register unit';

  @override
  String get fab_general_announcement => 'General Announcement';

  @override
  String get fab_general_announcement_subtitle => 'Send bulk SMS';

  @override
  String get selector_select_apartment => 'Select Apartment';

  @override
  String get selector_no_apartments => 'No apartments available';

  @override
  String get dashboard_title => 'Dashboard';

  @override
  String get dashboard_welcome => 'Welcome';

  @override
  String get dashboard_welcome_back => 'Welcome back!';

  @override
  String get dashboard_system_summary => 'Here is the system summary';

  @override
  String get dashboard_pending_count => 'pending';

  @override
  String get dashboard_statistics => 'Statistics';

  @override
  String get dashboard_main_stats => 'Main Statistics';

  @override
  String get dashboard_view_all => 'View all';

  @override
  String get dashboard_recent_activity => 'Recent Activity';

  @override
  String get dashboard_no_activity => 'No recent activity';

  @override
  String get dashboard_system_updating => 'System Updating';

  @override
  String get dashboard_requests_not_available =>
      'Requests v2 not yet available on server. Metrics may be outdated.';

  @override
  String get dashboard_error_loading_apartments => 'Error Loading Apartments';

  @override
  String get dashboard_maintenance => 'Maintenance';

  @override
  String get dashboard_open_count => 'open';

  @override
  String get dashboard_all_completed => 'All completed';

  @override
  String get dashboard_total_condo => 'Total in condo';

  @override
  String get dashboard_status_requests => 'Request Status';

  @override
  String get dashboard_quick_actions => 'Quick Actions';

  @override
  String get dashboard_new_request => 'New Request';

  @override
  String get dashboard_date_unknown => 'Unknown date';

  @override
  String get dashboard_date_now => 'Just now';

  @override
  String get dashboard_date_minutes_ago => 'minutes ago';

  @override
  String get dashboard_date_hours_ago => 'hours ago';

  @override
  String get dashboard_date_days_ago => 'days ago';

  @override
  String get maintenance_list_title => 'Maintenance Requests';

  @override
  String get maintenance_list_search => 'Search request...';

  @override
  String get maintenance_list_pending => 'Pending';

  @override
  String get maintenance_list_in_progress => 'In Progress';

  @override
  String get maintenance_list_completed => 'Completed';

  @override
  String get maintenance_list_empty => 'No requests found';

  @override
  String get maintenance_detail_title => 'Request Details';

  @override
  String get maintenance_detail_description => 'Description';

  @override
  String get maintenance_detail_status => 'Status';

  @override
  String get maintenance_detail_created => 'Created on';

  @override
  String get maintenance_request_attachments_optional =>
      'Attachments (optional)';

  @override
  String get maintenance_request_add_attachment => 'Add attachment';

  @override
  String get maintenance_request_no_files => 'No files selected';

  @override
  String get maintenance_request_remove_attachment => 'Remove attachment';

  @override
  String get apartments_list_title => 'Apartments';

  @override
  String get apartments_list_available => 'Available';

  @override
  String get apartments_list_occupied => 'Occupied';

  @override
  String get apartments_list_maintenance => 'Maintenance';

  @override
  String get apartments_inactive => 'Inactive';

  @override
  String get apartments_list_empty => 'No apartments found';

  @override
  String get apartments_detail_title => 'Apartment Details';

  @override
  String get apartments_detail_residents => 'Residents';

  @override
  String get apartments_create_title => 'New Apartment';

  @override
  String get apartments_number => 'Number';

  @override
  String get apartments_block => 'Block';

  @override
  String get apartments_floor => 'Floor';

  @override
  String get schedule_list_title => 'Schedules';

  @override
  String get schedule_detail_title => 'Schedule Details';

  @override
  String get schedule_create_title => 'New Schedule';

  @override
  String get schedule_date => 'Date';

  @override
  String get schedule_time => 'Time';

  @override
  String get schedule_empty => 'No schedules found';

  @override
  String get users_list_title => 'Users';

  @override
  String get users_add_title => 'New User';

  @override
  String get users_detail_title => 'User Details';

  @override
  String get users_role => 'Role';

  @override
  String get users_active => 'Active';

  @override
  String get users_inactive => 'Inactive';

  @override
  String get profile_title => 'My Profile';

  @override
  String get profile_edit => 'Edit Profile';

  @override
  String get profile_name => 'Name';

  @override
  String get profile_email => 'Email';

  @override
  String get profile_phone => 'Phone';

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_empty => 'No notifications';

  @override
  String get notifications_mark_read => 'Mark as read';

  @override
  String get reports_title => 'Reports';

  @override
  String get reports_generate => 'Generate Report';

  @override
  String get reports_date_range => 'Period';

  @override
  String get action_save => 'Save';

  @override
  String get action_delete => 'Delete';

  @override
  String get action_edit => 'Edit';

  @override
  String get action_create => 'Create';

  @override
  String get action_back => 'Back';

  @override
  String get action_yes => 'Yes';

  @override
  String get action_no => 'No';

  @override
  String get success_saved => 'Saved successfully';

  @override
  String get success_deleted => 'Deleted successfully';

  @override
  String get error_generic => 'An error occurred';

  @override
  String get error_connection => 'Connection error';

  @override
  String get error_timeout => 'Request timeout';

  @override
  String get common_user => 'User';

  @override
  String get common_users => 'Users';

  @override
  String get common_resident => 'Resident';

  @override
  String get common_residents => 'Residents';

  @override
  String get common_employee => 'Employee';

  @override
  String get common_administrator => 'Administrator';

  @override
  String get common_manager => 'Manager';

  @override
  String get common_name => 'Name';

  @override
  String get common_phone => 'Phone';

  @override
  String get common_type => 'Type';

  @override
  String get common_status => 'Status';

  @override
  String get common_active => 'Active';

  @override
  String get common_inactive => 'Inactive';

  @override
  String get common_all => 'All';

  @override
  String get common_search => 'Search';

  @override
  String get common_filter => 'Filter';

  @override
  String get common_no_data => 'No data available';

  @override
  String get common_loading_apartments => 'Loading apartments...';

  @override
  String get common_no_apartments => 'No apartments available';

  @override
  String get common_select_apartment => 'Select apartment';

  @override
  String get common_not_informed => 'Not informed';

  @override
  String get common_information => 'Information';

  @override
  String get common_details => 'Details';

  @override
  String get common_actions => 'Actions';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_required_field => 'Required field';

  @override
  String get common_success => 'Success';

  @override
  String get common_error => 'Error';

  @override
  String get common_warning => 'Warning';

  @override
  String get common_minutes => 'minutes';

  @override
  String get common_hours => 'hours';

  @override
  String get common_days => 'days';

  @override
  String get common_ago => 'ago';

  @override
  String get common_in => 'in';

  @override
  String get common_create_user => 'Create User';

  @override
  String get common_new_user => 'New User';

  @override
  String get common_user_type => 'User Type';

  @override
  String get common_user_created => 'User created successfully';

  @override
  String get common_fill_user_data => 'Fill in new user data';

  @override
  String get common_send_sms => 'Send SMS with credentials';

  @override
  String get residents_directory => 'Residents Directory';

  @override
  String get residents_statistics => 'Statistics';

  @override
  String get residents_link_apartment => 'Link Apartment';

  @override
  String get profile_user_not_found => 'User not found';

  @override
  String get profile_personal_info => 'PERSONAL INFORMATION';

  @override
  String get profile_full_name => 'Full Name';

  @override
  String get profile_login_name => 'Login Name';

  @override
  String get profile_user_type => 'User Type';

  @override
  String get profile_active_in_system => 'Active in system';

  @override
  String get profile_help_support => 'Help & Support';

  @override
  String get profile_get_in_touch => 'Get in touch';

  @override
  String get profile_support_email => 'Support: suporte@owany.com';

  @override
  String get profile_sign_out => 'Sign Out';

  @override
  String get profile_do_logout => 'Logout';

  @override
  String get profile_sign_out_confirm => 'Sign Out?';

  @override
  String get profile_disconnect_confirm =>
      'Are you sure you want to disconnect?';

  @override
  String get profile_type_admin => 'Administrator';

  @override
  String get profile_type_employee => 'Employee';

  @override
  String get profile_type_manager => 'Manager';

  @override
  String get profile_type_doorman => 'Doorman';

  @override
  String get profile_type_resident => 'Resident';

  @override
  String get profile_type_visitor => 'Visitor';

  @override
  String get notifications_unread => 'Unread';

  @override
  String get notifications_none_unread => 'No unread notifications';

  @override
  String get notifications_none => 'No notifications';

  @override
  String get notifications_removed => 'Notification removed';

  @override
  String get notifications_error_mark => 'Error marking notification';

  @override
  String get notifications_error_remove => 'Error removing notification';

  @override
  String get notifications_all_caught_up =>
      'You\'re all caught up with notifications';

  @override
  String get history_title => 'Solicitations History';

  @override
  String get history_no_records => 'No records registered yet';

  @override
  String get history_records_count => 'records registered';

  @override
  String get password_change => 'Change Password';

  @override
  String get password_min_chars => 'Minimum 6 characters';

  @override
  String get password_no_match => 'Passwords do not match';

  @override
  String get reports_analytics => 'Reports & Analytics';

  @override
  String get reports_loading_error => 'Error loading reports';

  @override
  String get reports_requests_summary => 'Requests Summary';

  @override
  String get reports_system_users => 'System Users';

  @override
  String get reports_alerts_notifications => 'Alerts & Notifications';

  @override
  String get reports_urgent_maintenance => 'Urgent Maintenance';

  @override
  String get reports_high_occupancy => 'High Occupancy';

  @override
  String get reports_occupancy => 'Occupancy';

  @override
  String get reports_satisfaction => 'Satisfaction';

  @override
  String get reports_building_summary => 'Building summary';

  @override
  String get reports_average_rating => 'Average rating';

  @override
  String get reports_available => 'Available';

  @override
  String get reports_party_room => 'Party Room';

  @override
  String get reports_no_data => 'No data available';

  @override
  String get reports_occupancy_rate => 'Occupancy Rate';

  @override
  String reports_apartments_of_total(int occupied, int total) {
    return '$occupied of $total apartments';
  }

  @override
  String reports_header_summary(int requests, int residents) {
    return '$requests requests • $residents residents';
  }

  @override
  String get agendamentos_title => 'Schedules';

  @override
  String get agendamentos_general => 'General (All Apartments)';

  @override
  String get agendamentos_condo => 'Condominium (Common Areas)';

  @override
  String get agendamentos_apartment => 'Apartment';

  @override
  String get notifications_no_unread => 'No unread notifications';

  @override
  String get common_system => 'System';

  @override
  String get time_now => 'Now';

  @override
  String time_ago_minutes(int count) {
    return '${count}m ago';
  }

  @override
  String time_ago_hours(int count) {
    return '${count}h ago';
  }

  @override
  String time_ago_days(int count) {
    return '${count}d ago';
  }

  @override
  String get time_yesterday => 'Yesterday';

  @override
  String get common_current => 'Current';

  @override
  String get common_internal => 'Internal';

  @override
  String get common_retry => 'Try again';

  @override
  String get common_update => 'Update';

  @override
  String get common_occupied => 'Occupied';

  @override
  String get common_total => 'Total';

  @override
  String get common_maintenance => 'Maintenance';

  @override
  String get reports_common_areas => 'Common Areas';

  @override
  String get reports_common_areas_subtitle => 'Status and occupancy of areas';

  @override
  String get reports_distribution_by_status => 'Distribution by status';

  @override
  String get reports_pool => 'Pool';

  @override
  String get reports_gym => 'Gym';

  @override
  String get reports_playground => 'Playground';

  @override
  String get reports_nps => 'NPS';

  @override
  String get reports_excellent => 'Excellent';

  @override
  String get reports_general_average => 'General Average';

  @override
  String get priority_urgent => 'URGENT';

  @override
  String get priority_high => 'HIGH';

  @override
  String get priority_medium => 'MEDIUM';

  @override
  String get priority_low => 'LOW';

  @override
  String get status_pending_short => 'Pend.';

  @override
  String get status_in_progress_short => 'Prog.';

  @override
  String get status_completed_short => 'Done';

  @override
  String get apartments_clear_all => 'Clear all';

  @override
  String get apartments_no_results => 'No apartments found';

  @override
  String get apartments_no_results_subtitle => 'Adjust filters to see results';

  @override
  String get apartments_complete_management => 'Complete management';

  @override
  String get apartments_total_residents => 'Total Residents';

  @override
  String get apartments_avg_per_apt => 'Avg/Apt';

  @override
  String get apartments_see_less => 'See less';

  @override
  String get apartments_see_more_stats => 'See more statistics';

  @override
  String get apartments_occupancy_rate => 'Occupancy Rate';

  @override
  String get apartments_search_hint => 'Search apartments...';

  @override
  String get apartments_advanced_filters => 'Advanced Filters';

  @override
  String get apartments_clear => 'Clear';

  @override
  String get apartments_apply_filters => 'Apply Filters';

  @override
  String get apartments_empty_subtitle =>
      'Start by adding the first apartment\nof the condominium';

  @override
  String get apartments_register => 'Register Apartment';

  @override
  String get apartments_error_title => 'Oops! Something went wrong';

  @override
  String get apartments_data_updated => 'Data updated';

  @override
  String get apartments_items => 'Items';

  @override
  String get apartments_detailed_info => 'Detailed Information';

  @override
  String get apartments_state => 'Status';

  @override
  String get apartments_linked => 'Linked';

  @override
  String get apartments_swap => 'Swap';

  @override
  String get apartments_register_exit => 'Register exit';

  @override
  String get apartments_make_available => 'Make available';

  @override
  String get apartments_no_residents => 'No residents';

  @override
  String get apartments_no_items => 'No items';

  @override
  String get apartments_edit => 'Edit Apartment';

  @override
  String get apartments_mark_available => 'Mark as Available';

  @override
  String get apartments_mark_maintenance => 'Mark as Maintenance';

  @override
  String get apartments_not_found => 'Apartment not found';

  @override
  String get apartments_manage_items => 'Manage Items';

  @override
  String get apartments_add_or_remove => 'Add or remove';

  @override
  String get apartments_assign_resident => 'Assign Resident';

  @override
  String get apartments_link_resident => 'Link resident';

  @override
  String get apartments_view_history => 'View History';

  @override
  String get apartments_entries_exits => 'Entries and exits';

  @override
  String get apartments_in_maintenance => 'In maintenance';

  @override
  String get apartments_available => 'Apartment available';

  @override
  String get apartments_make_available_question => 'Make resident available?';

  @override
  String apartments_remove_resident_confirm(String name) {
    return 'Do you want to remove \"$name\" from this apartment?';
  }

  @override
  String get apartments_remove => 'Remove';

  @override
  String get apartments_resident_available_success =>
      'Resident made available successfully!';

  @override
  String apartments_error_make_available(String error) {
    return 'Error making resident available: $error';
  }

  @override
  String get apartments_exit_invalid_resident =>
      'Could not register exit: invalid resident.';

  @override
  String apartments_confirm_exit(String name) {
    return 'Confirm the exit of $name from the apartment.';
  }

  @override
  String get apartments_exit_reason => 'Reason for exit (optional)';

  @override
  String get apartments_exit_reason_hint => 'E.g.: Moving, Sale, etc.';

  @override
  String get apartments_confirm_exit_button => 'Confirm Exit';

  @override
  String get apartments_exit_success => 'Exit registered successfully';

  @override
  String get apartments_exit_error => 'Error registering exit';

  @override
  String get apartments_details => 'Apartment Details';

  @override
  String get apartments_fill_fields =>
      'Fill in the fields to register a new apartment with complete information.';

  @override
  String get apartments_name => 'Apartment Name';

  @override
  String get apartments_name_hint => 'E.g.: Apt 101';

  @override
  String get apartments_number_hint => 'E.g.: 101';

  @override
  String get apartments_block_hint => 'E.g.: Block A';

  @override
  String get apartments_floor_hint => 'E.g.: 3';

  @override
  String get apartments_state_hint => 'Apartment status';

  @override
  String get apartments_valid_number => 'Enter a valid number';

  @override
  String get apartments_not_negative => 'Cannot be negative';

  @override
  String get apartments_rooms => 'Rooms';

  @override
  String get apartments_rooms_hint => 'E.g.: 2';

  @override
  String get apartments_notes => 'Notes (optional)';

  @override
  String get apartments_notes_hint => 'Additional details or notes';

  @override
  String get apartments_create_button => 'Create Apartment';

  @override
  String get apartments_created_success => 'Apartment created successfully!';

  @override
  String get apartments_premium_register => 'Premium apartment registration';

  @override
  String get apartments_organize_blocks =>
      'Organize blocks, units and status with Owany official colors.';

  @override
  String apartments_block_label(String name) {
    return 'Block $name';
  }

  @override
  String apartments_block_floor_label(String block, int floor) {
    return 'Block $block - Floor $floor';
  }

  @override
  String apartments_apt_block_label(String number, String block) {
    return 'Apt $number - $block';
  }

  @override
  String apartments_block_floor_display(String block, int floor) {
    return 'Block $block • ${floor}th floor';
  }

  @override
  String apartments_history_title(String number, String block) {
    return 'History of $number/$block';
  }

  @override
  String get users_title => 'Users';

  @override
  String get users_search_hint => 'Search user';

  @override
  String get users_search_placeholder => 'Enter name or login';

  @override
  String get users_empty_title => 'No users';

  @override
  String get users_empty_subtitle => 'Add a new user to get started';

  @override
  String get users_no_results => 'No results';

  @override
  String get users_no_results_subtitle => 'Adjust your search and try again';

  @override
  String get users_new => 'New User';

  @override
  String get users_reload => 'Reload';

  @override
  String get users_try_again => 'Try Again';

  @override
  String get users_type_admin => 'Admin';

  @override
  String get users_type_employee => 'Employee';

  @override
  String get users_type_manager => 'Manager';

  @override
  String get users_type_doorman => 'Doorman';

  @override
  String get users_type_resident => 'Resident';

  @override
  String get users_type_visitor => 'Visitor';

  @override
  String get users_create_new => 'Create New User';

  @override
  String get users_fill_data => 'Fill in new user data';

  @override
  String get users_full_name => 'Full Name';

  @override
  String get users_full_name_hint => 'E.g.: John Smith';

  @override
  String get users_login_name => 'Login Name';

  @override
  String get users_login_name_hint => 'E.g.: johnsmith';

  @override
  String get users_phone => 'Phone';

  @override
  String get users_phone_hint => '9 digits (e.g.: 84 123 4567)';

  @override
  String get users_phone_invalid => 'Enter 9 digits';

  @override
  String get users_user_type => 'User Type';

  @override
  String get users_send_sms_credentials => 'Send SMS with credentials';

  @override
  String get users_sms_subtitle =>
      'User will receive login and temporary password via SMS';

  @override
  String get users_security => 'Security';

  @override
  String get users_password => 'Password';

  @override
  String get users_password_hint => 'Enter a secure password';

  @override
  String get users_confirm_password => 'Confirm Password';

  @override
  String get users_confirm_password_hint => 'Confirm the password';

  @override
  String get users_password_no_match => 'Passwords do not match';

  @override
  String get users_min_chars => 'Minimum 6 characters';

  @override
  String get users_create_button => 'Create User';

  @override
  String get users_created_success => 'User created successfully!';

  @override
  String users_credentials_sent(String phone) {
    return 'Credentials were sent via SMS to $phone';
  }

  @override
  String get users_error_loading => 'Error loading user';

  @override
  String get users_not_found => 'User not found';

  @override
  String get users_information => 'Information';

  @override
  String get users_name => 'Name';

  @override
  String get users_login => 'Login';

  @override
  String get users_type => 'Type';

  @override
  String get users_status => 'Status';

  @override
  String get users_created_at => 'Created on';

  @override
  String get users_linked_apartment => 'Linked Apartment';

  @override
  String get users_residents => 'Residents';

  @override
  String get users_state => 'State';

  @override
  String get users_deactivate => 'Deactivate User?';

  @override
  String get users_deactivate_confirm =>
      'Are you sure you want to deactivate this user?';

  @override
  String get users_deactivate_button => 'Deactivate';

  @override
  String get common_activate => 'Activate';

  @override
  String get users_edit_title => 'Edit User';

  @override
  String get users_update_data => 'Update user data';

  @override
  String get users_update_info =>
      'Edit basic information. User type is read-only for security.';

  @override
  String get users_data => 'User data';

  @override
  String get users_full_name_label => 'Full name';

  @override
  String get users_full_name_example => 'E.g.: Maria Souza';

  @override
  String get users_phone_example => '(11) 99999-9999';

  @override
  String get users_save_changes => 'Save Changes';

  @override
  String get users_saving => 'Saving...';

  @override
  String get users_updated_success => 'User updated successfully!';

  @override
  String get users_actions => 'User Actions';

  @override
  String get users_reset_password => 'Password Reset';

  @override
  String get users_reset_confirm => 'Reset Password?';

  @override
  String get users_reset_description =>
      'A verification code will be sent via SMS to the user\'s registered phone. Confirm?';

  @override
  String get users_reset_sent => 'Reset code sent via SMS to user';

  @override
  String get users_reset_admin_title => 'Reset Password (Admin)';

  @override
  String get users_reset_admin_description =>
      'Enter the new password for the user. Password is NOT saved in SMS history.';

  @override
  String get users_reset_admin_new_password => 'New Password';

  @override
  String get users_reset_admin_confirm_password => 'Confirm New Password';

  @override
  String get users_reset_admin_send_sms => 'Send SMS with new password';

  @override
  String get users_reset_admin_password_min => 'Minimum 6 characters';

  @override
  String get users_reset_admin_password_mismatch => 'Passwords do not match';

  @override
  String get users_reset_admin_success => 'Password reset successfully';

  @override
  String get users_reset_admin_error => 'Error resetting password';

  @override
  String get users_reset_admin_cannot_self =>
      'Use the profile menu to change your own password';

  @override
  String get sms_cleanup_title => 'Clear Credential SMS';

  @override
  String get sms_cleanup_confirm =>
      'Are you sure? This will remove all credential and OTP SMS records from the database.';

  @override
  String sms_cleanup_success(int count) {
    return '$count SMS records deleted successfully';
  }

  @override
  String users_deactivate_description(String name) {
    return 'Are you sure you want to deactivate $name? This action can be reversed later.';
  }

  @override
  String get users_deactivated_success => 'User deactivated successfully';

  @override
  String get users_type_readonly_info =>
      'User type is shown for reference and remains locked on this screen.';

  @override
  String get users_error_reset => 'Error sending reset';

  @override
  String get users_error_deactivate => 'Error deactivating';

  @override
  String get users_error_login_name_not_found =>
      'Login name not found for this user';

  @override
  String get residents_loading => 'Loading residents...';

  @override
  String get residents_search_hint => 'Search by name, phone or apartment...';

  @override
  String get residents_all => 'All';

  @override
  String residents_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'residents',
      one: 'resident',
    );
    return '$count $_temp0';
  }

  @override
  String residents_of_total(int total) {
    return 'of $total';
  }

  @override
  String get residents_not_found => 'No resident found';

  @override
  String get residents_none_registered => 'No residents registered';

  @override
  String get residents_adjust_filters => 'Try adjusting the filters';

  @override
  String get residents_owner => 'Owner';

  @override
  String residents_since(String date) {
    return 'Resident since $date';
  }

  @override
  String get morador_detail_title => 'Resident Details';

  @override
  String get morador_error_loading => 'Error loading';

  @override
  String get morador_data => 'Resident data';

  @override
  String get morador_data_description =>
      'View and update basic information for this resident.';

  @override
  String get morador_name => 'Name';

  @override
  String get morador_name_required => 'Name is required';

  @override
  String get morador_name_hint => 'Enter the name';

  @override
  String get morador_user_id => 'User ID';

  @override
  String get morador_registration_date => 'Registration date';

  @override
  String get morador_save_changes => 'Save Changes';

  @override
  String get morador_updated_success => 'Resident updated successfully';

  @override
  String get morador_remove => 'Remove resident';

  @override
  String get morador_remove_warning =>
      'This action is irreversible. Confirm before permanently removing.';

  @override
  String get morador_delete_button => 'Delete resident';

  @override
  String get morador_delete_confirm => 'Delete Resident?';

  @override
  String get morador_delete_description =>
      'This action cannot be undone and will remove the resident from the system.';

  @override
  String get morador_deleted_success => 'Resident deleted successfully';

  @override
  String get morador_id_not_informed => 'ID not informed';

  @override
  String get morador_info_dynamic => 'Personal information loaded dynamically';

  @override
  String get morador_information => 'Information';

  @override
  String get morador_phone => 'Phone';

  @override
  String get morador_apartment => 'Apartment';

  @override
  String get morador_email => 'Email';

  @override
  String get maintenance_title => 'Maintenance';

  @override
  String get maintenance_filter_by_status => 'Filter by Status';

  @override
  String get maintenance_all => 'All';

  @override
  String get maintenance_status_pending => 'Pending';

  @override
  String get maintenance_status_in_progress => 'In Progress';

  @override
  String get maintenance_status_in_analysis => 'In Analysis';

  @override
  String get maintenance_status_waiting => 'Waiting';

  @override
  String get maintenance_status_completed => 'Completed';

  @override
  String get maintenance_status_cancelled => 'Cancelled';

  @override
  String get maintenance_status_rejected => 'Rejected';

  @override
  String get maintenance_loading => 'Loading requests...';

  @override
  String get maintenance_error_loading => 'Error loading';

  @override
  String get maintenance_try_again => 'Try Again';

  @override
  String get maintenance_empty => 'No requests found';

  @override
  String get maintenance_empty_subtitle =>
      'There are no maintenance requests at the moment';

  @override
  String get maintenance_empty_create_hint =>
      'Create a new request to get started';

  @override
  String get maintenance_empty_filter_hint => 'Try adjusting the filters';

  @override
  String get maintenance_search_hint => 'Search by title...';

  @override
  String maintenance_page_info(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get maintenance_previous => 'Previous';

  @override
  String get maintenance_next => 'Next';

  @override
  String maintenance_responsible_label(String name) {
    return 'Responsible: $name';
  }

  @override
  String maintenance_comments_count(int count) {
    return '$count comment(s)';
  }

  @override
  String maintenance_attachments_count(int count) {
    return '$count attachment(s)';
  }

  @override
  String maintenance_apt_block(String number, String block) {
    return 'Apt $number - $block';
  }

  @override
  String maintenance_time_minutes_ago(int count) {
    return '$count min ago';
  }

  @override
  String maintenance_time_hours_ago(int count) {
    return '${count}h ago';
  }

  @override
  String maintenance_time_days_ago(int count) {
    return '$count days ago';
  }

  @override
  String get maintenance_yesterday => 'Yesterday';

  @override
  String get maintenance_pending_count => 'Pending';

  @override
  String get maintenance_in_progress_count => 'In Progress';

  @override
  String get maintenance_completed_count => 'Completed';

  @override
  String get maintenance_detail_loading => 'Loading request...';

  @override
  String get maintenance_detail_not_found => 'Request not found';

  @override
  String get maintenance_detail_quick_actions => 'Quick actions';

  @override
  String get maintenance_detail_edit => 'Edit';

  @override
  String get maintenance_detail_complete => 'Complete';

  @override
  String get maintenance_detail_in_progress => 'In progress';

  @override
  String get maintenance_detail_reopen => 'Reopen';

  @override
  String get maintenance_detail_cancel_request => 'Cancel';

  @override
  String get maintenance_detail_reject_request => 'Reject';

  @override
  String get maintenance_detail_assign_responsible => 'Assign';

  @override
  String get maintenance_detail_define_deadline => 'Set Deadline';

  @override
  String get maintenance_detail_no_description => 'No description';

  @override
  String maintenance_detail_comments(int count) {
    return 'Comments ($count)';
  }

  @override
  String get maintenance_detail_no_comments => 'No comments yet';

  @override
  String get maintenance_detail_add_comment => 'Add comment...';

  @override
  String get maintenance_detail_internal_comment => 'Internal Comment';

  @override
  String get maintenance_detail_internal => 'Internal';

  @override
  String get maintenance_detail_send => 'Send';

  @override
  String get maintenance_detail_status_updated => 'Status updated';

  @override
  String get maintenance_detail_comment_added => 'Comment added successfully';

  @override
  String get maintenance_detail_updated => 'Request updated successfully';

  @override
  String get maintenance_detail_requester => 'Requester';

  @override
  String get maintenance_detail_apartment => 'Apartment';

  @override
  String get maintenance_detail_resident => 'Resident';

  @override
  String get maintenance_detail_responsible => 'Responsible';

  @override
  String get maintenance_detail_created_at => 'Created on';

  @override
  String get maintenance_detail_deadline => 'Deadline';

  @override
  String get maintenance_detail_updated_at => 'Updated on';

  @override
  String get maintenance_detail_edit_dialog_title => 'Edit request';

  @override
  String get maintenance_detail_deadline_label => 'Deadline';

  @override
  String get maintenance_detail_select_date => 'Select date';

  @override
  String get maintenance_detail_responsible_employee =>
      'Responsible (Employee)';

  @override
  String get maintenance_detail_no_employee => 'No employee available';

  @override
  String get maintenance_detail_select_responsible => 'Select responsible';

  @override
  String get maintenance_detail_no_employees => 'No employees';

  @override
  String get maintenance_detail_unknown => 'Unknown';

  @override
  String maintenance_detail_at_time(String time) {
    return 'at $time';
  }

  @override
  String get maintenance_request_title => 'New Request';

  @override
  String get maintenance_request_describe_problem => 'Describe the Problem';

  @override
  String get maintenance_request_describe_hint =>
      'Fill in the details so the responsible can attend';

  @override
  String get maintenance_request_problem_type => 'Problem Type (optional)';

  @override
  String get maintenance_request_subject => 'Subject';

  @override
  String get maintenance_request_subject_hint => 'E.g.: Leaking faucet';

  @override
  String get maintenance_request_description => 'Detailed Description';

  @override
  String get maintenance_request_description_hint =>
      'Detail the problem as much as possible...';

  @override
  String get maintenance_request_resident_responsible => 'Responsible Resident';

  @override
  String get maintenance_request_select_resident => 'Select the resident';

  @override
  String get maintenance_request_apartment => 'Apartment';

  @override
  String get maintenance_request_select_apartment => 'Select an apartment';

  @override
  String get maintenance_request_create => 'Create Request';

  @override
  String get maintenance_request_sending => 'Sending...';

  @override
  String get maintenance_request_success => 'Request created successfully!';

  @override
  String get maintenance_request_fill_required =>
      'Please fill all required fields';

  @override
  String get maintenance_request_select_apartment_error =>
      'Select an apartment';

  @override
  String get maintenance_request_select_resident_error =>
      'Select the responsible resident for the request';

  @override
  String get maintenance_request_user_not_authenticated =>
      'Error: User not authenticated';

  @override
  String get maintenance_request_resident_not_found =>
      'Could not identify resident. Please log in again.';

  @override
  String get problem_type_leak => 'Leak';

  @override
  String get problem_type_electrical => 'Electrical';

  @override
  String get problem_type_plumbing => 'Plumbing';

  @override
  String get problem_type_furniture => 'Furniture';

  @override
  String get problem_type_cleaning => 'Cleaning';

  @override
  String get problem_type_other => 'Other';

  @override
  String get agendamentos_schedule => 'Schedule';

  @override
  String get agendamentos_date_label => 'Date:';

  @override
  String get agendamentos_time_label => 'Time:';

  @override
  String get agendamentos_estimated_duration => 'Estimated Duration:';

  @override
  String get agendamentos_location => 'Location';

  @override
  String get agendamentos_priority => 'Priority:';

  @override
  String get agendamentos_responsible => 'Responsible';

  @override
  String get agendamentos_your_response => 'Your Response';

  @override
  String get agendamentos_confirm => 'Confirm';

  @override
  String get agendamentos_reschedule => 'Reschedule';

  @override
  String get agendamentos_decline => 'Decline';

  @override
  String get agendamentos_response_sent => 'Response sent';

  @override
  String get agendamentos_send_response => 'Send Response';

  @override
  String get agendamentos_error_loading => 'Error loading schedule';

  @override
  String get agendamentos_no_results_filter => 'No results for these filters';

  @override
  String get agendamentos_new => 'New';

  @override
  String get agendamentos_search_hint => 'Search by date, apartment...';

  @override
  String get agendamentos_no_title => 'No title';

  @override
  String get agendamentos_unknown => 'Unknown';

  @override
  String get agendamentos_no_responsible => 'No responsible';

  @override
  String get agendamentos_not_found => 'No schedule found';

  @override
  String get agendamentos_try_filters => 'Try adjusting your filters';

  @override
  String get agendamentos_loading => 'Loading schedules...';

  @override
  String get agendamentos_new_title => 'New Schedule';

  @override
  String get agendamentos_title_required => 'Title is required';

  @override
  String get agendamentos_type_required => 'Type is required';

  @override
  String get agendamentos_date_required => 'Date is required';

  @override
  String get agendamentos_time_required => 'Time is required';

  @override
  String get agendamentos_location_required => 'Select the schedule location';

  @override
  String get agendamentos_responsible_required => 'Responsible is required';

  @override
  String get agendamentos_confirm_title => 'Confirm Schedule';

  @override
  String get agendamentos_sms_will_send => 'SMS will be sent to resident';

  @override
  String get agendamentos_created_success => 'Schedule created successfully!';

  @override
  String get agendamentos_schedule_maintenance => 'Schedule the Maintenance';

  @override
  String get agendamentos_fill_details =>
      'Fill in the details to organize the service';

  @override
  String get agendamentos_send_message_resident => 'Send message to resident';

  @override
  String get agendamentos_sms_mass_tooltip =>
      'Mass SMS must be scheduled separately in Announcements';

  @override
  String get agendamentos_title_field => 'Title';

  @override
  String get agendamentos_title_hint => 'E.g.: Cleaning, Plumbing repair';

  @override
  String get agendamentos_type => 'Type';

  @override
  String get agendamentos_description_optional => 'Description (optional)';

  @override
  String get agendamentos_description_hint => 'Describe the schedule details';

  @override
  String get agendamentos_schedule_section => 'Schedule';

  @override
  String get agendamentos_date_field => 'Date';

  @override
  String get agendamentos_notes_optional => 'Notes (optional)';

  @override
  String get agendamentos_notes_field => 'Notes';

  @override
  String get agendamentos_notes_hint => 'Additional notes';

  @override
  String get agendamentos_create_button => 'Create';

  @override
  String get agendamentos_select_date => 'Select date';

  @override
  String get agendamentos_time_field => 'Time';

  @override
  String get agendamentos_select_time => 'Select the time';

  @override
  String get agendamentos_where_question => 'Where will it be done?';

  @override
  String get agendamentos_select_location => 'Select the location';

  @override
  String get agendamentos_no_employees => 'No employee available';

  @override
  String get agendamentos_general_condo => 'GENERAL/CONDO';

  @override
  String get agendamentos_apt => 'Apt';

  @override
  String get agendamentos_apartment_label => 'APARTMENT';

  @override
  String get agendamentos_not_specified => 'Not specified';

  @override
  String get create_morador_title => 'New Resident';

  @override
  String get create_morador_header => 'Create New Resident';

  @override
  String get create_morador_description =>
      'Associate an existing user with an available apartment to complete the resident registration.';

  @override
  String get create_morador_resident_users => 'Resident Users';

  @override
  String get create_morador_available_apts => 'Available Apts';

  @override
  String get create_morador_data => 'Resident Data';

  @override
  String get create_morador_name_label => 'Resident Name';

  @override
  String get create_morador_name_hint => 'E.g.: John Smith';

  @override
  String get create_morador_select_user => 'Select a user';

  @override
  String get create_morador_no_users =>
      'No users of type Resident available. Reload or register a user first.';

  @override
  String get create_morador_apartment_optional => 'Apartment (optional)';

  @override
  String get create_morador_no_apartment_now => 'No apartment now (link later)';

  @override
  String get create_morador_no_apartments =>
      'No apartments available at the moment. Reload to try again.';

  @override
  String get create_morador_button => 'Create Resident';

  @override
  String get create_morador_creating => 'Creating...';

  @override
  String get create_morador_success => 'Resident created successfully!';

  @override
  String get create_morador_error => 'Error creating resident';

  @override
  String get create_morador_error_loading => 'Error loading data';

  @override
  String get create_morador_tip =>
      'Tip: select users already approved as Resident to ensure correct access to modules.';

  @override
  String get sms_massa_title => 'Mass SMS';

  @override
  String get sms_massa_tab_send => 'Send SMS';

  @override
  String get sms_massa_tab_history => 'History';

  @override
  String get sms_massa_info_text =>
      'Send SMS to multiple users\nMax. 500 characters per message';

  @override
  String get sms_massa_selection_mode => 'Selection Mode';

  @override
  String get sms_massa_by_type => 'By Type';

  @override
  String get sms_massa_specific => 'Specific';

  @override
  String get sms_massa_user_types => 'User Types';

  @override
  String sms_massa_select_users(int selected, int total) {
    return 'Select Users ($selected/$total)';
  }

  @override
  String get sms_massa_sms_message => 'SMS Message';

  @override
  String get sms_massa_type_message => 'Type the message...';

  @override
  String get sms_massa_send_app_notification => 'Send app notification';

  @override
  String get sms_massa_besides_sms => 'Besides SMS, create app notification';

  @override
  String get sms_massa_notification_title_optional =>
      'Notification Title (optional)';

  @override
  String get sms_massa_notification_title_hint =>
      'E.g.: Important Announcement';

  @override
  String get sms_massa_send_button => 'Send Mass SMS';

  @override
  String get sms_massa_type_message_error => 'Type a message';

  @override
  String get sms_massa_message_too_long =>
      'Message too long (max 500 characters)';

  @override
  String get sms_massa_select_user_type_error =>
      'Select at least one user type';

  @override
  String get sms_massa_select_user_error => 'Select at least one user';

  @override
  String sms_massa_success(int sent, int total) {
    return 'SMS sent: $sent/$total successfully';
  }

  @override
  String sms_massa_error_sending(String error) {
    return 'Error sending SMS: $error';
  }

  @override
  String get sms_massa_no_recipients => 'No recipient available';

  @override
  String get sms_massa_no_history => 'No SMS sent yet';

  @override
  String get sms_massa_history_appear_here => 'Send history will appear here';

  @override
  String sms_massa_by(String name) {
    return 'By $name';
  }

  @override
  String get sms_massa_recipients => 'Recipients';

  @override
  String get sms_massa_sent => 'Sent';

  @override
  String get sms_massa_notifications => 'Notifications';

  @override
  String get sms_massa_time_now => 'Now';

  @override
  String sms_massa_time_minutes_ago(int count) {
    return '${count}m ago';
  }

  @override
  String sms_massa_time_hours_ago(int count) {
    return '${count}h ago';
  }

  @override
  String sms_massa_time_days_ago(int count) {
    return '${count}d ago';
  }

  @override
  String get sms_massa_yesterday => 'Yesterday';

  @override
  String get sms_massa_administrator => 'Administrator';

  @override
  String get sms_massa_employee => 'Employee';

  @override
  String get sms_massa_resident => 'Resident';

  @override
  String get change_password_success => 'Password changed successfully!';

  @override
  String get change_password_protect_account => 'Protect your account';

  @override
  String get change_password_tip =>
      'Change your password regularly and avoid reusing old passwords.';

  @override
  String get change_password_current => 'Current Password';

  @override
  String get change_password_current_hint => 'Enter your current password';

  @override
  String get change_password_new => 'New Password';

  @override
  String get change_password_new_hint => 'Create a new password';

  @override
  String get change_password_new_required => 'Enter a new password';

  @override
  String get change_password_confirm => 'Confirm New Password';

  @override
  String get change_password_confirm_hint => 'Repeat the new password';

  @override
  String get change_password_confirm_required => 'Confirm your password';

  @override
  String get change_password_saving => 'Saving...';

  @override
  String get mp_form_edit_title => 'Edit Maintenance';

  @override
  String get mp_form_new_title => 'New Maintenance';

  @override
  String get mp_form_title_required => 'Title is required';

  @override
  String get mp_form_next_maintenance_required =>
      'Next maintenance date is required';

  @override
  String get mp_form_updated_success => 'Maintenance updated successfully';

  @override
  String get mp_form_created_success => 'Maintenance created successfully';

  @override
  String get mp_form_save_error => 'Error saving maintenance';

  @override
  String get mp_form_title_hint => 'E.g.: Engine oil change';

  @override
  String get mp_form_maintenance_type => 'Maintenance Type';

  @override
  String get mp_form_type_hint => 'E.g.: Preventive, Corrective';

  @override
  String get mp_form_select_frequency => 'Select frequency';

  @override
  String get mp_form_select_date => 'Select date';

  @override
  String get mp_form_description_hint => 'Maintenance details';

  @override
  String get mp_form_supplier_hint => 'Supplier name';

  @override
  String get mp_form_supplier_phone => 'Supplier Phone';

  @override
  String get mp_form_freq_weekly => 'Weekly';

  @override
  String get mp_form_freq_monthly => 'Monthly';

  @override
  String get mp_form_freq_quarterly => 'Quarterly';

  @override
  String get mp_form_freq_semiannually => 'Semiannually';

  @override
  String get mp_form_freq_annually => 'Annually';

  @override
  String get history_residents_title => 'Residents History';

  @override
  String get history_current_residents => 'Current Residents';

  @override
  String get history_complete => 'Complete History';

  @override
  String get history_no_current_residents => 'No residents currently';

  @override
  String get history_period => 'Period';

  @override
  String get history_records => 'records';

  @override
  String get history_filter_30_days => 'Last 30 days';

  @override
  String get history_filter_6_months => 'Last 6 months';

  @override
  String get history_filter_12_months => 'Last 12 months';

  @override
  String get history_filter_all => 'All history';

  @override
  String get history_active => 'Active';

  @override
  String get history_previous => 'Previous';

  @override
  String get history_average => 'Average';

  @override
  String get history_occupancy_timeline => 'Occupancy Timeline';

  @override
  String get reports_critical_events => 'Critical events in the system';

  @override
  String reports_leak_detected_apt(String aptNumber) {
    return 'Leak detected in apt $aptNumber';
  }

  @override
  String get reports_pending_scheduling => 'Pending Scheduling';

  @override
  String get reports_responsible_unconfirmed => 'Responsible did not confirm';

  @override
  String reports_building_occupied_percent(int percent) {
    return '$percent% of building occupied';
  }

  @override
  String get reports_status_active => 'Active';

  @override
  String get reports_status_maintenance => 'Maintenance';

  @override
  String get reports_free => 'Free';

  @override
  String reports_cost_per_hour(String cost) {
    return 'MZN $cost/h';
  }

  @override
  String get register_min_3_chars => 'Must have at least 3 characters';

  @override
  String get register_invalid_phone => 'Invalid phone number';

  @override
  String get register_password_required => 'Password is required';

  @override
  String get register_password_min_length =>
      'Password must have at least 6 characters';

  @override
  String get register_confirm_password_required =>
      'Password confirmation is required';

  @override
  String get register_passwords_dont_match => 'Passwords do not match';

  @override
  String get register_accept_terms_label => 'I accept the Terms of Service';

  @override
  String get avaliar_rate_service => 'Rate the Service';

  @override
  String get avaliar_service_completed => 'Service Completed';

  @override
  String get avaliar_service => 'Service';

  @override
  String get avaliar_general_cleaning => 'General cleaning';

  @override
  String get avaliar_select_rating => 'Select a rating';

  @override
  String get avaliar_very_dissatisfied => 'Very dissatisfied 😞';

  @override
  String get avaliar_dissatisfied => 'Dissatisfied 😕';

  @override
  String get avaliar_neutral => 'Neutral 😐';

  @override
  String get avaliar_satisfied => 'Satisfied 😊';

  @override
  String get avaliar_very_satisfied => 'Very satisfied! 😁';

  @override
  String get avaliar_what_worked_well => 'What worked well?';

  @override
  String get avaliar_aspect_punctuality => 'Punctuality';

  @override
  String get avaliar_aspect_quality => 'Quality';

  @override
  String get avaliar_aspect_politeness => 'Politeness';

  @override
  String get avaliar_aspect_cleanliness => 'Cleanliness';

  @override
  String get avaliar_recommend_professional =>
      'Would you recommend this professional?';

  @override
  String get avaliar_yes_definitely => 'Yes, definitely!';

  @override
  String get avaliar_leave_comment => 'Leave a comment (optional)';

  @override
  String get avaliar_share_experience => 'Share your experience...';

  @override
  String get avaliar_skip => 'Skip';

  @override
  String get avaliar_send => 'Submit';

  @override
  String get avaliar_select_classification => 'Select a classification';

  @override
  String get avaliar_thank_you => 'Thank you for your feedback!';

  @override
  String get items_apartment_title => 'Apartment Items';

  @override
  String get items_no_permission =>
      'Only manager or employee can manage items.';

  @override
  String get items_no_delete_permission => 'No permission to delete items.';

  @override
  String get items_edit_item => 'Edit Item';

  @override
  String get items_new_item => 'New Item';

  @override
  String items_for_apartment(String name) {
    return 'For apartment $name';
  }

  @override
  String get items_name_label => 'Item Name';

  @override
  String get items_name_hint => 'E.g.: Air Conditioner, Refrigerator, etc';

  @override
  String get items_description_label => 'Description (optional)';

  @override
  String get items_description_hint =>
      'Add information about condition, brand, etc';

  @override
  String get items_quantity_label => 'Quantity';

  @override
  String get items_quantity_hint => 'E.g.: 1';

  @override
  String get items_estimated_value_label => 'Estimated Value (MZN)';

  @override
  String get items_estimated_value_hint => 'E.g.: 1500.00';

  @override
  String get items_type_label => 'Item Type';

  @override
  String get items_type_furniture => 'Furniture';

  @override
  String get items_type_appliance => 'Appliance';

  @override
  String get items_type_electronics => 'Electronics';

  @override
  String get items_type_plumbing => 'Plumbing';

  @override
  String get items_type_lighting => 'Lighting';

  @override
  String get items_type_structure => 'Structure';

  @override
  String get items_type_other => 'Other';

  @override
  String get items_type_not_informed => 'Type not informed';

  @override
  String get items_update_item => 'Update Item';

  @override
  String get items_add_item => 'Add Item';

  @override
  String get items_close => 'Close';

  @override
  String get items_name_required => 'Name is required';

  @override
  String get items_quantity_invalid =>
      'Quantity must be a number greater than zero';

  @override
  String get items_quantity_max => 'Maximum quantity allowed is 9999';

  @override
  String get items_created_success => 'Item created successfully';

  @override
  String get items_updated_success => 'Item updated successfully';

  @override
  String items_save_error(String error) {
    return 'Error saving item: $error';
  }

  @override
  String get items_delete_title => 'Delete Item?';

  @override
  String get items_delete_confirm => 'This action cannot be undone.';

  @override
  String get items_deleted_success => 'Item deleted successfully';

  @override
  String items_delete_error(String error) {
    return 'Error deleting item: $error';
  }

  @override
  String get items_load_error => 'Could not load items for this apartment.';

  @override
  String get items_check_connection => 'Check your connection and try again';

  @override
  String get items_view_details => 'View Details';

  @override
  String get items_error_details_title => 'Error details';

  @override
  String get items_unknown_error => 'Unknown error';

  @override
  String get items_empty_title => 'No items registered';

  @override
  String get items_empty_subtitle =>
      'Add items to keep a record of what is in the apartment';

  @override
  String get items_add_first => 'Add First Item';

  @override
  String get common_not_available => 'N/A';

  @override
  String get mp_cost_hint => '0.00';

  @override
  String get mp_currency_prefix => 'MZN ';

  @override
  String get responder_title => 'Respond';

  @override
  String get responder_proposed_schedule => 'Proposed Schedule';

  @override
  String get responder_service => 'Service';

  @override
  String get responder_service_example => 'General cleaning - Apt. 402';

  @override
  String get responder_date_example => 'January 15, 2026';

  @override
  String get responder_time_slot => 'Time Slot';

  @override
  String get responder_time_example => '10:00 - 11:00';

  @override
  String get responder_responsible_example => 'John Smith';

  @override
  String get responder_what_response => 'What is your response?';

  @override
  String get responder_accept => 'Accept';

  @override
  String get responder_decline => 'Decline';

  @override
  String get responder_select_new_datetime => 'Select a new date and time';

  @override
  String get responder_select => 'Select';

  @override
  String get responder_hour => 'Hour';

  @override
  String get responder_message_optional => 'Message (optional)';

  @override
  String get responder_decline_reason_hint =>
      'Describe the reason for declining...';

  @override
  String get responder_schedule_accepted => 'Schedule accepted';

  @override
  String get responder_schedule_declined => 'Schedule declined';

  @override
  String settings_theme_changed(String theme) {
    return 'Theme changed to $theme';
  }

  @override
  String error_update_with_details(String error) {
    return 'Error updating: $error';
  }

  @override
  String error_delete_with_details(String error) {
    return 'Error deleting: $error';
  }

  @override
  String get morador_name_label => 'Resident Name';

  @override
  String morador_since_date(String date) {
    return 'Resident since $date';
  }

  @override
  String get error_creating_request => 'Error creating request';

  @override
  String get avaliar_placeholder_name => 'John Doe';

  @override
  String historico_residents_title(String title) {
    return 'Residents History - $title';
  }

  @override
  String get history_entry => 'Entry';

  @override
  String get history_exit => 'Exit';

  @override
  String get history_duration => 'Duration';

  @override
  String get history_present => 'Present';

  @override
  String get reports_export_requests_excel => 'Requests (Excel)';

  @override
  String get reports_export_requests_pdf => 'Requests (PDF)';

  @override
  String get reports_export_apartments_excel => 'Apartments (Excel)';

  @override
  String get reports_export_residents_excel => 'Residents (Excel)';

  @override
  String get reports_export_users_excel => 'Users (Excel)';

  @override
  String get reports_export_agendamentos_excel => 'Schedules (Excel)';

  @override
  String get reports_export_manutencoes_excel =>
      'Preventive Maintenance (Excel)';

  @override
  String get reports_export_ativos_excel => 'Assets/Inventory (Excel)';

  @override
  String get reports_export_sms_excel => 'SMS History (Excel)';

  @override
  String get reports_export_kpi_excel => 'KPIs (Excel)';

  @override
  String get reports_export_kpi_pdf => 'KPIs (PDF)';

  @override
  String get reports_export_complete => '📦 Complete Report (Folder)';

  @override
  String get reports_export_complete_zip => '📦 Complete Report (ZIP)';

  @override
  String get reports_exporting => 'Exporting...';

  @override
  String get reports_exporting_multiple => 'Exporting multiple files...';

  @override
  String get reports_export_tooltip => 'Export reports';

  @override
  String get reports_kpi_mttr => 'MTTR';

  @override
  String get reports_delay_stats => 'Delay Statistics';

  @override
  String get reports_distribution_by_type => 'Distribution by Type';

  @override
  String get reports_top_late_responsible => 'Top Late Responsible';

  @override
  String get reports_monthly_evolution => 'Monthly Evolution';

  @override
  String get items_transfer_title => 'Transfer item';

  @override
  String get items_transfer_button => 'Transfer';

  @override
  String get items_update_state_title => 'Update item state';

  @override
  String get items_update_state_button => 'Update state';

  @override
  String get items_movement_history => 'Movement history';

  @override
  String get items_history_load_error => 'Error loading history';

  @override
  String get items_history_empty => 'No history found.';

  @override
  String get items_history_button => 'History';

  @override
  String get items_no_movement_found => 'No movement found for this item.';

  @override
  String get items_movement_details => 'Movement Details';

  @override
  String get items_origin => 'Origin';

  @override
  String get items_destination => 'Destination';

  @override
  String get items_reason => 'Reason';

  @override
  String get items_observations => 'Observations';

  @override
  String get items_transfer_dialog_title => 'Transfer Item';

  @override
  String get items_dest_apartment_id => 'Destination apartment (ID)';

  @override
  String get items_new_state_optional => 'New state (optional)';

  @override
  String get items_reason_optional => 'Reason (optional)';

  @override
  String get items_observations_optional => 'Observations (optional)';

  @override
  String get items_transfer_success => 'Transfer completed successfully';

  @override
  String get items_transfer_fail => 'Transfer failed';

  @override
  String get items_update_state_dialog_title => 'Update State';

  @override
  String get items_new_state => 'New state';

  @override
  String get items_update_success => 'State updated successfully';

  @override
  String get items_update_fail => 'Failed to update state';

  @override
  String get items_item_not_provided => 'Item not provided';

  @override
  String get items_update_state_menu => 'Update State';

  @override
  String get items_history_title => 'Item History';

  @override
  String get common_view_all => 'View all';

  @override
  String get common_history => 'History';

  @override
  String get common_close => 'Close';

  @override
  String get common_search_placeholder => 'Search item or apartment...';

  @override
  String get common_search_action => 'Search (placeholder)';

  @override
  String get common_add => 'Add';

  @override
  String get common_remove => 'Remove';

  @override
  String get common_save => 'Save';

  @override
  String get common_saving => 'Saving...';

  @override
  String get assets_item_not_found => 'Item not found';

  @override
  String get request_types_title => 'Request Types';

  @override
  String get request_types_add_new => 'Add new type:';

  @override
  String get request_types_hint => 'Ex: Electrical, Leak';

  @override
  String get request_types_registered => 'Registered types:';

  @override
  String get request_types_empty => 'No types registered.';

  @override
  String get apartments_add_new => 'Add Apartment';

  @override
  String get assets_management_title => 'Asset Management';

  @override
  String assets_items_registered(int count) {
    return '$count items registered';
  }

  @override
  String get assets_scan_qr => 'Scan QR Code';

  @override
  String get assets_generate_batch_qr => 'Generate QR Codes in Batch';

  @override
  String get assets_search_placeholder => 'Search assets';

  @override
  String get assets_search_hint => 'Name, code or type...';

  @override
  String get assets_filter_all => 'All';

  @override
  String get assets_filter_available => 'Available';

  @override
  String get assets_filter_maintenance => 'Maintenance';

  @override
  String get assets_filter_damaged => 'Damaged';

  @override
  String get assets_filter_by_apartment => 'By Apt';

  @override
  String assets_results_count(int count) {
    return '$count result(s)';
  }

  @override
  String get assets_stat_total => 'Total';

  @override
  String get assets_sort_by_name => 'Sort by name';

  @override
  String get assets_sort_by_code => 'Sort by code';

  @override
  String get assets_sort_by_state => 'Sort by state';

  @override
  String get assets_label_name => 'Name';

  @override
  String get assets_label_code => 'Code';

  @override
  String get assets_label_state => 'State';

  @override
  String get assets_fail_open_details => 'Failed to open details';

  @override
  String get assets_code_not_generated => 'Code not generated';

  @override
  String get assets_copy_code => 'Copy code';

  @override
  String get assets_code_copied => 'Code copied';

  @override
  String get assets_menu_qr_code => 'QR Code';

  @override
  String get assets_menu_edit => 'Edit';

  @override
  String get assets_menu_transfer => 'Transfer';

  @override
  String get assets_menu_generate_code => 'Generate Code';

  @override
  String get assets_menu_delete => 'Delete';

  @override
  String get assets_no_results => 'No results';

  @override
  String get assets_no_items => 'No assets registered';

  @override
  String get assets_try_another_search =>
      'Try another search term or clear filters.';

  @override
  String get assets_start_adding => 'Start by adding your first asset.';

  @override
  String get assets_add => 'Add Asset';

  @override
  String get assets_select_apartment => 'Select Apartment';

  @override
  String assets_code_generated_with_value(String code) {
    return 'Code generated: $code';
  }

  @override
  String get assets_code_generated_success => 'Code generated successfully';

  @override
  String get assets_code_generate_fail => 'Failed to generate code';

  @override
  String get assets_close => 'Close';

  @override
  String get assets_copy => 'Copy';

  @override
  String get assets_edit_asset => 'Edit Asset';

  @override
  String get assets_new_asset => 'New Asset';

  @override
  String get assets_field_apartment => 'Apartment';

  @override
  String get assets_field_name_required => 'Name *';

  @override
  String get assets_field_description => 'Description';

  @override
  String get assets_field_type => 'Type';

  @override
  String get assets_field_quantity => 'Quantity';

  @override
  String get assets_state_new => 'New';

  @override
  String get assets_state_available => 'Available';

  @override
  String get assets_state_used => 'Used';

  @override
  String get assets_state_in_maintenance => 'In maintenance';

  @override
  String get assets_state_damaged => 'Damaged';

  @override
  String get assets_save => 'Save';

  @override
  String get assets_asset_updated => 'Asset updated';

  @override
  String get assets_asset_added => 'Asset added';

  @override
  String get assets_transfer_asset => 'Transfer Asset';

  @override
  String get assets_link => 'Link';

  @override
  String get assets_move_to_stock => 'Move to Stock';

  @override
  String get assets_dest_apartment => 'Destination apartment';

  @override
  String get assets_new_state => 'New state';

  @override
  String get assets_field_reason_required => 'Reason *';

  @override
  String get assets_field_observations => 'Observations';

  @override
  String get assets_inform_reason => 'Please inform the transfer reason';

  @override
  String get assets_session_expired => 'Session expired. Please login again.';

  @override
  String get assets_transfer_completed => 'Transfer completed';

  @override
  String get assets_transfer_failed => 'Transfer failed';

  @override
  String get assets_delete_asset => 'Delete Asset';

  @override
  String get assets_delete_confirm =>
      'Are you sure you want to delete this asset?';

  @override
  String get assets_delete_irreversible => 'This action cannot be undone.';

  @override
  String get assets_asset_deleted => 'Asset deleted';

  @override
  String assets_files_saved(int count) {
    return '$count file(s) saved';
  }

  @override
  String get assets_search_by_code => 'Search by Code';

  @override
  String get assets_patrimony_code => 'Patrimony code';

  @override
  String assets_code_not_found(String code) {
    return 'Code \"$code\" not found.';
  }

  @override
  String get assets_register => 'Register';

  @override
  String get assets_scan_qr_short => 'Scan QR';

  @override
  String get assets_generate_codes => 'Generate codes';

  @override
  String get assets_search_by_name_desc_code =>
      'Search by name, description or code';

  @override
  String assets_count(int count) {
    return '$count asset(s)';
  }

  @override
  String assets_code_label(String code) {
    return 'Code: $code';
  }

  @override
  String get assets_code_not_generated_msg => 'Patrimony code not generated';

  @override
  String get assets_show_qr => 'Show QR';

  @override
  String get assets_no_items_loaded =>
      'No assets loaded. Use the scanner to query an asset.';

  @override
  String get assets_no_match_filter => 'No assets match the search filter.';

  @override
  String assets_consulted(String code) {
    return 'Asset consulted: $code';
  }

  @override
  String get assets_consult_fail => 'Failed to consult asset';

  @override
  String get assets_codes_generated => 'Patrimony codes generated';

  @override
  String get assets_codes_generate_fail => 'Failed to generate codes';

  @override
  String get assets_qr_patrimony => 'Patrimony QR';

  @override
  String get assets_register_not_implemented =>
      'Asset registration not yet implemented';

  @override
  String assets_detail_title(String code) {
    return 'Asset • $code';
  }

  @override
  String get assets_refresh => 'Refresh';

  @override
  String get assets_error_load => 'Error loading asset';

  @override
  String get assets_try_again => 'Try again';

  @override
  String get assets_not_linked => '(not linked)';

  @override
  String get assets_stat_quantity => 'Quantity';

  @override
  String get assets_stat_estimated_value => 'Estimated value';

  @override
  String get assets_stat_last_movement => 'Last movement';

  @override
  String get assets_details => 'Details';

  @override
  String get assets_acquisition_date => 'Acquisition date';

  @override
  String get assets_identifier_code => 'Identifier code';

  @override
  String get assets_current_state => 'Current state';

  @override
  String get assets_notes => 'Notes';

  @override
  String get assets_movement_history => 'Movement History';

  @override
  String get assets_no_movement_registered => 'No movement registered';

  @override
  String get assets_movement => 'Movement';

  @override
  String get assets_origin => 'Origin';

  @override
  String get assets_destination => 'Destination';

  @override
  String get assets_responsible => 'Responsible';

  @override
  String get assets_not_informed => 'Not informed';

  @override
  String get assets_attachments => 'Attachments';

  @override
  String get assets_no_attachments => 'No attachments available';

  @override
  String get assets_footer => 'Owany • Asset Management';

  @override
  String get assets_no_apartment_for_transfer =>
      'No apartment available for transfer.';

  @override
  String get assets_stock_without_apartment => 'Stock (no apartment)';

  @override
  String assets_apartment_block_label(String numero, String bloco) {
    return 'Apt $numero - Block $bloco';
  }

  @override
  String assets_apartment_short(String numero) {
    return 'Apt $numero';
  }

  @override
  String get assets_na => 'N/A';

  @override
  String get assets_motivo => 'Reason';

  @override
  String get assets_observacoes => 'Observations';

  @override
  String assets_asset_title(String codigo) {
    return 'Asset • $codigo';
  }

  @override
  String get common_refresh => 'Refresh';

  @override
  String get assets_error_loading => 'Error loading';

  @override
  String get assets_quantity => 'Quantity';

  @override
  String get assets_estimated_value => 'Estimated Value';

  @override
  String get assets_last_movement => 'Last Movement';

  @override
  String get assets_type => 'Type';

  @override
  String get assets_description => 'Description';

  @override
  String get assets_no_movements => 'No movements registered';

  @override
  String get assets_state => 'State';

  @override
  String get assets_no_apt_available => 'No apartment available for transfer';

  @override
  String get assets_field_reason => 'Reason';

  @override
  String get assets_no_apartment_transfer => 'No apartment to transfer';

  @override
  String get mp_register_execution => 'Register Execution';

  @override
  String get mp_execution_status => 'Execution Status';

  @override
  String get mp_execution_date => 'Completion Date';

  @override
  String get mp_select_date => 'Select date';

  @override
  String get mp_invoice => 'Invoice (optional)';

  @override
  String get mp_invoice_hint => 'Ex: INV-001234';

  @override
  String get mp_status_concluida => 'Completed';

  @override
  String get mp_status_em_andamento => 'In Progress';

  @override
  String get mp_status_cancelada => 'Cancelled';

  @override
  String get mp_save_execution => 'Save Execution';

  @override
  String get mp_invoice_label => 'Invoice';

  @override
  String residents_apt_label(String numero) {
    return 'Apt $numero';
  }

  @override
  String residents_block_label(String bloco) {
    return 'Block $bloco';
  }

  @override
  String residents_floor_label(int andar) {
    return '${andar}th floor';
  }

  @override
  String get residents_no_apartment => 'No linked apartment';

  @override
  String get residents_no_account => 'No linked account';

  @override
  String get residents_with_account => 'With linked account';

  @override
  String get residents_contact => 'Contact';

  @override
  String get residents_resident => 'Resident';

  @override
  String get residents_tenant => 'Tenant';

  @override
  String get residents_owner_full => 'Owner';

  @override
  String get residents_active => 'Active';

  @override
  String get residents_inactive => 'Inactive';

  @override
  String get residents_group_no_apartment => 'No apartment';

  @override
  String get maintenance_my_requests => 'My Requests';

  @override
  String get maintenance_all_requests => 'All Requests';

  @override
  String get maintenance_exporting => 'Exporting requests...';

  @override
  String get maintenance_export_tooltip => 'Export requests';

  @override
  String maintenance_export_error(String error) {
    return 'Error exporting: $error';
  }

  @override
  String maintenance_total_label(int count) {
    return '$count requests';
  }

  @override
  String maintenance_deadline_label(String date) {
    return 'Deadline: $date';
  }

  @override
  String get maintenance_overdue => 'Overdue';

  @override
  String get maintenance_no_responsible => 'No responsible';

  @override
  String maintenance_created_by(String name) {
    return 'By $name';
  }

  @override
  String get maintenance_status_em_analise => 'In Analysis';

  @override
  String get maintenance_status_aguardando => 'Waiting';

  @override
  String get maintenance_status_rejeitado => 'Rejected';
}
