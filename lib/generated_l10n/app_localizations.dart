import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @common_cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get common_cancel;

  /// No description provided for @common_exit.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get common_exit;

  /// No description provided for @common_edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get common_edit;

  /// No description provided for @common_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get common_loading;

  /// No description provided for @common_back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get common_back;

  /// No description provided for @common_confirm_question.
  ///
  /// In pt, this message translates to:
  /// **'Deseja continuar?'**
  String get common_confirm_question;

  /// No description provided for @role_administrator.
  ///
  /// In pt, this message translates to:
  /// **'Administrador'**
  String get role_administrator;

  /// No description provided for @role_employee.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário'**
  String get role_employee;

  /// No description provided for @role_resident.
  ///
  /// In pt, this message translates to:
  /// **'Morador'**
  String get role_resident;

  /// No description provided for @role_syndic.
  ///
  /// In pt, this message translates to:
  /// **'Síndico'**
  String get role_syndic;

  /// No description provided for @role_doorman.
  ///
  /// In pt, this message translates to:
  /// **'Portaria'**
  String get role_doorman;

  /// No description provided for @role_visitor.
  ///
  /// In pt, this message translates to:
  /// **'Visitante'**
  String get role_visitor;

  /// No description provided for @login_app_name.
  ///
  /// In pt, this message translates to:
  /// **'Owany'**
  String get login_app_name;

  /// No description provided for @login_welcome.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo de volta!'**
  String get login_welcome;

  /// No description provided for @login_identifier_label.
  ///
  /// In pt, this message translates to:
  /// **'Telefone ou Usuário'**
  String get login_identifier_label;

  /// No description provided for @login_password_label.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get login_password_label;

  /// No description provided for @login_sign_in.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get login_sign_in;

  /// No description provided for @login_need_access.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de acesso? Contacte o administrador do sistema.'**
  String get login_need_access;

  /// No description provided for @login_forgot_password.
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu sua senha?'**
  String get login_forgot_password;

  /// No description provided for @login_required_field.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório'**
  String get login_required_field;

  /// No description provided for @login_error_connection.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar ao servidor'**
  String get login_error_connection;

  /// No description provided for @login_error_credentials.
  ///
  /// In pt, this message translates to:
  /// **'Usuário ou senha incorretos'**
  String get login_error_credentials;

  /// No description provided for @login_error_generic.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro. Tente novamente'**
  String get login_error_generic;

  /// No description provided for @login_processing.
  ///
  /// In pt, this message translates to:
  /// **'Processando...'**
  String get login_processing;

  /// No description provided for @login_language_pt.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get login_language_pt;

  /// No description provided for @login_language_en.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get login_language_en;

  /// No description provided for @settings_title.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings_title;

  /// No description provided for @settings_account_preferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências da Conta'**
  String get settings_account_preferences;

  /// No description provided for @settings_account_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerencie sua experiência e segurança'**
  String get settings_account_subtitle;

  /// No description provided for @settings_security.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get settings_security;

  /// No description provided for @settings_change_password.
  ///
  /// In pt, this message translates to:
  /// **'Alterar Senha'**
  String get settings_change_password;

  /// No description provided for @settings_change_password_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualize sua senha regularmente'**
  String get settings_change_password_subtitle;

  /// No description provided for @settings_notifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get settings_notifications;

  /// No description provided for @settings_notifications_push.
  ///
  /// In pt, this message translates to:
  /// **'Notificações Push'**
  String get settings_notifications_push;

  /// No description provided for @settings_notifications_push_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Alertas em tempo real'**
  String get settings_notifications_push_subtitle;

  /// No description provided for @settings_notifications_email.
  ///
  /// In pt, this message translates to:
  /// **'Notificações por Email'**
  String get settings_notifications_email;

  /// No description provided for @settings_notifications_email_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo semanal de atividades'**
  String get settings_notifications_email_subtitle;

  /// No description provided for @settings_notifications_sms.
  ///
  /// In pt, this message translates to:
  /// **'Notificações por SMS'**
  String get settings_notifications_sms;

  /// No description provided for @settings_notifications_sms_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Receber alertas via mensagem de texto'**
  String get settings_notifications_sms_subtitle;

  /// No description provided for @settings_sms_enabled.
  ///
  /// In pt, this message translates to:
  /// **'Notificações SMS ativadas'**
  String get settings_sms_enabled;

  /// No description provided for @settings_sms_disabled.
  ///
  /// In pt, this message translates to:
  /// **'Notificações SMS desativadas'**
  String get settings_sms_disabled;

  /// No description provided for @settings_sms_update_failed.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao atualizar preferência de SMS'**
  String get settings_sms_update_failed;

  /// No description provided for @settings_appearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get settings_appearance;

  /// No description provided for @settings_theme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get settings_theme;

  /// No description provided for @settings_language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settings_language;

  /// No description provided for @settings_language_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Português • English'**
  String get settings_language_subtitle;

  /// No description provided for @settings_about.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get settings_about;

  /// No description provided for @settings_about_description.
  ///
  /// In pt, this message translates to:
  /// **'Sistema moderno de gestão de edifícios para facilitar o gerenciamento de apartamentos, solicitações de manutenção e comunicação com residentes.'**
  String get settings_about_description;

  /// No description provided for @settings_logout.
  ///
  /// In pt, this message translates to:
  /// **'Sair da Conta'**
  String get settings_logout;

  /// No description provided for @settings_logout_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Saída'**
  String get settings_logout_confirm_title;

  /// No description provided for @settings_logout_confirm_body.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja sair da sua conta? Você precisará fazer login novamente.'**
  String get settings_logout_confirm_body;

  /// No description provided for @settings_language_apply_restart.
  ///
  /// In pt, this message translates to:
  /// **'Idioma será aplicado na próxima reinicialização'**
  String get settings_language_apply_restart;

  /// No description provided for @mp_details_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da Manutenção'**
  String get mp_details_title;

  /// No description provided for @mp_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção não encontrada'**
  String get mp_not_found;

  /// No description provided for @mp_status_overdue.
  ///
  /// In pt, this message translates to:
  /// **'Vencida'**
  String get mp_status_overdue;

  /// No description provided for @mp_status_alert.
  ///
  /// In pt, this message translates to:
  /// **'Em Alerta'**
  String get mp_status_alert;

  /// No description provided for @mp_status_active.
  ///
  /// In pt, this message translates to:
  /// **'Ativa'**
  String get mp_status_active;

  /// No description provided for @mp_info_general.
  ///
  /// In pt, this message translates to:
  /// **'Informações Gerais'**
  String get mp_info_general;

  /// No description provided for @mp_title.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get mp_title;

  /// No description provided for @mp_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get mp_type;

  /// No description provided for @mp_frequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência'**
  String get mp_frequency;

  /// No description provided for @mp_status.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get mp_status;

  /// No description provided for @mp_active.
  ///
  /// In pt, this message translates to:
  /// **'Ativa'**
  String get mp_active;

  /// No description provided for @mp_inactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativa'**
  String get mp_inactive;

  /// No description provided for @mp_schedule.
  ///
  /// In pt, this message translates to:
  /// **'Cronograma'**
  String get mp_schedule;

  /// No description provided for @mp_next_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Próxima Manutenção'**
  String get mp_next_maintenance;

  /// No description provided for @mp_last_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Última Manutenção'**
  String get mp_last_maintenance;

  /// No description provided for @mp_never_executed.
  ///
  /// In pt, this message translates to:
  /// **'Nunca executada'**
  String get mp_never_executed;

  /// No description provided for @mp_total_executions.
  ///
  /// In pt, this message translates to:
  /// **'Total de Execuções'**
  String get mp_total_executions;

  /// No description provided for @mp_costs_supplier.
  ///
  /// In pt, this message translates to:
  /// **'Custos e Fornecedor'**
  String get mp_costs_supplier;

  /// No description provided for @mp_estimated_cost.
  ///
  /// In pt, this message translates to:
  /// **'Custo Estimado'**
  String get mp_estimated_cost;

  /// No description provided for @mp_supplier.
  ///
  /// In pt, this message translates to:
  /// **'Fornecedor'**
  String get mp_supplier;

  /// No description provided for @mp_phone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get mp_phone;

  /// No description provided for @mp_responsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get mp_responsible;

  /// No description provided for @mp_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get mp_name;

  /// No description provided for @mp_not_assigned.
  ///
  /// In pt, this message translates to:
  /// **'Não atribuído'**
  String get mp_not_assigned;

  /// No description provided for @mp_created_by.
  ///
  /// In pt, this message translates to:
  /// **'Criado por'**
  String get mp_created_by;

  /// No description provided for @mp_last_update.
  ///
  /// In pt, this message translates to:
  /// **'Última atualização'**
  String get mp_last_update;

  /// No description provided for @mp_description.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get mp_description;

  /// No description provided for @mp_notes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get mp_notes;

  /// No description provided for @mp_edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get mp_edit;

  /// No description provided for @mp_conclude.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get mp_conclude;

  /// No description provided for @mp_history_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma execução registrada'**
  String get mp_history_empty;

  /// No description provided for @mp_last_executions.
  ///
  /// In pt, this message translates to:
  /// **'Últimas Execuções'**
  String get mp_last_executions;

  /// No description provided for @mp_last_execution.
  ///
  /// In pt, this message translates to:
  /// **'Última Execução'**
  String get mp_last_execution;

  /// No description provided for @mp_next_execution.
  ///
  /// In pt, this message translates to:
  /// **'Próxima Execução'**
  String get mp_next_execution;

  /// No description provided for @mp_total_times.
  ///
  /// In pt, this message translates to:
  /// **'vezes'**
  String get mp_total_times;

  /// No description provided for @mp_conclude_execution.
  ///
  /// In pt, this message translates to:
  /// **'Concluir Execução'**
  String get mp_conclude_execution;

  /// No description provided for @mp_detailed_history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico Detalhado'**
  String get mp_detailed_history;

  /// No description provided for @mp_conclude_title.
  ///
  /// In pt, this message translates to:
  /// **'Concluir execução'**
  String get mp_conclude_title;

  /// No description provided for @mp_done_what.
  ///
  /// In pt, this message translates to:
  /// **'O que foi feito?'**
  String get mp_done_what;

  /// No description provided for @mp_done_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Troca de peça e testes finais'**
  String get mp_done_hint;

  /// No description provided for @mp_additional_comments.
  ///
  /// In pt, this message translates to:
  /// **'Comentários adicionais'**
  String get mp_additional_comments;

  /// No description provided for @mp_comments_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Necessário acompanhamento próximas 2 semanas'**
  String get mp_comments_hint;

  /// No description provided for @mp_real_cost_optional.
  ///
  /// In pt, this message translates to:
  /// **'Custo real (opcional)'**
  String get mp_real_cost_optional;

  /// No description provided for @mp_execution_saved.
  ///
  /// In pt, this message translates to:
  /// **'Execução registrada com sucesso'**
  String get mp_execution_saved;

  /// No description provided for @mp_execution_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao registrar execução'**
  String get mp_execution_error;

  /// No description provided for @mp_alerts_title.
  ///
  /// In pt, this message translates to:
  /// **'Alertas de Manutenção'**
  String get mp_alerts_title;

  /// No description provided for @mp_alerts_overdue.
  ///
  /// In pt, this message translates to:
  /// **'Vencidas'**
  String get mp_alerts_overdue;

  /// No description provided for @mp_alerts_overdue_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Vencidas e aguardando ação'**
  String get mp_alerts_overdue_subtitle;

  /// No description provided for @mp_alerts_in_alert.
  ///
  /// In pt, this message translates to:
  /// **'Em Alerta'**
  String get mp_alerts_in_alert;

  /// No description provided for @mp_alerts_in_alert_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Próximo vencimento crítico'**
  String get mp_alerts_in_alert_subtitle;

  /// No description provided for @mp_alerts_upcoming.
  ///
  /// In pt, this message translates to:
  /// **'Próximas'**
  String get mp_alerts_upcoming;

  /// No description provided for @mp_alerts_upcoming_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento em até 30 dias'**
  String get mp_alerts_upcoming_subtitle;

  /// No description provided for @mp_alerts_planned.
  ///
  /// In pt, this message translates to:
  /// **'Planejadas'**
  String get mp_alerts_planned;

  /// No description provided for @mp_alerts_planned_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Planejadas normalmente'**
  String get mp_alerts_planned_subtitle;

  /// No description provided for @mp_alerts_alerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get mp_alerts_alerts;

  /// No description provided for @mp_alerts_none_registered.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma manutenção cadastrada'**
  String get mp_alerts_none_registered;

  /// No description provided for @mp_alerts_none_overdue.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma manutenção vencida'**
  String get mp_alerts_none_overdue;

  /// No description provided for @mp_alerts_none_in_alert.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma manutenção em alerta'**
  String get mp_alerts_none_in_alert;

  /// No description provided for @mp_alerts_none_upcoming.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma manutenção próxima'**
  String get mp_alerts_none_upcoming;

  /// No description provided for @mp_alerts_general_condo.
  ///
  /// In pt, this message translates to:
  /// **'GERAL/CONDOMÍNIO'**
  String get mp_alerts_general_condo;

  /// No description provided for @mp_alerts_apartment.
  ///
  /// In pt, this message translates to:
  /// **'APARTAMENTO'**
  String get mp_alerts_apartment;

  /// No description provided for @mp_alerts_next.
  ///
  /// In pt, this message translates to:
  /// **'Próxima'**
  String get mp_alerts_next;

  /// No description provided for @mp_alerts_cost.
  ///
  /// In pt, this message translates to:
  /// **'Custo'**
  String get mp_alerts_cost;

  /// No description provided for @mp_alerts_hero_title.
  ///
  /// In pt, this message translates to:
  /// **'Manutenções Preventivas'**
  String get mp_alerts_hero_title;

  /// No description provided for @mp_alerts_hero_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Monitoramento contínuo dos ativos'**
  String get mp_alerts_hero_subtitle;

  /// No description provided for @mp_alerts_assets_label.
  ///
  /// In pt, this message translates to:
  /// **'ativos'**
  String get mp_alerts_assets_label;

  /// No description provided for @mp_alerts_overdue_suffix.
  ///
  /// In pt, this message translates to:
  /// **'atraso'**
  String get mp_alerts_overdue_suffix;

  /// No description provided for @mp_alerts_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando manutenções...'**
  String get mp_alerts_loading;

  /// No description provided for @mp_alerts_urgent_items.
  ///
  /// In pt, this message translates to:
  /// **'{count} item(s) necessitam atenção imediata'**
  String mp_alerts_urgent_items(int count);

  /// No description provided for @mp_list_title.
  ///
  /// In pt, this message translates to:
  /// **'Manutenções Preventivas'**
  String get mp_list_title;

  /// No description provided for @mp_list_filters.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get mp_list_filters;

  /// No description provided for @mp_list_filter_status_title.
  ///
  /// In pt, this message translates to:
  /// **'Por Status'**
  String get mp_list_filter_status_title;

  /// No description provided for @mp_list_filter_location_title.
  ///
  /// In pt, this message translates to:
  /// **'Por Local'**
  String get mp_list_filter_location_title;

  /// No description provided for @mp_list_filter_all.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get mp_list_filter_all;

  /// No description provided for @mp_list_filter_general.
  ///
  /// In pt, this message translates to:
  /// **'🏢 Geral/Condomínio'**
  String get mp_list_filter_general;

  /// No description provided for @mp_list_filter_apartment.
  ///
  /// In pt, this message translates to:
  /// **'🏠 Apartamento'**
  String get mp_list_filter_apartment;

  /// No description provided for @mp_list_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar manutenção...'**
  String get mp_list_search_hint;

  /// No description provided for @mp_list_status_active.
  ///
  /// In pt, this message translates to:
  /// **'Ativas'**
  String get mp_list_status_active;

  /// No description provided for @mp_list_status_alert.
  ///
  /// In pt, this message translates to:
  /// **'Com Alerta'**
  String get mp_list_status_alert;

  /// No description provided for @mp_list_status_overdue.
  ///
  /// In pt, this message translates to:
  /// **'Vencidas'**
  String get mp_list_status_overdue;

  /// No description provided for @mp_list_total.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get mp_list_total;

  /// No description provided for @mp_list_summary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get mp_list_summary;

  /// No description provided for @mp_list_general_title.
  ///
  /// In pt, this message translates to:
  /// **'🏢 MANUTENÇÕES GERAIS/CONDOMÍNIO'**
  String get mp_list_general_title;

  /// No description provided for @mp_list_general_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Afetam todo o prédio'**
  String get mp_list_general_subtitle;

  /// No description provided for @mp_list_apartment_title.
  ///
  /// In pt, this message translates to:
  /// **'🏠 MANUTENÇÕES DE APARTAMENTOS'**
  String get mp_list_apartment_title;

  /// No description provided for @mp_list_apartment_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Específicas de unidades'**
  String get mp_list_apartment_subtitle;

  /// No description provided for @mp_list_status_badge_overdue.
  ///
  /// In pt, this message translates to:
  /// **'VENCIDA'**
  String get mp_list_status_badge_overdue;

  /// No description provided for @mp_list_status_badge_alert.
  ///
  /// In pt, this message translates to:
  /// **'ALERTA'**
  String get mp_list_status_badge_alert;

  /// No description provided for @mp_list_status_badge_active.
  ///
  /// In pt, this message translates to:
  /// **'ATIVA'**
  String get mp_list_status_badge_active;

  /// No description provided for @mp_list_type_general_badge.
  ///
  /// In pt, this message translates to:
  /// **'GERAL'**
  String get mp_list_type_general_badge;

  /// No description provided for @mp_list_type_apartment_badge.
  ///
  /// In pt, this message translates to:
  /// **'APARTAMENTO'**
  String get mp_list_type_apartment_badge;

  /// No description provided for @mp_list_location_condo.
  ///
  /// In pt, this message translates to:
  /// **'Condomínio'**
  String get mp_list_location_condo;

  /// No description provided for @mp_list_location_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento'**
  String get mp_list_location_apartment;

  /// No description provided for @mp_list_type_label.
  ///
  /// In pt, this message translates to:
  /// **'Tipo:'**
  String get mp_list_type_label;

  /// No description provided for @mp_list_frequency_label.
  ///
  /// In pt, this message translates to:
  /// **'Frequência:'**
  String get mp_list_frequency_label;

  /// No description provided for @mp_list_responsible_label.
  ///
  /// In pt, this message translates to:
  /// **'Responsável:'**
  String get mp_list_responsible_label;

  /// No description provided for @mp_list_next_in.
  ///
  /// In pt, this message translates to:
  /// **'Próximo em'**
  String get mp_list_next_in;

  /// No description provided for @mp_list_estimated_cost.
  ///
  /// In pt, this message translates to:
  /// **'Custo Estimado'**
  String get mp_list_estimated_cost;

  /// No description provided for @mp_list_conclude_execution.
  ///
  /// In pt, this message translates to:
  /// **'Concluir Execução'**
  String get mp_list_conclude_execution;

  /// No description provided for @mp_list_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Concluir execução'**
  String get mp_list_dialog_title;

  /// No description provided for @mp_list_dialog_description_label.
  ///
  /// In pt, this message translates to:
  /// **'Descreva o que foi feito (opcional)'**
  String get mp_list_dialog_description_label;

  /// No description provided for @mp_list_dialog_description_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Troca de peça e testes finais'**
  String get mp_list_dialog_description_hint;

  /// No description provided for @mp_list_dialog_cost_label.
  ///
  /// In pt, this message translates to:
  /// **'Custo real (opcional)'**
  String get mp_list_dialog_cost_label;

  /// No description provided for @mp_list_dialog_cost_hint.
  ///
  /// In pt, this message translates to:
  /// **'0,00'**
  String get mp_list_dialog_cost_hint;

  /// No description provided for @mp_list_dialog_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get mp_list_dialog_confirm;

  /// No description provided for @mp_list_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma manutenção encontrada'**
  String get mp_list_empty_title;

  /// No description provided for @mp_list_empty_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste os filtros para ver resultados'**
  String get mp_list_empty_subtitle;

  /// No description provided for @mp_list_days_late_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Atrasado'**
  String get mp_list_days_late_prefix;

  /// No description provided for @mp_list_days_today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get mp_list_days_today;

  /// No description provided for @mp_list_days_tomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get mp_list_days_tomorrow;

  /// No description provided for @mp_list_days_in_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Em'**
  String get mp_list_days_in_prefix;

  /// No description provided for @mp_list_days_suffix.
  ///
  /// In pt, this message translates to:
  /// **'dias'**
  String get mp_list_days_suffix;

  /// No description provided for @manage_items_title.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar Itens'**
  String get manage_items_title;

  /// No description provided for @manage_items_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicione itens de patrimônio aos apartamentos'**
  String get manage_items_subtitle;

  /// No description provided for @apartment.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento'**
  String get apartment;

  /// No description provided for @select_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um apartamento...'**
  String get select_apartment;

  /// No description provided for @item_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Item'**
  String get item_name;

  /// No description provided for @description_optional.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get description_optional;

  /// No description provided for @save_item.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Item'**
  String get save_item;

  /// No description provided for @required_field.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório'**
  String get required_field;

  /// No description provided for @item_success.
  ///
  /// In pt, this message translates to:
  /// **'Item adicionado com sucesso!'**
  String get item_success;

  /// No description provided for @item_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar item'**
  String get item_error;

  /// No description provided for @loading_apartments.
  ///
  /// In pt, this message translates to:
  /// **'Carregando apartamentos...'**
  String get loading_apartments;

  /// No description provided for @no_apartments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum apartamento disponível'**
  String get no_apartments;

  /// No description provided for @link_apartment_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Vincule um usuário a um apartamento'**
  String get link_apartment_subtitle;

  /// No description provided for @link_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Vincular Apartamento'**
  String get link_apartment;

  /// No description provided for @link_success.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento vinculado com sucesso!'**
  String get link_success;

  /// No description provided for @link_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao vincular apartamento'**
  String get link_error;

  /// No description provided for @user.
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get user;

  /// No description provided for @register_create_account.
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get register_create_account;

  /// No description provided for @register_fill_data.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os dados abaixo para registrar'**
  String get register_fill_data;

  /// No description provided for @register_full_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get register_full_name;

  /// No description provided for @register_username.
  ///
  /// In pt, this message translates to:
  /// **'Nome de Usuário'**
  String get register_username;

  /// No description provided for @register_phone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get register_phone;

  /// No description provided for @register_password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get register_password;

  /// No description provided for @register_confirm_password.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Senha'**
  String get register_confirm_password;

  /// No description provided for @register_accept_terms.
  ///
  /// In pt, this message translates to:
  /// **'Você deve aceitar os termos de serviço'**
  String get register_accept_terms;

  /// No description provided for @register_success.
  ///
  /// In pt, this message translates to:
  /// **'Registro realizado com sucesso!'**
  String get register_success;

  /// No description provided for @register_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao registrar'**
  String get register_error;

  /// No description provided for @register_name_required.
  ///
  /// In pt, this message translates to:
  /// **'Nome é obrigatório'**
  String get register_name_required;

  /// No description provided for @register_name_min_length.
  ///
  /// In pt, this message translates to:
  /// **'Nome deve ter pelo menos 3 caracteres'**
  String get register_name_min_length;

  /// No description provided for @register_button.
  ///
  /// In pt, this message translates to:
  /// **'Registrar'**
  String get register_button;

  /// No description provided for @register_already_have_account.
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta?'**
  String get register_already_have_account;

  /// No description provided for @register_login_link.
  ///
  /// In pt, this message translates to:
  /// **'Faça login aqui'**
  String get register_login_link;

  /// No description provided for @forgot_password_title.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar Senha'**
  String get forgot_password_title;

  /// No description provided for @forgot_password_step1_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome de Usuário ou Telefone'**
  String get forgot_password_step1_label;

  /// No description provided for @forgot_password_step1_button.
  ///
  /// In pt, this message translates to:
  /// **'Solicitar Código'**
  String get forgot_password_step1_button;

  /// No description provided for @forgot_password_step2_title.
  ///
  /// In pt, this message translates to:
  /// **'Verificação de Código'**
  String get forgot_password_step2_title;

  /// No description provided for @forgot_password_step2_label.
  ///
  /// In pt, this message translates to:
  /// **'Código de Verificação'**
  String get forgot_password_step2_label;

  /// No description provided for @forgot_password_step2_button.
  ///
  /// In pt, this message translates to:
  /// **'Verificar Código'**
  String get forgot_password_step2_button;

  /// No description provided for @forgot_password_step3_title.
  ///
  /// In pt, this message translates to:
  /// **'Nova Senha'**
  String get forgot_password_step3_title;

  /// No description provided for @forgot_password_step3_password.
  ///
  /// In pt, this message translates to:
  /// **'Nova Senha'**
  String get forgot_password_step3_password;

  /// No description provided for @forgot_password_step3_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Senha'**
  String get forgot_password_step3_confirm;

  /// No description provided for @forgot_password_step3_button.
  ///
  /// In pt, this message translates to:
  /// **'Alterar Senha'**
  String get forgot_password_step3_button;

  /// No description provided for @forgot_password_resend.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar em {seconds}s'**
  String forgot_password_resend(int seconds);

  /// No description provided for @forgot_password_sms_sent.
  ///
  /// In pt, this message translates to:
  /// **'SMS enviado'**
  String get forgot_password_sms_sent;

  /// No description provided for @forgot_password_error_invalid_login.
  ///
  /// In pt, this message translates to:
  /// **'Digite um nome de login válido'**
  String get forgot_password_error_invalid_login;

  /// No description provided for @forgot_password_login_required.
  ///
  /// In pt, this message translates to:
  /// **'Nome de login é obrigatório'**
  String get forgot_password_login_required;

  /// No description provided for @forgot_password_login_too_short.
  ///
  /// In pt, this message translates to:
  /// **'Nome de login muito curto'**
  String get forgot_password_login_too_short;

  /// No description provided for @forgot_password_passwords_dont_match.
  ///
  /// In pt, this message translates to:
  /// **'Senhas não correspondem'**
  String get forgot_password_passwords_dont_match;

  /// No description provided for @forgot_password_success.
  ///
  /// In pt, this message translates to:
  /// **'Senha redefinida com sucesso!'**
  String get forgot_password_success;

  /// No description provided for @forgot_password_step_verification.
  ///
  /// In pt, this message translates to:
  /// **'Verificação'**
  String get forgot_password_step_verification;

  /// No description provided for @forgot_password_step_code.
  ///
  /// In pt, this message translates to:
  /// **'Código'**
  String get forgot_password_step_code;

  /// No description provided for @forgot_password_step_new_password.
  ///
  /// In pt, this message translates to:
  /// **'Nova Senha'**
  String get forgot_password_step_new_password;

  /// No description provided for @forgot_password_step1_heading.
  ///
  /// In pt, this message translates to:
  /// **'Etapa 1: Verificação'**
  String get forgot_password_step1_heading;

  /// No description provided for @forgot_password_step1_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu nome de login para receber um código por SMS'**
  String get forgot_password_step1_subtitle;

  /// No description provided for @forgot_password_login_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome de Login'**
  String get forgot_password_login_label;

  /// No description provided for @forgot_password_login_hint.
  ///
  /// In pt, this message translates to:
  /// **'joao.silva'**
  String get forgot_password_login_hint;

  /// No description provided for @forgot_password_login_helper.
  ///
  /// In pt, this message translates to:
  /// **'Use o mesmo nome de login do cadastro'**
  String get forgot_password_login_helper;

  /// No description provided for @forgot_password_sms_will_be_sent.
  ///
  /// In pt, this message translates to:
  /// **'SMS será enviado para o telefone cadastrado'**
  String get forgot_password_sms_will_be_sent;

  /// No description provided for @forgot_password_step2_heading.
  ///
  /// In pt, this message translates to:
  /// **'Etapa 2: Código OTP'**
  String get forgot_password_step2_heading;

  /// No description provided for @forgot_password_step2_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Digite o código que você recebeu por SMS'**
  String get forgot_password_step2_subtitle;

  /// No description provided for @forgot_password_phone_label.
  ///
  /// In pt, this message translates to:
  /// **'Telefone: {phone}'**
  String forgot_password_phone_label(String phone);

  /// No description provided for @forgot_password_otp_label.
  ///
  /// In pt, this message translates to:
  /// **'Código OTP (6 dígitos)'**
  String get forgot_password_otp_label;

  /// No description provided for @forgot_password_resend_in.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar em {seconds} s'**
  String forgot_password_resend_in(int seconds);

  /// No description provided for @forgot_password_resend_button.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar Código'**
  String get forgot_password_resend_button;

  /// No description provided for @forgot_password_step3_heading.
  ///
  /// In pt, this message translates to:
  /// **'Etapa 3: Nova Senha'**
  String get forgot_password_step3_heading;

  /// No description provided for @forgot_password_step3_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Defina sua nova senha'**
  String get forgot_password_step3_subtitle;

  /// No description provided for @forgot_password_reset_button.
  ///
  /// In pt, this message translates to:
  /// **'Resetar Senha'**
  String get forgot_password_reset_button;

  /// No description provided for @forgot_password_sms_sent_to.
  ///
  /// In pt, this message translates to:
  /// **'SMS enviado {destination}. Você receberá em breve com seu nome.'**
  String forgot_password_sms_sent_to(String destination);

  /// No description provided for @forgot_password_to_registered_phone.
  ///
  /// In pt, this message translates to:
  /// **'para o telefone cadastrado'**
  String get forgot_password_to_registered_phone;

  /// No description provided for @common_next.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get common_next;

  /// No description provided for @nav_home.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get nav_home;

  /// No description provided for @nav_services.
  ///
  /// In pt, this message translates to:
  /// **'Serviços'**
  String get nav_services;

  /// No description provided for @nav_properties.
  ///
  /// In pt, this message translates to:
  /// **'Imóveis'**
  String get nav_properties;

  /// No description provided for @nav_profile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get nav_profile;

  /// No description provided for @drawer_main.
  ///
  /// In pt, this message translates to:
  /// **'Principal'**
  String get drawer_main;

  /// No description provided for @drawer_administration.
  ///
  /// In pt, this message translates to:
  /// **'Administração'**
  String get drawer_administration;

  /// No description provided for @drawer_resident_management.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Moradores'**
  String get drawer_resident_management;

  /// No description provided for @drawer_account.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get drawer_account;

  /// No description provided for @drawer_new.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get drawer_new;

  /// No description provided for @drawer_logout.
  ///
  /// In pt, this message translates to:
  /// **'Sair da Conta'**
  String get drawer_logout;

  /// No description provided for @drawer_logout_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Saída'**
  String get drawer_logout_confirm_title;

  /// No description provided for @drawer_logout_confirm_body.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente sair da sua conta?'**
  String get drawer_logout_confirm_body;

  /// No description provided for @drawer_user_default.
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get drawer_user_default;

  /// No description provided for @drawer_resident_default.
  ///
  /// In pt, this message translates to:
  /// **'Morador'**
  String get drawer_resident_default;

  /// No description provided for @drawer_asset_management.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Ativos'**
  String get drawer_asset_management;

  /// No description provided for @drawer_request_types.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de Solicitação'**
  String get drawer_request_types;

  /// No description provided for @fab_add.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get fab_add;

  /// No description provided for @fab_apartment_maintenance_title.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção Apartamento'**
  String get fab_apartment_maintenance_title;

  /// No description provided for @fab_apartment_maintenance_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Agendar manutenção em um apartamento'**
  String get fab_apartment_maintenance_subtitle;

  /// No description provided for @fab_preventive_maintenance_title.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção Preventiva'**
  String get fab_preventive_maintenance_title;

  /// No description provided for @fab_preventive_maintenance_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Agendar manutenção preventiva'**
  String get fab_preventive_maintenance_subtitle;

  /// No description provided for @fab_new_request.
  ///
  /// In pt, this message translates to:
  /// **'Nova Solicitação'**
  String get fab_new_request;

  /// No description provided for @fab_new_request_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Reportar um problema'**
  String get fab_new_request_subtitle;

  /// No description provided for @fab_new_user.
  ///
  /// In pt, this message translates to:
  /// **'Novo Usuário'**
  String get fab_new_user;

  /// No description provided for @fab_new_user_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Convidar pessoa'**
  String get fab_new_user_subtitle;

  /// No description provided for @fab_new_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Novo Apartamento'**
  String get fab_new_apartment;

  /// No description provided for @fab_new_apartment_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar unidade'**
  String get fab_new_apartment_subtitle;

  /// No description provided for @fab_general_announcement.
  ///
  /// In pt, this message translates to:
  /// **'Comunicado Geral'**
  String get fab_general_announcement;

  /// No description provided for @fab_general_announcement_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Enviar SMS em massa'**
  String get fab_general_announcement_subtitle;

  /// No description provided for @selector_select_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Apartamento'**
  String get selector_select_apartment;

  /// No description provided for @selector_no_apartments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum apartamento disponível'**
  String get selector_no_apartments;

  /// No description provided for @dashboard_title.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get dashboard_title;

  /// No description provided for @dashboard_welcome.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo'**
  String get dashboard_welcome;

  /// No description provided for @dashboard_welcome_back.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo de volta!'**
  String get dashboard_welcome_back;

  /// No description provided for @dashboard_system_summary.
  ///
  /// In pt, this message translates to:
  /// **'Aqui está o resumo do sistema'**
  String get dashboard_system_summary;

  /// No description provided for @dashboard_pending_count.
  ///
  /// In pt, this message translates to:
  /// **'pendentes'**
  String get dashboard_pending_count;

  /// No description provided for @dashboard_statistics.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get dashboard_statistics;

  /// No description provided for @dashboard_main_stats.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas Principais'**
  String get dashboard_main_stats;

  /// No description provided for @dashboard_view_all.
  ///
  /// In pt, this message translates to:
  /// **'Ver tudo'**
  String get dashboard_view_all;

  /// No description provided for @dashboard_recent_activity.
  ///
  /// In pt, this message translates to:
  /// **'Atividade Recente'**
  String get dashboard_recent_activity;

  /// No description provided for @dashboard_no_activity.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma atividade recente'**
  String get dashboard_no_activity;

  /// No description provided for @dashboard_system_updating.
  ///
  /// In pt, this message translates to:
  /// **'Sistema em Atualização'**
  String get dashboard_system_updating;

  /// No description provided for @dashboard_requests_not_available.
  ///
  /// In pt, this message translates to:
  /// **'Solicitações v2 ainda não disponíveis no servidor. Métricas podem estar desatualizadas.'**
  String get dashboard_requests_not_available;

  /// No description provided for @dashboard_error_loading_apartments.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao Carregar Apartamentos'**
  String get dashboard_error_loading_apartments;

  /// No description provided for @dashboard_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manutenções'**
  String get dashboard_maintenance;

  /// No description provided for @dashboard_open_count.
  ///
  /// In pt, this message translates to:
  /// **'abertas'**
  String get dashboard_open_count;

  /// No description provided for @dashboard_all_completed.
  ///
  /// In pt, this message translates to:
  /// **'Todas concluídas'**
  String get dashboard_all_completed;

  /// No description provided for @dashboard_total_condo.
  ///
  /// In pt, this message translates to:
  /// **'Total do condomínio'**
  String get dashboard_total_condo;

  /// No description provided for @dashboard_status_requests.
  ///
  /// In pt, this message translates to:
  /// **'Status das Solicitações'**
  String get dashboard_status_requests;

  /// No description provided for @dashboard_quick_actions.
  ///
  /// In pt, this message translates to:
  /// **'Ações Rápidas'**
  String get dashboard_quick_actions;

  /// No description provided for @dashboard_new_request.
  ///
  /// In pt, this message translates to:
  /// **'Nova Solicitação'**
  String get dashboard_new_request;

  /// No description provided for @dashboard_date_unknown.
  ///
  /// In pt, this message translates to:
  /// **'Data desconhecida'**
  String get dashboard_date_unknown;

  /// No description provided for @dashboard_date_now.
  ///
  /// In pt, this message translates to:
  /// **'Agora mesmo'**
  String get dashboard_date_now;

  /// No description provided for @dashboard_date_minutes_ago.
  ///
  /// In pt, this message translates to:
  /// **'minutos atrás'**
  String get dashboard_date_minutes_ago;

  /// No description provided for @dashboard_date_hours_ago.
  ///
  /// In pt, this message translates to:
  /// **'horas atrás'**
  String get dashboard_date_hours_ago;

  /// No description provided for @dashboard_date_days_ago.
  ///
  /// In pt, this message translates to:
  /// **'dias atrás'**
  String get dashboard_date_days_ago;

  /// No description provided for @maintenance_list_title.
  ///
  /// In pt, this message translates to:
  /// **'Solicitações de Manutenção'**
  String get maintenance_list_title;

  /// No description provided for @maintenance_list_search.
  ///
  /// In pt, this message translates to:
  /// **'Buscar solicitação...'**
  String get maintenance_list_search;

  /// No description provided for @maintenance_list_pending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get maintenance_list_pending;

  /// No description provided for @maintenance_list_in_progress.
  ///
  /// In pt, this message translates to:
  /// **'Em Andamento'**
  String get maintenance_list_in_progress;

  /// No description provided for @maintenance_list_completed.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get maintenance_list_completed;

  /// No description provided for @maintenance_list_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma solicitação encontrada'**
  String get maintenance_list_empty;

  /// No description provided for @maintenance_detail_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da Solicitação'**
  String get maintenance_detail_title;

  /// No description provided for @maintenance_detail_description.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get maintenance_detail_description;

  /// No description provided for @maintenance_detail_status.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get maintenance_detail_status;

  /// No description provided for @maintenance_detail_created.
  ///
  /// In pt, this message translates to:
  /// **'Criado em'**
  String get maintenance_detail_created;

  /// Label indicating attachments are optional when creating a maintenance request
  ///
  /// In pt, this message translates to:
  /// **'Anexos (opcional)'**
  String get maintenance_request_attachments_optional;

  /// Button label to add an attachment to a maintenance request
  ///
  /// In pt, this message translates to:
  /// **'Adicionar anexo'**
  String get maintenance_request_add_attachment;

  /// Displayed when no files were selected for attachment
  ///
  /// In pt, this message translates to:
  /// **'Nenhum arquivo selecionado'**
  String get maintenance_request_no_files;

  /// Tooltip or action to remove a selected attachment
  ///
  /// In pt, this message translates to:
  /// **'Remover anexo'**
  String get maintenance_request_remove_attachment;

  /// No description provided for @apartments_list_title.
  ///
  /// In pt, this message translates to:
  /// **'Apartamentos'**
  String get apartments_list_title;

  /// No description provided for @apartments_list_available.
  ///
  /// In pt, this message translates to:
  /// **'Disponível'**
  String get apartments_list_available;

  /// No description provided for @apartments_list_occupied.
  ///
  /// In pt, this message translates to:
  /// **'Ocupado'**
  String get apartments_list_occupied;

  /// No description provided for @apartments_list_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get apartments_list_maintenance;

  /// No description provided for @apartments_inactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get apartments_inactive;

  /// No description provided for @apartments_list_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum apartamento encontrado'**
  String get apartments_list_empty;

  /// No description provided for @apartments_detail_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Apartamento'**
  String get apartments_detail_title;

  /// No description provided for @apartments_detail_residents.
  ///
  /// In pt, this message translates to:
  /// **'Moradores'**
  String get apartments_detail_residents;

  /// No description provided for @apartments_create_title.
  ///
  /// In pt, this message translates to:
  /// **'Novo Apartamento'**
  String get apartments_create_title;

  /// No description provided for @apartments_number.
  ///
  /// In pt, this message translates to:
  /// **'Número'**
  String get apartments_number;

  /// No description provided for @apartments_block.
  ///
  /// In pt, this message translates to:
  /// **'Bloco'**
  String get apartments_block;

  /// No description provided for @apartments_floor.
  ///
  /// In pt, this message translates to:
  /// **'Andar'**
  String get apartments_floor;

  /// No description provided for @schedule_list_title.
  ///
  /// In pt, this message translates to:
  /// **'Agendamentos'**
  String get schedule_list_title;

  /// No description provided for @schedule_detail_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Agendamento'**
  String get schedule_detail_title;

  /// No description provided for @schedule_create_title.
  ///
  /// In pt, this message translates to:
  /// **'Novo Agendamento'**
  String get schedule_create_title;

  /// No description provided for @schedule_date.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get schedule_date;

  /// No description provided for @schedule_time.
  ///
  /// In pt, this message translates to:
  /// **'Hora'**
  String get schedule_time;

  /// No description provided for @schedule_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum agendamento encontrado'**
  String get schedule_empty;

  /// No description provided for @users_list_title.
  ///
  /// In pt, this message translates to:
  /// **'Usuários'**
  String get users_list_title;

  /// No description provided for @users_add_title.
  ///
  /// In pt, this message translates to:
  /// **'Novo Usuário'**
  String get users_add_title;

  /// No description provided for @users_detail_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Usuário'**
  String get users_detail_title;

  /// No description provided for @users_role.
  ///
  /// In pt, this message translates to:
  /// **'Função'**
  String get users_role;

  /// No description provided for @users_active.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get users_active;

  /// No description provided for @users_inactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get users_inactive;

  /// No description provided for @profile_title.
  ///
  /// In pt, this message translates to:
  /// **'Meu Perfil'**
  String get profile_title;

  /// No description provided for @profile_edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get profile_edit;

  /// No description provided for @profile_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get profile_name;

  /// No description provided for @profile_email.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get profile_email;

  /// No description provided for @profile_phone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get profile_phone;

  /// No description provided for @notifications_title.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notifications_title;

  /// No description provided for @notifications_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma notificação'**
  String get notifications_empty;

  /// No description provided for @notifications_mark_read.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como lido'**
  String get notifications_mark_read;

  /// No description provided for @reports_title.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get reports_title;

  /// No description provided for @reports_generate.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Relatório'**
  String get reports_generate;

  /// No description provided for @reports_date_range.
  ///
  /// In pt, this message translates to:
  /// **'Período'**
  String get reports_date_range;

  /// No description provided for @action_save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get action_save;

  /// No description provided for @action_delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get action_delete;

  /// No description provided for @action_edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get action_edit;

  /// No description provided for @action_create.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get action_create;

  /// No description provided for @action_back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get action_back;

  /// No description provided for @action_yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get action_yes;

  /// No description provided for @action_no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get action_no;

  /// No description provided for @success_saved.
  ///
  /// In pt, this message translates to:
  /// **'Salvo com sucesso'**
  String get success_saved;

  /// No description provided for @success_deleted.
  ///
  /// In pt, this message translates to:
  /// **'Excluído com sucesso'**
  String get success_deleted;

  /// No description provided for @error_generic.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro'**
  String get error_generic;

  /// No description provided for @error_connection.
  ///
  /// In pt, this message translates to:
  /// **'Erro de conexão'**
  String get error_connection;

  /// No description provided for @error_timeout.
  ///
  /// In pt, this message translates to:
  /// **'Tempo limite excedido'**
  String get error_timeout;

  /// No description provided for @common_user.
  ///
  /// In pt, this message translates to:
  /// **'Usuário'**
  String get common_user;

  /// No description provided for @common_users.
  ///
  /// In pt, this message translates to:
  /// **'Usuários'**
  String get common_users;

  /// No description provided for @common_resident.
  ///
  /// In pt, this message translates to:
  /// **'Morador'**
  String get common_resident;

  /// No description provided for @common_residents.
  ///
  /// In pt, this message translates to:
  /// **'Moradores'**
  String get common_residents;

  /// No description provided for @common_employee.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário'**
  String get common_employee;

  /// No description provided for @common_administrator.
  ///
  /// In pt, this message translates to:
  /// **'Administrador'**
  String get common_administrator;

  /// No description provided for @common_manager.
  ///
  /// In pt, this message translates to:
  /// **'Síndico'**
  String get common_manager;

  /// No description provided for @common_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get common_name;

  /// No description provided for @common_phone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get common_phone;

  /// No description provided for @common_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get common_type;

  /// No description provided for @common_status.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get common_status;

  /// No description provided for @common_active.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get common_active;

  /// No description provided for @common_inactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get common_inactive;

  /// No description provided for @common_all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get common_all;

  /// No description provided for @common_search.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get common_search;

  /// No description provided for @common_filter.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar'**
  String get common_filter;

  /// No description provided for @common_no_data.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum dado disponível'**
  String get common_no_data;

  /// No description provided for @common_loading_apartments.
  ///
  /// In pt, this message translates to:
  /// **'Carregando apartamentos...'**
  String get common_loading_apartments;

  /// No description provided for @common_no_apartments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum apartamento disponível'**
  String get common_no_apartments;

  /// No description provided for @common_select_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um apartamento'**
  String get common_select_apartment;

  /// No description provided for @common_not_informed.
  ///
  /// In pt, this message translates to:
  /// **'Não informado'**
  String get common_not_informed;

  /// No description provided for @common_information.
  ///
  /// In pt, this message translates to:
  /// **'Informações'**
  String get common_information;

  /// No description provided for @common_details.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get common_details;

  /// No description provided for @common_actions.
  ///
  /// In pt, this message translates to:
  /// **'Ações'**
  String get common_actions;

  /// No description provided for @common_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get common_confirm;

  /// No description provided for @common_required_field.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório'**
  String get common_required_field;

  /// No description provided for @common_success.
  ///
  /// In pt, this message translates to:
  /// **'Sucesso'**
  String get common_success;

  /// No description provided for @common_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get common_error;

  /// No description provided for @common_warning.
  ///
  /// In pt, this message translates to:
  /// **'Aviso'**
  String get common_warning;

  /// No description provided for @common_minutes.
  ///
  /// In pt, this message translates to:
  /// **'minutos'**
  String get common_minutes;

  /// No description provided for @common_hours.
  ///
  /// In pt, this message translates to:
  /// **'horas'**
  String get common_hours;

  /// No description provided for @common_days.
  ///
  /// In pt, this message translates to:
  /// **'dias'**
  String get common_days;

  /// No description provided for @common_ago.
  ///
  /// In pt, this message translates to:
  /// **'atrás'**
  String get common_ago;

  /// No description provided for @common_in.
  ///
  /// In pt, this message translates to:
  /// **'em'**
  String get common_in;

  /// No description provided for @common_create_user.
  ///
  /// In pt, this message translates to:
  /// **'Criar Usuário'**
  String get common_create_user;

  /// No description provided for @common_new_user.
  ///
  /// In pt, this message translates to:
  /// **'Novo Usuário'**
  String get common_new_user;

  /// No description provided for @common_user_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Usuário'**
  String get common_user_type;

  /// No description provided for @common_user_created.
  ///
  /// In pt, this message translates to:
  /// **'Usuário criado com sucesso'**
  String get common_user_created;

  /// No description provided for @common_fill_user_data.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os dados do novo usuário'**
  String get common_fill_user_data;

  /// No description provided for @common_send_sms.
  ///
  /// In pt, this message translates to:
  /// **'Enviar SMS com credenciais'**
  String get common_send_sms;

  /// No description provided for @residents_directory.
  ///
  /// In pt, this message translates to:
  /// **'Diretório de Moradores'**
  String get residents_directory;

  /// No description provided for @residents_statistics.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get residents_statistics;

  /// No description provided for @residents_link_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Vincular Apartamento'**
  String get residents_link_apartment;

  /// No description provided for @profile_user_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Usuário não encontrado'**
  String get profile_user_not_found;

  /// No description provided for @profile_personal_info.
  ///
  /// In pt, this message translates to:
  /// **'INFORMAÇÕES PESSOAIS'**
  String get profile_personal_info;

  /// No description provided for @profile_full_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get profile_full_name;

  /// No description provided for @profile_login_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome de Login'**
  String get profile_login_name;

  /// No description provided for @profile_user_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Usuário'**
  String get profile_user_type;

  /// No description provided for @profile_active_in_system.
  ///
  /// In pt, this message translates to:
  /// **'Ativo no sistema'**
  String get profile_active_in_system;

  /// No description provided for @profile_help_support.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda e Suporte'**
  String get profile_help_support;

  /// No description provided for @profile_get_in_touch.
  ///
  /// In pt, this message translates to:
  /// **'Entre em contato'**
  String get profile_get_in_touch;

  /// No description provided for @profile_support_email.
  ///
  /// In pt, this message translates to:
  /// **'Suporte: suporte@owany.com'**
  String get profile_support_email;

  /// No description provided for @profile_sign_out.
  ///
  /// In pt, this message translates to:
  /// **'Sair da Conta'**
  String get profile_sign_out;

  /// No description provided for @profile_do_logout.
  ///
  /// In pt, this message translates to:
  /// **'Fazer logout'**
  String get profile_do_logout;

  /// No description provided for @profile_sign_out_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Sair da Conta?'**
  String get profile_sign_out_confirm;

  /// No description provided for @profile_disconnect_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja se desconectar?'**
  String get profile_disconnect_confirm;

  /// No description provided for @profile_type_admin.
  ///
  /// In pt, this message translates to:
  /// **'Administrador'**
  String get profile_type_admin;

  /// No description provided for @profile_type_employee.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário'**
  String get profile_type_employee;

  /// No description provided for @profile_type_manager.
  ///
  /// In pt, this message translates to:
  /// **'Síndico'**
  String get profile_type_manager;

  /// No description provided for @profile_type_doorman.
  ///
  /// In pt, this message translates to:
  /// **'Portaria'**
  String get profile_type_doorman;

  /// No description provided for @profile_type_resident.
  ///
  /// In pt, this message translates to:
  /// **'Morador'**
  String get profile_type_resident;

  /// No description provided for @profile_type_visitor.
  ///
  /// In pt, this message translates to:
  /// **'Visitante'**
  String get profile_type_visitor;

  /// No description provided for @notifications_unread.
  ///
  /// In pt, this message translates to:
  /// **'Não lidas'**
  String get notifications_unread;

  /// No description provided for @notifications_none_unread.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma notificação não lida'**
  String get notifications_none_unread;

  /// No description provided for @notifications_none.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma notificação'**
  String get notifications_none;

  /// No description provided for @notifications_removed.
  ///
  /// In pt, this message translates to:
  /// **'Notificação removida'**
  String get notifications_removed;

  /// No description provided for @notifications_error_mark.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao marcar notificação'**
  String get notifications_error_mark;

  /// No description provided for @notifications_error_remove.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover notificação'**
  String get notifications_error_remove;

  /// No description provided for @notifications_all_caught_up.
  ///
  /// In pt, this message translates to:
  /// **'Você está em dia com todas as notificações'**
  String get notifications_all_caught_up;

  /// No description provided for @history_title.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Solicitações'**
  String get history_title;

  /// No description provided for @history_no_records.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação registrada ainda'**
  String get history_no_records;

  /// No description provided for @history_records_count.
  ///
  /// In pt, this message translates to:
  /// **'movimentações registradas'**
  String get history_records_count;

  /// No description provided for @password_change.
  ///
  /// In pt, this message translates to:
  /// **'Alterar Senha'**
  String get password_change;

  /// No description provided for @password_min_chars.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get password_min_chars;

  /// No description provided for @password_no_match.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não correspondem'**
  String get password_no_match;

  /// No description provided for @reports_analytics.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios & Analytics'**
  String get reports_analytics;

  /// No description provided for @reports_loading_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar relatórios'**
  String get reports_loading_error;

  /// No description provided for @reports_requests_summary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo de Solicitações'**
  String get reports_requests_summary;

  /// No description provided for @reports_system_users.
  ///
  /// In pt, this message translates to:
  /// **'Usuários do Sistema'**
  String get reports_system_users;

  /// No description provided for @reports_alerts_notifications.
  ///
  /// In pt, this message translates to:
  /// **'Alertas & Notificações'**
  String get reports_alerts_notifications;

  /// No description provided for @reports_urgent_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção Urgente'**
  String get reports_urgent_maintenance;

  /// No description provided for @reports_high_occupancy.
  ///
  /// In pt, this message translates to:
  /// **'Ocupação Alta'**
  String get reports_high_occupancy;

  /// No description provided for @reports_occupancy.
  ///
  /// In pt, this message translates to:
  /// **'Ocupação'**
  String get reports_occupancy;

  /// No description provided for @reports_satisfaction.
  ///
  /// In pt, this message translates to:
  /// **'Satisfação'**
  String get reports_satisfaction;

  /// No description provided for @reports_building_summary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo do edifício'**
  String get reports_building_summary;

  /// No description provided for @reports_average_rating.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação média'**
  String get reports_average_rating;

  /// No description provided for @reports_available.
  ///
  /// In pt, this message translates to:
  /// **'Disponíveis'**
  String get reports_available;

  /// No description provided for @reports_party_room.
  ///
  /// In pt, this message translates to:
  /// **'Salão Festas'**
  String get reports_party_room;

  /// No description provided for @reports_no_data.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum dado disponível'**
  String get reports_no_data;

  /// No description provided for @reports_occupancy_rate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de Ocupação'**
  String get reports_occupancy_rate;

  /// No description provided for @reports_apartments_of_total.
  ///
  /// In pt, this message translates to:
  /// **'{occupied} de {total} apartamentos'**
  String reports_apartments_of_total(int occupied, int total);

  /// No description provided for @reports_header_summary.
  ///
  /// In pt, this message translates to:
  /// **'{requests} solicitações • {residents} moradores'**
  String reports_header_summary(int requests, int residents);

  /// No description provided for @agendamentos_title.
  ///
  /// In pt, this message translates to:
  /// **'Agendamentos'**
  String get agendamentos_title;

  /// No description provided for @agendamentos_general.
  ///
  /// In pt, this message translates to:
  /// **'Geral (Todos os Apartamentos)'**
  String get agendamentos_general;

  /// No description provided for @agendamentos_condo.
  ///
  /// In pt, this message translates to:
  /// **'Condomínio (Áreas Comuns)'**
  String get agendamentos_condo;

  /// No description provided for @agendamentos_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento'**
  String get agendamentos_apartment;

  /// No description provided for @notifications_no_unread.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma notificação não lida'**
  String get notifications_no_unread;

  /// No description provided for @common_system.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get common_system;

  /// No description provided for @time_now.
  ///
  /// In pt, this message translates to:
  /// **'Agora'**
  String get time_now;

  /// No description provided for @time_ago_minutes.
  ///
  /// In pt, this message translates to:
  /// **'Há {count}m'**
  String time_ago_minutes(int count);

  /// No description provided for @time_ago_hours.
  ///
  /// In pt, this message translates to:
  /// **'Há {count}h'**
  String time_ago_hours(int count);

  /// No description provided for @time_ago_days.
  ///
  /// In pt, this message translates to:
  /// **'Há {count}d'**
  String time_ago_days(int count);

  /// No description provided for @time_yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get time_yesterday;

  /// No description provided for @common_current.
  ///
  /// In pt, this message translates to:
  /// **'Atual'**
  String get common_current;

  /// No description provided for @common_internal.
  ///
  /// In pt, this message translates to:
  /// **'Interno'**
  String get common_internal;

  /// No description provided for @common_retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get common_retry;

  /// No description provided for @common_update.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get common_update;

  /// No description provided for @common_occupied.
  ///
  /// In pt, this message translates to:
  /// **'Ocupado'**
  String get common_occupied;

  /// No description provided for @common_total.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get common_total;

  /// No description provided for @common_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get common_maintenance;

  /// No description provided for @reports_common_areas.
  ///
  /// In pt, this message translates to:
  /// **'Áreas Comuns'**
  String get reports_common_areas;

  /// No description provided for @reports_common_areas_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Status e ocupação das áreas'**
  String get reports_common_areas_subtitle;

  /// No description provided for @reports_distribution_by_status.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição por status'**
  String get reports_distribution_by_status;

  /// No description provided for @reports_pool.
  ///
  /// In pt, this message translates to:
  /// **'Piscina'**
  String get reports_pool;

  /// No description provided for @reports_gym.
  ///
  /// In pt, this message translates to:
  /// **'Academia'**
  String get reports_gym;

  /// No description provided for @reports_playground.
  ///
  /// In pt, this message translates to:
  /// **'Playground'**
  String get reports_playground;

  /// No description provided for @reports_nps.
  ///
  /// In pt, this message translates to:
  /// **'NPS'**
  String get reports_nps;

  /// No description provided for @reports_excellent.
  ///
  /// In pt, this message translates to:
  /// **'Excelente'**
  String get reports_excellent;

  /// No description provided for @reports_general_average.
  ///
  /// In pt, this message translates to:
  /// **'Média Geral'**
  String get reports_general_average;

  /// No description provided for @priority_urgent.
  ///
  /// In pt, this message translates to:
  /// **'URGENTE'**
  String get priority_urgent;

  /// No description provided for @priority_high.
  ///
  /// In pt, this message translates to:
  /// **'ALTO'**
  String get priority_high;

  /// No description provided for @priority_medium.
  ///
  /// In pt, this message translates to:
  /// **'MÉDIA'**
  String get priority_medium;

  /// No description provided for @priority_low.
  ///
  /// In pt, this message translates to:
  /// **'BAIXA'**
  String get priority_low;

  /// No description provided for @status_pending_short.
  ///
  /// In pt, this message translates to:
  /// **'Pend.'**
  String get status_pending_short;

  /// No description provided for @status_in_progress_short.
  ///
  /// In pt, this message translates to:
  /// **'Andam.'**
  String get status_in_progress_short;

  /// No description provided for @status_completed_short.
  ///
  /// In pt, this message translates to:
  /// **'Concl.'**
  String get status_completed_short;

  /// No description provided for @apartments_clear_all.
  ///
  /// In pt, this message translates to:
  /// **'Limpar tudo'**
  String get apartments_clear_all;

  /// No description provided for @apartments_no_results.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum apartamento encontrado'**
  String get apartments_no_results;

  /// No description provided for @apartments_no_results_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste os filtros para ver resultados'**
  String get apartments_no_results_subtitle;

  /// No description provided for @apartments_complete_management.
  ///
  /// In pt, this message translates to:
  /// **'Gestão completa'**
  String get apartments_complete_management;

  /// No description provided for @apartments_total_residents.
  ///
  /// In pt, this message translates to:
  /// **'Total Moradores'**
  String get apartments_total_residents;

  /// No description provided for @apartments_avg_per_apt.
  ///
  /// In pt, this message translates to:
  /// **'Média/Apto'**
  String get apartments_avg_per_apt;

  /// No description provided for @apartments_see_less.
  ///
  /// In pt, this message translates to:
  /// **'Ver menos'**
  String get apartments_see_less;

  /// No description provided for @apartments_see_more_stats.
  ///
  /// In pt, this message translates to:
  /// **'Ver mais estatísticas'**
  String get apartments_see_more_stats;

  /// No description provided for @apartments_occupancy_rate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de Ocupação'**
  String get apartments_occupancy_rate;

  /// No description provided for @apartments_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar apartamentos...'**
  String get apartments_search_hint;

  /// No description provided for @apartments_advanced_filters.
  ///
  /// In pt, this message translates to:
  /// **'Filtros Avançados'**
  String get apartments_advanced_filters;

  /// No description provided for @apartments_clear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get apartments_clear;

  /// No description provided for @apartments_apply_filters.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar Filtros'**
  String get apartments_apply_filters;

  /// No description provided for @apartments_empty_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Comece adicionando o primeiro apartamento\ndo condomínio'**
  String get apartments_empty_subtitle;

  /// No description provided for @apartments_register.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar Apartamento'**
  String get apartments_register;

  /// No description provided for @apartments_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Ops! Algo deu errado'**
  String get apartments_error_title;

  /// No description provided for @apartments_data_updated.
  ///
  /// In pt, this message translates to:
  /// **'Dados atualizados'**
  String get apartments_data_updated;

  /// No description provided for @apartments_items.
  ///
  /// In pt, this message translates to:
  /// **'Itens'**
  String get apartments_items;

  /// No description provided for @apartments_detailed_info.
  ///
  /// In pt, this message translates to:
  /// **'Informações Detalhadas'**
  String get apartments_detailed_info;

  /// No description provided for @apartments_state.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get apartments_state;

  /// No description provided for @apartments_linked.
  ///
  /// In pt, this message translates to:
  /// **'Vinculado'**
  String get apartments_linked;

  /// No description provided for @apartments_swap.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get apartments_swap;

  /// No description provided for @apartments_register_exit.
  ///
  /// In pt, this message translates to:
  /// **'Registrar saída'**
  String get apartments_register_exit;

  /// No description provided for @apartments_make_available.
  ///
  /// In pt, this message translates to:
  /// **'Disponibilizar'**
  String get apartments_make_available;

  /// No description provided for @apartments_no_residents.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum morador'**
  String get apartments_no_residents;

  /// No description provided for @apartments_no_items.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item'**
  String get apartments_no_items;

  /// No description provided for @apartments_edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar Apartamento'**
  String get apartments_edit;

  /// No description provided for @apartments_mark_available.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como Disponível'**
  String get apartments_mark_available;

  /// No description provided for @apartments_mark_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Marcar em Manutenção'**
  String get apartments_mark_maintenance;

  /// No description provided for @apartments_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento não encontrado'**
  String get apartments_not_found;

  /// No description provided for @apartments_manage_items.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar Itens'**
  String get apartments_manage_items;

  /// No description provided for @apartments_add_or_remove.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ou remover'**
  String get apartments_add_or_remove;

  /// No description provided for @apartments_assign_resident.
  ///
  /// In pt, this message translates to:
  /// **'Atribuir Morador'**
  String get apartments_assign_resident;

  /// No description provided for @apartments_link_resident.
  ///
  /// In pt, this message translates to:
  /// **'Vincular residente'**
  String get apartments_link_resident;

  /// No description provided for @apartments_view_history.
  ///
  /// In pt, this message translates to:
  /// **'Ver Histórico'**
  String get apartments_view_history;

  /// No description provided for @apartments_entries_exits.
  ///
  /// In pt, this message translates to:
  /// **'Entradas e saídas'**
  String get apartments_entries_exits;

  /// No description provided for @apartments_in_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Em manutenção'**
  String get apartments_in_maintenance;

  /// No description provided for @apartments_available.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento disponível'**
  String get apartments_available;

  /// No description provided for @apartments_make_available_question.
  ///
  /// In pt, this message translates to:
  /// **'Disponibilizar morador?'**
  String get apartments_make_available_question;

  /// No description provided for @apartments_remove_resident_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover \"{name}\" deste apartamento?'**
  String apartments_remove_resident_confirm(String name);

  /// No description provided for @apartments_remove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get apartments_remove;

  /// No description provided for @apartments_resident_available_success.
  ///
  /// In pt, this message translates to:
  /// **'Morador disponibilizado com sucesso!'**
  String get apartments_resident_available_success;

  /// No description provided for @apartments_error_make_available.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao disponibilizar morador: {error}'**
  String apartments_error_make_available(String error);

  /// No description provided for @apartments_exit_invalid_resident.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registrar saída: morador inválido.'**
  String get apartments_exit_invalid_resident;

  /// No description provided for @apartments_confirm_exit.
  ///
  /// In pt, this message translates to:
  /// **'Confirme a saída de {name} do apartamento.'**
  String apartments_confirm_exit(String name);

  /// No description provided for @apartments_exit_reason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo da saída (opcional)'**
  String get apartments_exit_reason;

  /// No description provided for @apartments_exit_reason_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Mudança, Venda, etc.'**
  String get apartments_exit_reason_hint;

  /// No description provided for @apartments_confirm_exit_button.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Saída'**
  String get apartments_confirm_exit_button;

  /// No description provided for @apartments_exit_success.
  ///
  /// In pt, this message translates to:
  /// **'Saída registrada com sucesso'**
  String get apartments_exit_success;

  /// No description provided for @apartments_exit_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao registrar saída'**
  String get apartments_exit_error;

  /// No description provided for @apartments_details.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Apartamento'**
  String get apartments_details;

  /// No description provided for @apartments_fill_fields.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os campos para cadastrar um novo apartamento com as informações completas.'**
  String get apartments_fill_fields;

  /// No description provided for @apartments_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Apartamento'**
  String get apartments_name;

  /// No description provided for @apartments_name_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Apto 101'**
  String get apartments_name_hint;

  /// No description provided for @apartments_number_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 101'**
  String get apartments_number_hint;

  /// No description provided for @apartments_block_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Bloco A'**
  String get apartments_block_hint;

  /// No description provided for @apartments_floor_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 3'**
  String get apartments_floor_hint;

  /// No description provided for @apartments_state_hint.
  ///
  /// In pt, this message translates to:
  /// **'Estado do apartamento'**
  String get apartments_state_hint;

  /// No description provided for @apartments_valid_number.
  ///
  /// In pt, this message translates to:
  /// **'Informe um número válido'**
  String get apartments_valid_number;

  /// No description provided for @apartments_not_negative.
  ///
  /// In pt, this message translates to:
  /// **'Não pode ser negativo'**
  String get apartments_not_negative;

  /// No description provided for @apartments_rooms.
  ///
  /// In pt, this message translates to:
  /// **'Quartos'**
  String get apartments_rooms;

  /// No description provided for @apartments_rooms_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 2'**
  String get apartments_rooms_hint;

  /// No description provided for @apartments_notes.
  ///
  /// In pt, this message translates to:
  /// **'Observações (opcional)'**
  String get apartments_notes;

  /// No description provided for @apartments_notes_hint.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes adicionais ou observações'**
  String get apartments_notes_hint;

  /// No description provided for @apartments_create_button.
  ///
  /// In pt, this message translates to:
  /// **'Criar Apartamento'**
  String get apartments_create_button;

  /// No description provided for @apartments_created_success.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento criado com sucesso!'**
  String get apartments_created_success;

  /// No description provided for @apartments_premium_register.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro premium de apartamento'**
  String get apartments_premium_register;

  /// No description provided for @apartments_organize_blocks.
  ///
  /// In pt, this message translates to:
  /// **'Organize blocos, unidades e status com as cores oficiais da Owany.'**
  String get apartments_organize_blocks;

  /// No description provided for @apartments_block_label.
  ///
  /// In pt, this message translates to:
  /// **'Bloco {name}'**
  String apartments_block_label(String name);

  /// No description provided for @apartments_block_floor_label.
  ///
  /// In pt, this message translates to:
  /// **'Bloco {block} - Andar {floor}'**
  String apartments_block_floor_label(String block, int floor);

  /// No description provided for @apartments_apt_block_label.
  ///
  /// In pt, this message translates to:
  /// **'Apto {number} - {block}'**
  String apartments_apt_block_label(String number, String block);

  /// No description provided for @apartments_block_floor_display.
  ///
  /// In pt, this message translates to:
  /// **'Bloco {block} • {floor}º andar'**
  String apartments_block_floor_display(String block, int floor);

  /// No description provided for @apartments_history_title.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de {number}/{block}'**
  String apartments_history_title(String number, String block);

  /// No description provided for @users_title.
  ///
  /// In pt, this message translates to:
  /// **'Usuários'**
  String get users_title;

  /// No description provided for @users_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar usuário'**
  String get users_search_hint;

  /// No description provided for @users_search_placeholder.
  ///
  /// In pt, this message translates to:
  /// **'Digite o nome ou login'**
  String get users_search_placeholder;

  /// No description provided for @users_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum usuário'**
  String get users_empty_title;

  /// No description provided for @users_empty_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicione um novo usuário para começar'**
  String get users_empty_subtitle;

  /// No description provided for @users_no_results.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado'**
  String get users_no_results;

  /// No description provided for @users_no_results_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste sua busca e tente novamente'**
  String get users_no_results_subtitle;

  /// No description provided for @users_new.
  ///
  /// In pt, this message translates to:
  /// **'Novo Usuário'**
  String get users_new;

  /// No description provided for @users_reload.
  ///
  /// In pt, this message translates to:
  /// **'Recarregar'**
  String get users_reload;

  /// No description provided for @users_try_again.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get users_try_again;

  /// No description provided for @users_type_admin.
  ///
  /// In pt, this message translates to:
  /// **'Admin'**
  String get users_type_admin;

  /// No description provided for @users_type_employee.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário'**
  String get users_type_employee;

  /// No description provided for @users_type_manager.
  ///
  /// In pt, this message translates to:
  /// **'Síndico'**
  String get users_type_manager;

  /// No description provided for @users_type_doorman.
  ///
  /// In pt, this message translates to:
  /// **'Portaria'**
  String get users_type_doorman;

  /// No description provided for @users_type_resident.
  ///
  /// In pt, this message translates to:
  /// **'Morador'**
  String get users_type_resident;

  /// No description provided for @users_type_visitor.
  ///
  /// In pt, this message translates to:
  /// **'Visitante'**
  String get users_type_visitor;

  /// No description provided for @users_create_new.
  ///
  /// In pt, this message translates to:
  /// **'Criar Novo Usuário'**
  String get users_create_new;

  /// No description provided for @users_fill_data.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os dados do novo usuário'**
  String get users_fill_data;

  /// No description provided for @users_full_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get users_full_name;

  /// No description provided for @users_full_name_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: João Silva'**
  String get users_full_name_hint;

  /// No description provided for @users_login_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome de Login'**
  String get users_login_name;

  /// No description provided for @users_login_name_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: joaosilva'**
  String get users_login_name_hint;

  /// No description provided for @users_phone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get users_phone;

  /// No description provided for @users_phone_hint.
  ///
  /// In pt, this message translates to:
  /// **'9 dígitos (ex: 84 123 4567)'**
  String get users_phone_hint;

  /// No description provided for @users_phone_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe 9 dígitos'**
  String get users_phone_invalid;

  /// No description provided for @users_user_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Usuário'**
  String get users_user_type;

  /// No description provided for @users_send_sms_credentials.
  ///
  /// In pt, this message translates to:
  /// **'Enviar SMS com credenciais'**
  String get users_send_sms_credentials;

  /// No description provided for @users_sms_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Usuário receberá login e senha temporária por SMS'**
  String get users_sms_subtitle;

  /// No description provided for @users_security.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get users_security;

  /// No description provided for @users_password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get users_password;

  /// No description provided for @users_password_hint.
  ///
  /// In pt, this message translates to:
  /// **'Digite uma senha segura'**
  String get users_password_hint;

  /// No description provided for @users_confirm_password.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Senha'**
  String get users_confirm_password;

  /// No description provided for @users_confirm_password_hint.
  ///
  /// In pt, this message translates to:
  /// **'Confirme a senha'**
  String get users_confirm_password_hint;

  /// No description provided for @users_password_no_match.
  ///
  /// In pt, this message translates to:
  /// **'Senhas não correspondem'**
  String get users_password_no_match;

  /// No description provided for @users_min_chars.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get users_min_chars;

  /// No description provided for @users_create_button.
  ///
  /// In pt, this message translates to:
  /// **'Criar Usuário'**
  String get users_create_button;

  /// No description provided for @users_created_success.
  ///
  /// In pt, this message translates to:
  /// **'Utilizador criado com sucesso!'**
  String get users_created_success;

  /// No description provided for @users_credentials_sent.
  ///
  /// In pt, this message translates to:
  /// **'Credenciais foram enviadas por SMS para {phone}'**
  String users_credentials_sent(String phone);

  /// No description provided for @users_error_loading.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar usuário'**
  String get users_error_loading;

  /// No description provided for @users_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Usuário não encontrado'**
  String get users_not_found;

  /// No description provided for @users_information.
  ///
  /// In pt, this message translates to:
  /// **'Informações'**
  String get users_information;

  /// No description provided for @users_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get users_name;

  /// No description provided for @users_login.
  ///
  /// In pt, this message translates to:
  /// **'Login'**
  String get users_login;

  /// No description provided for @users_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get users_type;

  /// No description provided for @users_status.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get users_status;

  /// No description provided for @users_created_at.
  ///
  /// In pt, this message translates to:
  /// **'Criado em'**
  String get users_created_at;

  /// No description provided for @users_linked_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento Vinculado'**
  String get users_linked_apartment;

  /// No description provided for @users_residents.
  ///
  /// In pt, this message translates to:
  /// **'Moradores'**
  String get users_residents;

  /// No description provided for @users_state.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get users_state;

  /// No description provided for @users_deactivate.
  ///
  /// In pt, this message translates to:
  /// **'Desativar Usuário?'**
  String get users_deactivate;

  /// No description provided for @users_deactivate_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja desativar este usuário?'**
  String get users_deactivate_confirm;

  /// No description provided for @users_deactivate_button.
  ///
  /// In pt, this message translates to:
  /// **'Desativar'**
  String get users_deactivate_button;

  /// No description provided for @users_edit_title.
  ///
  /// In pt, this message translates to:
  /// **'Editar Usuário'**
  String get users_edit_title;

  /// No description provided for @users_update_data.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar dados do usuário'**
  String get users_update_data;

  /// No description provided for @users_update_info.
  ///
  /// In pt, this message translates to:
  /// **'Edite informações básicas. O tipo de usuário é somente leitura para segurança.'**
  String get users_update_info;

  /// No description provided for @users_data.
  ///
  /// In pt, this message translates to:
  /// **'Dados do usuário'**
  String get users_data;

  /// No description provided for @users_full_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get users_full_name_label;

  /// No description provided for @users_full_name_example.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Maria Souza'**
  String get users_full_name_example;

  /// No description provided for @users_phone_example.
  ///
  /// In pt, this message translates to:
  /// **'(11) 99999-9999'**
  String get users_phone_example;

  /// No description provided for @users_save_changes.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Alterações'**
  String get users_save_changes;

  /// No description provided for @users_saving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando...'**
  String get users_saving;

  /// No description provided for @users_updated_success.
  ///
  /// In pt, this message translates to:
  /// **'Usuário atualizado com sucesso!'**
  String get users_updated_success;

  /// No description provided for @users_actions.
  ///
  /// In pt, this message translates to:
  /// **'Ações do Usuário'**
  String get users_actions;

  /// No description provided for @users_reset_password.
  ///
  /// In pt, this message translates to:
  /// **'Reset de Senha'**
  String get users_reset_password;

  /// No description provided for @users_reset_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Resetar Senha?'**
  String get users_reset_confirm;

  /// No description provided for @users_reset_description.
  ///
  /// In pt, this message translates to:
  /// **'Um código de verificação será enviado por SMS para o telefone cadastrado do usuário. Confirmar?'**
  String get users_reset_description;

  /// No description provided for @users_reset_sent.
  ///
  /// In pt, this message translates to:
  /// **'Código de reset enviado por SMS ao usuário'**
  String get users_reset_sent;

  /// No description provided for @users_reset_admin_title.
  ///
  /// In pt, this message translates to:
  /// **'Redefinir Senha (Admin)'**
  String get users_reset_admin_title;

  /// No description provided for @users_reset_admin_description.
  ///
  /// In pt, this message translates to:
  /// **'Digite a nova senha para o utilizador. A senha NÃO é salva no histórico de SMS.'**
  String get users_reset_admin_description;

  /// No description provided for @users_reset_admin_new_password.
  ///
  /// In pt, this message translates to:
  /// **'Nova Senha'**
  String get users_reset_admin_new_password;

  /// No description provided for @users_reset_admin_confirm_password.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Nova Senha'**
  String get users_reset_admin_confirm_password;

  /// No description provided for @users_reset_admin_send_sms.
  ///
  /// In pt, this message translates to:
  /// **'Enviar SMS com a nova senha'**
  String get users_reset_admin_send_sms;

  /// No description provided for @users_reset_admin_password_min.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get users_reset_admin_password_min;

  /// No description provided for @users_reset_admin_password_mismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get users_reset_admin_password_mismatch;

  /// No description provided for @users_reset_admin_success.
  ///
  /// In pt, this message translates to:
  /// **'Senha redefinida com sucesso'**
  String get users_reset_admin_success;

  /// No description provided for @users_reset_admin_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao redefinir senha'**
  String get users_reset_admin_error;

  /// No description provided for @users_reset_admin_cannot_self.
  ///
  /// In pt, this message translates to:
  /// **'Use o menu de perfil para alterar sua própria senha'**
  String get users_reset_admin_cannot_self;

  /// No description provided for @sms_cleanup_title.
  ///
  /// In pt, this message translates to:
  /// **'Limpar SMS de Credenciais'**
  String get sms_cleanup_title;

  /// No description provided for @sms_cleanup_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza? Esta ação eliminará todos os registros de SMS de credenciais e OTP da base de dados.'**
  String get sms_cleanup_confirm;

  /// No description provided for @sms_cleanup_success.
  ///
  /// In pt, this message translates to:
  /// **'{count} registros de SMS eliminados com sucesso'**
  String sms_cleanup_success(int count);

  /// No description provided for @users_deactivate_description.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja desativar {name}? Esta ação pode ser revertida depois.'**
  String users_deactivate_description(String name);

  /// No description provided for @users_deactivated_success.
  ///
  /// In pt, this message translates to:
  /// **'Usuário desativado com sucesso'**
  String get users_deactivated_success;

  /// No description provided for @users_type_readonly_info.
  ///
  /// In pt, this message translates to:
  /// **'O tipo de usuário é exibido para conferência e permanece bloqueado nesta tela.'**
  String get users_type_readonly_info;

  /// No description provided for @users_error_reset.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar reset'**
  String get users_error_reset;

  /// No description provided for @users_error_deactivate.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao desativar'**
  String get users_error_deactivate;

  /// No description provided for @users_error_login_name_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Nome de login não encontrado para este usuário'**
  String get users_error_login_name_not_found;

  /// No description provided for @residents_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando moradores...'**
  String get residents_loading;

  /// No description provided for @residents_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por nome, telefone ou apartamento...'**
  String get residents_search_hint;

  /// No description provided for @residents_all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get residents_all;

  /// No description provided for @residents_count.
  ///
  /// In pt, this message translates to:
  /// **'{count} {count, plural, =1{morador} other{moradores}}'**
  String residents_count(int count);

  /// No description provided for @residents_of_total.
  ///
  /// In pt, this message translates to:
  /// **'de {total}'**
  String residents_of_total(int total);

  /// No description provided for @residents_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum morador encontrado'**
  String get residents_not_found;

  /// No description provided for @residents_none_registered.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum morador cadastrado'**
  String get residents_none_registered;

  /// No description provided for @residents_adjust_filters.
  ///
  /// In pt, this message translates to:
  /// **'Tente ajustar os filtros'**
  String get residents_adjust_filters;

  /// No description provided for @residents_owner.
  ///
  /// In pt, this message translates to:
  /// **'Prop.'**
  String get residents_owner;

  /// No description provided for @residents_since.
  ///
  /// In pt, this message translates to:
  /// **'Morador desde {date}'**
  String residents_since(String date);

  /// No description provided for @morador_detail_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Morador'**
  String get morador_detail_title;

  /// No description provided for @morador_error_loading.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar'**
  String get morador_error_loading;

  /// No description provided for @morador_data.
  ///
  /// In pt, this message translates to:
  /// **'Dados do morador'**
  String get morador_data;

  /// No description provided for @morador_data_description.
  ///
  /// In pt, this message translates to:
  /// **'Visualize e atualize informações básicas deste morador.'**
  String get morador_data_description;

  /// No description provided for @morador_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get morador_name;

  /// No description provided for @morador_name_required.
  ///
  /// In pt, this message translates to:
  /// **'Nome é obrigatório'**
  String get morador_name_required;

  /// No description provided for @morador_name_hint.
  ///
  /// In pt, this message translates to:
  /// **'Digite o nome'**
  String get morador_name_hint;

  /// No description provided for @morador_user_id.
  ///
  /// In pt, this message translates to:
  /// **'ID do Usuário'**
  String get morador_user_id;

  /// No description provided for @morador_registration_date.
  ///
  /// In pt, this message translates to:
  /// **'Data de registro'**
  String get morador_registration_date;

  /// No description provided for @morador_save_changes.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Alterações'**
  String get morador_save_changes;

  /// No description provided for @morador_updated_success.
  ///
  /// In pt, this message translates to:
  /// **'Morador atualizado com sucesso'**
  String get morador_updated_success;

  /// No description provided for @morador_remove.
  ///
  /// In pt, this message translates to:
  /// **'Remover morador'**
  String get morador_remove;

  /// No description provided for @morador_remove_warning.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação é irreversível. Confirme antes de remover definitivamente.'**
  String get morador_remove_warning;

  /// No description provided for @morador_delete_button.
  ///
  /// In pt, this message translates to:
  /// **'Deletar morador'**
  String get morador_delete_button;

  /// No description provided for @morador_delete_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Deletar Morador?'**
  String get morador_delete_confirm;

  /// No description provided for @morador_delete_description.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita e removerá o morador do sistema.'**
  String get morador_delete_description;

  /// No description provided for @morador_deleted_success.
  ///
  /// In pt, this message translates to:
  /// **'Morador deletado com sucesso'**
  String get morador_deleted_success;

  /// No description provided for @morador_id_not_informed.
  ///
  /// In pt, this message translates to:
  /// **'ID não informado'**
  String get morador_id_not_informed;

  /// No description provided for @morador_info_dynamic.
  ///
  /// In pt, this message translates to:
  /// **'Informações pessoais carregadas dinamicamente'**
  String get morador_info_dynamic;

  /// No description provided for @morador_information.
  ///
  /// In pt, this message translates to:
  /// **'Informações'**
  String get morador_information;

  /// No description provided for @morador_phone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get morador_phone;

  /// No description provided for @morador_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento'**
  String get morador_apartment;

  /// No description provided for @morador_email.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get morador_email;

  /// No description provided for @maintenance_title.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get maintenance_title;

  /// No description provided for @maintenance_filter_by_status.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por Status'**
  String get maintenance_filter_by_status;

  /// No description provided for @maintenance_all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get maintenance_all;

  /// No description provided for @maintenance_status_pending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get maintenance_status_pending;

  /// No description provided for @maintenance_status_in_progress.
  ///
  /// In pt, this message translates to:
  /// **'Em Andamento'**
  String get maintenance_status_in_progress;

  /// No description provided for @maintenance_status_in_analysis.
  ///
  /// In pt, this message translates to:
  /// **'Em Análise'**
  String get maintenance_status_in_analysis;

  /// No description provided for @maintenance_status_waiting.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando'**
  String get maintenance_status_waiting;

  /// No description provided for @maintenance_status_completed.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get maintenance_status_completed;

  /// No description provided for @maintenance_status_cancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get maintenance_status_cancelled;

  /// No description provided for @maintenance_status_rejected.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitado'**
  String get maintenance_status_rejected;

  /// No description provided for @maintenance_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando solicitações...'**
  String get maintenance_loading;

  /// No description provided for @maintenance_error_loading.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar'**
  String get maintenance_error_loading;

  /// No description provided for @maintenance_try_again.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get maintenance_try_again;

  /// No description provided for @maintenance_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma solicitação encontrada'**
  String get maintenance_empty;

  /// No description provided for @maintenance_empty_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Não há solicitações de manutenção no momento'**
  String get maintenance_empty_subtitle;

  /// No description provided for @maintenance_empty_create_hint.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma nova solicitação para começar'**
  String get maintenance_empty_create_hint;

  /// No description provided for @maintenance_empty_filter_hint.
  ///
  /// In pt, this message translates to:
  /// **'Tente ajustar os filtros'**
  String get maintenance_empty_filter_hint;

  /// No description provided for @maintenance_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por título...'**
  String get maintenance_search_hint;

  /// No description provided for @maintenance_page_info.
  ///
  /// In pt, this message translates to:
  /// **'Página {current} de {total}'**
  String maintenance_page_info(int current, int total);

  /// No description provided for @maintenance_previous.
  ///
  /// In pt, this message translates to:
  /// **'Anterior'**
  String get maintenance_previous;

  /// No description provided for @maintenance_next.
  ///
  /// In pt, this message translates to:
  /// **'Próxima'**
  String get maintenance_next;

  /// No description provided for @maintenance_responsible_label.
  ///
  /// In pt, this message translates to:
  /// **'Responsável: {name}'**
  String maintenance_responsible_label(String name);

  /// No description provided for @maintenance_comments_count.
  ///
  /// In pt, this message translates to:
  /// **'{count} comentário(s)'**
  String maintenance_comments_count(int count);

  /// No description provided for @maintenance_attachments_count.
  ///
  /// In pt, this message translates to:
  /// **'{count} anexo(s)'**
  String maintenance_attachments_count(int count);

  /// No description provided for @maintenance_apt_block.
  ///
  /// In pt, this message translates to:
  /// **'Apto {number} - {block}'**
  String maintenance_apt_block(String number, String block);

  /// No description provided for @maintenance_time_minutes_ago.
  ///
  /// In pt, this message translates to:
  /// **'Há {count} min'**
  String maintenance_time_minutes_ago(int count);

  /// No description provided for @maintenance_time_hours_ago.
  ///
  /// In pt, this message translates to:
  /// **'Há {count}h'**
  String maintenance_time_hours_ago(int count);

  /// No description provided for @maintenance_time_days_ago.
  ///
  /// In pt, this message translates to:
  /// **'Há {count} dias'**
  String maintenance_time_days_ago(int count);

  /// No description provided for @maintenance_yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get maintenance_yesterday;

  /// No description provided for @maintenance_pending_count.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get maintenance_pending_count;

  /// No description provided for @maintenance_in_progress_count.
  ///
  /// In pt, this message translates to:
  /// **'Em Andamento'**
  String get maintenance_in_progress_count;

  /// No description provided for @maintenance_completed_count.
  ///
  /// In pt, this message translates to:
  /// **'Concluídas'**
  String get maintenance_completed_count;

  /// No description provided for @maintenance_detail_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando solicitação...'**
  String get maintenance_detail_loading;

  /// No description provided for @maintenance_detail_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Solicitação não encontrada'**
  String get maintenance_detail_not_found;

  /// No description provided for @maintenance_detail_quick_actions.
  ///
  /// In pt, this message translates to:
  /// **'Ações rápidas'**
  String get maintenance_detail_quick_actions;

  /// No description provided for @maintenance_detail_edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get maintenance_detail_edit;

  /// No description provided for @maintenance_detail_complete.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get maintenance_detail_complete;

  /// No description provided for @maintenance_detail_in_progress.
  ///
  /// In pt, this message translates to:
  /// **'Em andamento'**
  String get maintenance_detail_in_progress;

  /// No description provided for @maintenance_detail_reopen.
  ///
  /// In pt, this message translates to:
  /// **'Reabrir'**
  String get maintenance_detail_reopen;

  /// No description provided for @maintenance_detail_cancel_request.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get maintenance_detail_cancel_request;

  /// No description provided for @maintenance_detail_reject_request.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar'**
  String get maintenance_detail_reject_request;

  /// No description provided for @maintenance_detail_assign_responsible.
  ///
  /// In pt, this message translates to:
  /// **'Atribuir'**
  String get maintenance_detail_assign_responsible;

  /// No description provided for @maintenance_detail_define_deadline.
  ///
  /// In pt, this message translates to:
  /// **'Definir Prazo'**
  String get maintenance_detail_define_deadline;

  /// No description provided for @maintenance_detail_no_description.
  ///
  /// In pt, this message translates to:
  /// **'Sem descrição'**
  String get maintenance_detail_no_description;

  /// No description provided for @maintenance_detail_comments.
  ///
  /// In pt, this message translates to:
  /// **'Comentários ({count})'**
  String maintenance_detail_comments(int count);

  /// No description provided for @maintenance_detail_no_comments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum comentário ainda'**
  String get maintenance_detail_no_comments;

  /// No description provided for @maintenance_detail_add_comment.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar comentário...'**
  String get maintenance_detail_add_comment;

  /// No description provided for @maintenance_detail_internal_comment.
  ///
  /// In pt, this message translates to:
  /// **'Comentário Interno'**
  String get maintenance_detail_internal_comment;

  /// No description provided for @maintenance_detail_internal.
  ///
  /// In pt, this message translates to:
  /// **'Interno'**
  String get maintenance_detail_internal;

  /// No description provided for @maintenance_detail_send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get maintenance_detail_send;

  /// No description provided for @maintenance_detail_status_updated.
  ///
  /// In pt, this message translates to:
  /// **'Status atualizado'**
  String get maintenance_detail_status_updated;

  /// No description provided for @maintenance_detail_comment_added.
  ///
  /// In pt, this message translates to:
  /// **'Comentário adicionado com sucesso'**
  String get maintenance_detail_comment_added;

  /// No description provided for @maintenance_detail_updated.
  ///
  /// In pt, this message translates to:
  /// **'Solicitação atualizada com sucesso'**
  String get maintenance_detail_updated;

  /// No description provided for @maintenance_detail_requester.
  ///
  /// In pt, this message translates to:
  /// **'Solicitante'**
  String get maintenance_detail_requester;

  /// No description provided for @maintenance_detail_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento'**
  String get maintenance_detail_apartment;

  /// No description provided for @maintenance_detail_resident.
  ///
  /// In pt, this message translates to:
  /// **'Morador'**
  String get maintenance_detail_resident;

  /// No description provided for @maintenance_detail_responsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get maintenance_detail_responsible;

  /// No description provided for @maintenance_detail_created_at.
  ///
  /// In pt, this message translates to:
  /// **'Criado em'**
  String get maintenance_detail_created_at;

  /// No description provided for @maintenance_detail_deadline.
  ///
  /// In pt, this message translates to:
  /// **'Prazo limite'**
  String get maintenance_detail_deadline;

  /// No description provided for @maintenance_detail_updated_at.
  ///
  /// In pt, this message translates to:
  /// **'Atualizado em'**
  String get maintenance_detail_updated_at;

  /// No description provided for @maintenance_detail_edit_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Editar solicitação'**
  String get maintenance_detail_edit_dialog_title;

  /// No description provided for @maintenance_detail_deadline_label.
  ///
  /// In pt, this message translates to:
  /// **'Data limite'**
  String get maintenance_detail_deadline_label;

  /// No description provided for @maintenance_detail_select_date.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar data'**
  String get maintenance_detail_select_date;

  /// No description provided for @maintenance_detail_responsible_employee.
  ///
  /// In pt, this message translates to:
  /// **'Responsável (Funcionário)'**
  String get maintenance_detail_responsible_employee;

  /// No description provided for @maintenance_detail_no_employee.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum funcionário disponível'**
  String get maintenance_detail_no_employee;

  /// No description provided for @maintenance_detail_select_responsible.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar responsável'**
  String get maintenance_detail_select_responsible;

  /// No description provided for @maintenance_detail_no_employees.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum funcionário'**
  String get maintenance_detail_no_employees;

  /// No description provided for @maintenance_detail_unknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get maintenance_detail_unknown;

  /// No description provided for @maintenance_detail_at_time.
  ///
  /// In pt, this message translates to:
  /// **'às {time}'**
  String maintenance_detail_at_time(String time);

  /// No description provided for @maintenance_request_title.
  ///
  /// In pt, this message translates to:
  /// **'Nova Solicitação'**
  String get maintenance_request_title;

  /// No description provided for @maintenance_request_describe_problem.
  ///
  /// In pt, this message translates to:
  /// **'Descreva o Problema'**
  String get maintenance_request_describe_problem;

  /// No description provided for @maintenance_request_describe_hint.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os detalhes para que o responsável possa atender'**
  String get maintenance_request_describe_hint;

  /// No description provided for @maintenance_request_problem_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Problema (opcional)'**
  String get maintenance_request_problem_type;

  /// No description provided for @maintenance_request_subject.
  ///
  /// In pt, this message translates to:
  /// **'Assunto'**
  String get maintenance_request_subject;

  /// No description provided for @maintenance_request_subject_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Torneira com vazamento'**
  String get maintenance_request_subject_hint;

  /// No description provided for @maintenance_request_description.
  ///
  /// In pt, this message translates to:
  /// **'Descrição Detalhada'**
  String get maintenance_request_description;

  /// No description provided for @maintenance_request_description_hint.
  ///
  /// In pt, this message translates to:
  /// **'Detalhe o problema ao máximo...'**
  String get maintenance_request_description_hint;

  /// No description provided for @maintenance_request_resident_responsible.
  ///
  /// In pt, this message translates to:
  /// **'Morador Responsável'**
  String get maintenance_request_resident_responsible;

  /// No description provided for @maintenance_request_select_resident.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o morador'**
  String get maintenance_request_select_resident;

  /// No description provided for @maintenance_request_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento'**
  String get maintenance_request_apartment;

  /// No description provided for @maintenance_request_select_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um apartamento'**
  String get maintenance_request_select_apartment;

  /// No description provided for @maintenance_request_create.
  ///
  /// In pt, this message translates to:
  /// **'Criar Solicitação'**
  String get maintenance_request_create;

  /// No description provided for @maintenance_request_sending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando...'**
  String get maintenance_request_sending;

  /// No description provided for @maintenance_request_success.
  ///
  /// In pt, this message translates to:
  /// **'Solicitação criada com sucesso!'**
  String get maintenance_request_success;

  /// No description provided for @maintenance_request_fill_required.
  ///
  /// In pt, this message translates to:
  /// **'Preencha todos os campos obrigatórios'**
  String get maintenance_request_fill_required;

  /// No description provided for @maintenance_request_select_apartment_error.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um apartamento'**
  String get maintenance_request_select_apartment_error;

  /// No description provided for @maintenance_request_select_resident_error.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o morador responsável pela solicitação'**
  String get maintenance_request_select_resident_error;

  /// No description provided for @maintenance_request_user_not_authenticated.
  ///
  /// In pt, this message translates to:
  /// **'Erro: Usuário não autenticado'**
  String get maintenance_request_user_not_authenticated;

  /// No description provided for @maintenance_request_resident_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível identificar o morador. Entre novamente.'**
  String get maintenance_request_resident_not_found;

  /// No description provided for @problem_type_leak.
  ///
  /// In pt, this message translates to:
  /// **'Vazamento'**
  String get problem_type_leak;

  /// No description provided for @problem_type_electrical.
  ///
  /// In pt, this message translates to:
  /// **'Elétrica'**
  String get problem_type_electrical;

  /// No description provided for @problem_type_plumbing.
  ///
  /// In pt, this message translates to:
  /// **'Encanamento'**
  String get problem_type_plumbing;

  /// No description provided for @problem_type_furniture.
  ///
  /// In pt, this message translates to:
  /// **'Móvel'**
  String get problem_type_furniture;

  /// No description provided for @problem_type_cleaning.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza'**
  String get problem_type_cleaning;

  /// No description provided for @problem_type_other.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get problem_type_other;

  /// No description provided for @agendamentos_schedule.
  ///
  /// In pt, this message translates to:
  /// **'Agendamento'**
  String get agendamentos_schedule;

  /// No description provided for @agendamentos_date_label.
  ///
  /// In pt, this message translates to:
  /// **'Data:'**
  String get agendamentos_date_label;

  /// No description provided for @agendamentos_time_label.
  ///
  /// In pt, this message translates to:
  /// **'Horário:'**
  String get agendamentos_time_label;

  /// No description provided for @agendamentos_estimated_duration.
  ///
  /// In pt, this message translates to:
  /// **'Duração Estimada:'**
  String get agendamentos_estimated_duration;

  /// No description provided for @agendamentos_location.
  ///
  /// In pt, this message translates to:
  /// **'Localização'**
  String get agendamentos_location;

  /// No description provided for @agendamentos_priority.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade:'**
  String get agendamentos_priority;

  /// No description provided for @agendamentos_responsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get agendamentos_responsible;

  /// No description provided for @agendamentos_your_response.
  ///
  /// In pt, this message translates to:
  /// **'Sua Resposta'**
  String get agendamentos_your_response;

  /// No description provided for @agendamentos_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get agendamentos_confirm;

  /// No description provided for @agendamentos_reschedule.
  ///
  /// In pt, this message translates to:
  /// **'Reagendar'**
  String get agendamentos_reschedule;

  /// No description provided for @agendamentos_decline.
  ///
  /// In pt, this message translates to:
  /// **'Recusar'**
  String get agendamentos_decline;

  /// No description provided for @agendamentos_response_sent.
  ///
  /// In pt, this message translates to:
  /// **'Resposta enviada'**
  String get agendamentos_response_sent;

  /// No description provided for @agendamentos_send_response.
  ///
  /// In pt, this message translates to:
  /// **'Enviar Resposta'**
  String get agendamentos_send_response;

  /// No description provided for @agendamentos_error_loading.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar agendamento'**
  String get agendamentos_error_loading;

  /// No description provided for @agendamentos_no_results_filter.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado para esses filtros'**
  String get agendamentos_no_results_filter;

  /// No description provided for @agendamentos_new.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get agendamentos_new;

  /// No description provided for @agendamentos_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por data, apartamento...'**
  String get agendamentos_search_hint;

  /// No description provided for @agendamentos_no_title.
  ///
  /// In pt, this message translates to:
  /// **'Sem título'**
  String get agendamentos_no_title;

  /// No description provided for @agendamentos_unknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get agendamentos_unknown;

  /// No description provided for @agendamentos_no_responsible.
  ///
  /// In pt, this message translates to:
  /// **'Sem responsável'**
  String get agendamentos_no_responsible;

  /// No description provided for @agendamentos_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum agendamento encontrado'**
  String get agendamentos_not_found;

  /// No description provided for @agendamentos_try_filters.
  ///
  /// In pt, this message translates to:
  /// **'Tente ajustar seus filtros'**
  String get agendamentos_try_filters;

  /// No description provided for @agendamentos_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando agendamentos...'**
  String get agendamentos_loading;

  /// No description provided for @agendamentos_new_title.
  ///
  /// In pt, this message translates to:
  /// **'Novo Agendamento'**
  String get agendamentos_new_title;

  /// No description provided for @agendamentos_title_required.
  ///
  /// In pt, this message translates to:
  /// **'Título é obrigatório'**
  String get agendamentos_title_required;

  /// No description provided for @agendamentos_type_required.
  ///
  /// In pt, this message translates to:
  /// **'Tipo é obrigatório'**
  String get agendamentos_type_required;

  /// No description provided for @agendamentos_date_required.
  ///
  /// In pt, this message translates to:
  /// **'Data é obrigatória'**
  String get agendamentos_date_required;

  /// No description provided for @agendamentos_time_required.
  ///
  /// In pt, this message translates to:
  /// **'Hora é obrigatória'**
  String get agendamentos_time_required;

  /// No description provided for @agendamentos_location_required.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o local do agendamento'**
  String get agendamentos_location_required;

  /// No description provided for @agendamentos_responsible_required.
  ///
  /// In pt, this message translates to:
  /// **'Responsável é obrigatório'**
  String get agendamentos_responsible_required;

  /// No description provided for @agendamentos_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Agendamento'**
  String get agendamentos_confirm_title;

  /// No description provided for @agendamentos_sms_will_send.
  ///
  /// In pt, this message translates to:
  /// **'SMS será enviado ao morador'**
  String get agendamentos_sms_will_send;

  /// No description provided for @agendamentos_created_success.
  ///
  /// In pt, this message translates to:
  /// **'Agendamento criado com sucesso!'**
  String get agendamentos_created_success;

  /// No description provided for @agendamentos_schedule_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Agende a Manutenção'**
  String get agendamentos_schedule_maintenance;

  /// No description provided for @agendamentos_fill_details.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os detalhes para organizar o atendimento'**
  String get agendamentos_fill_details;

  /// No description provided for @agendamentos_send_message_resident.
  ///
  /// In pt, this message translates to:
  /// **'Enviar mensagem ao morador'**
  String get agendamentos_send_message_resident;

  /// No description provided for @agendamentos_sms_mass_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'SMS em massa deve ser agendado separadamente em Comunicados'**
  String get agendamentos_sms_mass_tooltip;

  /// No description provided for @agendamentos_title_field.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get agendamentos_title_field;

  /// No description provided for @agendamentos_title_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Limpeza, Reparo de encanação'**
  String get agendamentos_title_hint;

  /// No description provided for @agendamentos_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get agendamentos_type;

  /// No description provided for @agendamentos_description_optional.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get agendamentos_description_optional;

  /// No description provided for @agendamentos_description_hint.
  ///
  /// In pt, this message translates to:
  /// **'Descreva os detalhes do agendamento'**
  String get agendamentos_description_hint;

  /// No description provided for @agendamentos_schedule_section.
  ///
  /// In pt, this message translates to:
  /// **'Cronograma'**
  String get agendamentos_schedule_section;

  /// No description provided for @agendamentos_date_field.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get agendamentos_date_field;

  /// No description provided for @agendamentos_notes_optional.
  ///
  /// In pt, this message translates to:
  /// **'Observações (opcional)'**
  String get agendamentos_notes_optional;

  /// No description provided for @agendamentos_notes_field.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get agendamentos_notes_field;

  /// No description provided for @agendamentos_notes_hint.
  ///
  /// In pt, this message translates to:
  /// **'Observações adicionais'**
  String get agendamentos_notes_hint;

  /// No description provided for @agendamentos_create_button.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get agendamentos_create_button;

  /// No description provided for @agendamentos_select_date.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar data'**
  String get agendamentos_select_date;

  /// No description provided for @agendamentos_time_field.
  ///
  /// In pt, this message translates to:
  /// **'Hora'**
  String get agendamentos_time_field;

  /// No description provided for @agendamentos_select_time.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a hora'**
  String get agendamentos_select_time;

  /// No description provided for @agendamentos_where_question.
  ///
  /// In pt, this message translates to:
  /// **'Onde será realizada?'**
  String get agendamentos_where_question;

  /// No description provided for @agendamentos_select_location.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o local'**
  String get agendamentos_select_location;

  /// No description provided for @agendamentos_no_employees.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum funcionário disponível'**
  String get agendamentos_no_employees;

  /// No description provided for @agendamentos_general_condo.
  ///
  /// In pt, this message translates to:
  /// **'GERAL/CONDOMÍNIO'**
  String get agendamentos_general_condo;

  /// No description provided for @agendamentos_apt.
  ///
  /// In pt, this message translates to:
  /// **'Apto'**
  String get agendamentos_apt;

  /// No description provided for @agendamentos_apartment_label.
  ///
  /// In pt, this message translates to:
  /// **'APARTAMENTO'**
  String get agendamentos_apartment_label;

  /// No description provided for @agendamentos_not_specified.
  ///
  /// In pt, this message translates to:
  /// **'Não especificado'**
  String get agendamentos_not_specified;

  /// No description provided for @create_morador_title.
  ///
  /// In pt, this message translates to:
  /// **'Novo Morador'**
  String get create_morador_title;

  /// No description provided for @create_morador_header.
  ///
  /// In pt, this message translates to:
  /// **'Criar Novo Morador'**
  String get create_morador_header;

  /// No description provided for @create_morador_description.
  ///
  /// In pt, this message translates to:
  /// **'Associe um usuário existente a um apartamento disponível para concluir o cadastro do morador.'**
  String get create_morador_description;

  /// No description provided for @create_morador_resident_users.
  ///
  /// In pt, this message translates to:
  /// **'Usuários Morador'**
  String get create_morador_resident_users;

  /// No description provided for @create_morador_available_apts.
  ///
  /// In pt, this message translates to:
  /// **'Aptos disponíveis'**
  String get create_morador_available_apts;

  /// No description provided for @create_morador_data.
  ///
  /// In pt, this message translates to:
  /// **'Dados do Morador'**
  String get create_morador_data;

  /// No description provided for @create_morador_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Morador'**
  String get create_morador_name_label;

  /// No description provided for @create_morador_name_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: João Silva'**
  String get create_morador_name_hint;

  /// No description provided for @create_morador_select_user.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um usuário'**
  String get create_morador_select_user;

  /// No description provided for @create_morador_no_users.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum usuário do tipo Morador disponível. Recarregue ou cadastre um usuário primeiro.'**
  String get create_morador_no_users;

  /// No description provided for @create_morador_apartment_optional.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento (opcional)'**
  String get create_morador_apartment_optional;

  /// No description provided for @create_morador_no_apartment_now.
  ///
  /// In pt, this message translates to:
  /// **'Sem apartamento agora (vincule depois)'**
  String get create_morador_no_apartment_now;

  /// No description provided for @create_morador_no_apartments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum apartamento disponível no momento. Recarregue para tentar novamente.'**
  String get create_morador_no_apartments;

  /// No description provided for @create_morador_button.
  ///
  /// In pt, this message translates to:
  /// **'Criar Morador'**
  String get create_morador_button;

  /// No description provided for @create_morador_creating.
  ///
  /// In pt, this message translates to:
  /// **'Criando...'**
  String get create_morador_creating;

  /// No description provided for @create_morador_success.
  ///
  /// In pt, this message translates to:
  /// **'Morador criado com sucesso!'**
  String get create_morador_success;

  /// No description provided for @create_morador_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar morador'**
  String get create_morador_error;

  /// No description provided for @create_morador_error_loading.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados'**
  String get create_morador_error_loading;

  /// No description provided for @create_morador_tip.
  ///
  /// In pt, this message translates to:
  /// **'Dica: selecione usuários já aprovados como Morador para garantir o acesso correto aos módulos.'**
  String get create_morador_tip;

  /// No description provided for @sms_massa_title.
  ///
  /// In pt, this message translates to:
  /// **'SMS em Massa'**
  String get sms_massa_title;

  /// No description provided for @sms_massa_tab_send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar SMS'**
  String get sms_massa_tab_send;

  /// No description provided for @sms_massa_tab_history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get sms_massa_tab_history;

  /// No description provided for @sms_massa_info_text.
  ///
  /// In pt, this message translates to:
  /// **'Envie SMS para múltiplos usuários\nMáx. 500 caracteres por mensagem'**
  String get sms_massa_info_text;

  /// No description provided for @sms_massa_selection_mode.
  ///
  /// In pt, this message translates to:
  /// **'Modo de Seleção'**
  String get sms_massa_selection_mode;

  /// No description provided for @sms_massa_by_type.
  ///
  /// In pt, this message translates to:
  /// **'Por Tipo'**
  String get sms_massa_by_type;

  /// No description provided for @sms_massa_specific.
  ///
  /// In pt, this message translates to:
  /// **'Específicos'**
  String get sms_massa_specific;

  /// No description provided for @sms_massa_user_types.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de Usuário'**
  String get sms_massa_user_types;

  /// No description provided for @sms_massa_select_users.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Usuários ({selected}/{total})'**
  String sms_massa_select_users(int selected, int total);

  /// No description provided for @sms_massa_sms_message.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem do SMS'**
  String get sms_massa_sms_message;

  /// No description provided for @sms_massa_type_message.
  ///
  /// In pt, this message translates to:
  /// **'Digite a mensagem...'**
  String get sms_massa_type_message;

  /// No description provided for @sms_massa_send_app_notification.
  ///
  /// In pt, this message translates to:
  /// **'Enviar notificação no app'**
  String get sms_massa_send_app_notification;

  /// No description provided for @sms_massa_besides_sms.
  ///
  /// In pt, this message translates to:
  /// **'Além do SMS, criar notificação no app'**
  String get sms_massa_besides_sms;

  /// No description provided for @sms_massa_notification_title_optional.
  ///
  /// In pt, this message translates to:
  /// **'Título da Notificação (opcional)'**
  String get sms_massa_notification_title_optional;

  /// No description provided for @sms_massa_notification_title_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Comunicado Importante'**
  String get sms_massa_notification_title_hint;

  /// No description provided for @sms_massa_send_button.
  ///
  /// In pt, this message translates to:
  /// **'Enviar SMS em Massa'**
  String get sms_massa_send_button;

  /// No description provided for @sms_massa_type_message_error.
  ///
  /// In pt, this message translates to:
  /// **'Digite uma mensagem'**
  String get sms_massa_type_message_error;

  /// No description provided for @sms_massa_message_too_long.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem muito longa (máx 500 caracteres)'**
  String get sms_massa_message_too_long;

  /// No description provided for @sms_massa_select_user_type_error.
  ///
  /// In pt, this message translates to:
  /// **'Selecione pelo menos um tipo de usuário'**
  String get sms_massa_select_user_type_error;

  /// No description provided for @sms_massa_select_user_error.
  ///
  /// In pt, this message translates to:
  /// **'Selecione pelo menos um usuário'**
  String get sms_massa_select_user_error;

  /// No description provided for @sms_massa_success.
  ///
  /// In pt, this message translates to:
  /// **'SMS enviado: {sent}/{total} com sucesso'**
  String sms_massa_success(int sent, int total);

  /// No description provided for @sms_massa_error_sending.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar SMS: {error}'**
  String sms_massa_error_sending(String error);

  /// No description provided for @sms_massa_no_recipients.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum destinatário disponível'**
  String get sms_massa_no_recipients;

  /// No description provided for @sms_massa_no_history.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum SMS enviado ainda'**
  String get sms_massa_no_history;

  /// No description provided for @sms_massa_history_appear_here.
  ///
  /// In pt, this message translates to:
  /// **'O histórico de envios aparecerá aqui'**
  String get sms_massa_history_appear_here;

  /// No description provided for @sms_massa_by.
  ///
  /// In pt, this message translates to:
  /// **'Por {name}'**
  String sms_massa_by(String name);

  /// No description provided for @sms_massa_recipients.
  ///
  /// In pt, this message translates to:
  /// **'Destinatários'**
  String get sms_massa_recipients;

  /// No description provided for @sms_massa_sent.
  ///
  /// In pt, this message translates to:
  /// **'Enviados'**
  String get sms_massa_sent;

  /// No description provided for @sms_massa_notifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get sms_massa_notifications;

  /// No description provided for @sms_massa_time_now.
  ///
  /// In pt, this message translates to:
  /// **'Agora'**
  String get sms_massa_time_now;

  /// No description provided for @sms_massa_time_minutes_ago.
  ///
  /// In pt, this message translates to:
  /// **'{count}m atrás'**
  String sms_massa_time_minutes_ago(int count);

  /// No description provided for @sms_massa_time_hours_ago.
  ///
  /// In pt, this message translates to:
  /// **'{count}h atrás'**
  String sms_massa_time_hours_ago(int count);

  /// No description provided for @sms_massa_time_days_ago.
  ///
  /// In pt, this message translates to:
  /// **'{count}d atrás'**
  String sms_massa_time_days_ago(int count);

  /// No description provided for @sms_massa_yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get sms_massa_yesterday;

  /// No description provided for @sms_massa_administrator.
  ///
  /// In pt, this message translates to:
  /// **'Administrador'**
  String get sms_massa_administrator;

  /// No description provided for @sms_massa_employee.
  ///
  /// In pt, this message translates to:
  /// **'Funcionario'**
  String get sms_massa_employee;

  /// No description provided for @sms_massa_resident.
  ///
  /// In pt, this message translates to:
  /// **'Morador'**
  String get sms_massa_resident;

  /// No description provided for @change_password_success.
  ///
  /// In pt, this message translates to:
  /// **'Senha alterada com sucesso!'**
  String get change_password_success;

  /// No description provided for @change_password_protect_account.
  ///
  /// In pt, this message translates to:
  /// **'Proteja sua conta'**
  String get change_password_protect_account;

  /// No description provided for @change_password_tip.
  ///
  /// In pt, this message translates to:
  /// **'Altere sua senha regularmente e evite reutilizar senhas anteriores.'**
  String get change_password_tip;

  /// No description provided for @change_password_current.
  ///
  /// In pt, this message translates to:
  /// **'Senha Atual'**
  String get change_password_current;

  /// No description provided for @change_password_current_hint.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua senha atual'**
  String get change_password_current_hint;

  /// No description provided for @change_password_new.
  ///
  /// In pt, this message translates to:
  /// **'Nova Senha'**
  String get change_password_new;

  /// No description provided for @change_password_new_hint.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma nova senha'**
  String get change_password_new_hint;

  /// No description provided for @change_password_new_required.
  ///
  /// In pt, this message translates to:
  /// **'Digite uma nova senha'**
  String get change_password_new_required;

  /// No description provided for @change_password_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Nova Senha'**
  String get change_password_confirm;

  /// No description provided for @change_password_confirm_hint.
  ///
  /// In pt, this message translates to:
  /// **'Repita a nova senha'**
  String get change_password_confirm_hint;

  /// No description provided for @change_password_confirm_required.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua senha'**
  String get change_password_confirm_required;

  /// No description provided for @change_password_saving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando...'**
  String get change_password_saving;

  /// No description provided for @mp_form_edit_title.
  ///
  /// In pt, this message translates to:
  /// **'Editar Manutenção'**
  String get mp_form_edit_title;

  /// No description provided for @mp_form_new_title.
  ///
  /// In pt, this message translates to:
  /// **'Nova Manutenção'**
  String get mp_form_new_title;

  /// No description provided for @mp_form_title_required.
  ///
  /// In pt, this message translates to:
  /// **'Título é obrigatório'**
  String get mp_form_title_required;

  /// No description provided for @mp_form_next_maintenance_required.
  ///
  /// In pt, this message translates to:
  /// **'Próxima manutenção é obrigatória'**
  String get mp_form_next_maintenance_required;

  /// No description provided for @mp_form_updated_success.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção atualizada com sucesso'**
  String get mp_form_updated_success;

  /// No description provided for @mp_form_created_success.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção criada com sucesso'**
  String get mp_form_created_success;

  /// No description provided for @mp_form_save_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar manutenção'**
  String get mp_form_save_error;

  /// No description provided for @mp_form_title_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Troca de óleo do motor'**
  String get mp_form_title_hint;

  /// No description provided for @mp_form_maintenance_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Manutenção'**
  String get mp_form_maintenance_type;

  /// No description provided for @mp_form_type_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Preventiva, Corretiva'**
  String get mp_form_type_hint;

  /// No description provided for @mp_form_select_frequency.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a frequência'**
  String get mp_form_select_frequency;

  /// No description provided for @mp_form_select_date.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a data'**
  String get mp_form_select_date;

  /// No description provided for @mp_form_description_hint.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da manutenção'**
  String get mp_form_description_hint;

  /// No description provided for @mp_form_supplier_hint.
  ///
  /// In pt, this message translates to:
  /// **'Nome do fornecedor'**
  String get mp_form_supplier_hint;

  /// No description provided for @mp_form_supplier_phone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone Fornecedor'**
  String get mp_form_supplier_phone;

  /// No description provided for @mp_form_freq_weekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get mp_form_freq_weekly;

  /// No description provided for @mp_form_freq_monthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get mp_form_freq_monthly;

  /// No description provided for @mp_form_freq_quarterly.
  ///
  /// In pt, this message translates to:
  /// **'Trimestral'**
  String get mp_form_freq_quarterly;

  /// No description provided for @mp_form_freq_semiannually.
  ///
  /// In pt, this message translates to:
  /// **'Semestral'**
  String get mp_form_freq_semiannually;

  /// No description provided for @mp_form_freq_annually.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get mp_form_freq_annually;

  /// No description provided for @history_residents_title.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Moradores'**
  String get history_residents_title;

  /// No description provided for @history_current_residents.
  ///
  /// In pt, this message translates to:
  /// **'Moradores Atuais'**
  String get history_current_residents;

  /// No description provided for @history_complete.
  ///
  /// In pt, this message translates to:
  /// **'Histórico Completo'**
  String get history_complete;

  /// No description provided for @history_no_current_residents.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum morador atualmente'**
  String get history_no_current_residents;

  /// No description provided for @history_period.
  ///
  /// In pt, this message translates to:
  /// **'Período'**
  String get history_period;

  /// No description provided for @history_records.
  ///
  /// In pt, this message translates to:
  /// **'registros'**
  String get history_records;

  /// No description provided for @history_filter_30_days.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 30 dias'**
  String get history_filter_30_days;

  /// No description provided for @history_filter_6_months.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 6 meses'**
  String get history_filter_6_months;

  /// No description provided for @history_filter_12_months.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 12 meses'**
  String get history_filter_12_months;

  /// No description provided for @history_filter_all.
  ///
  /// In pt, this message translates to:
  /// **'Todo o histórico'**
  String get history_filter_all;

  /// No description provided for @history_active.
  ///
  /// In pt, this message translates to:
  /// **'Ativos'**
  String get history_active;

  /// No description provided for @history_previous.
  ///
  /// In pt, this message translates to:
  /// **'Anteriores'**
  String get history_previous;

  /// No description provided for @history_average.
  ///
  /// In pt, this message translates to:
  /// **'Média'**
  String get history_average;

  /// No description provided for @history_occupancy_timeline.
  ///
  /// In pt, this message translates to:
  /// **'Linha do tempo de ocupação'**
  String get history_occupancy_timeline;

  /// No description provided for @reports_critical_events.
  ///
  /// In pt, this message translates to:
  /// **'Eventos críticos no sistema'**
  String get reports_critical_events;

  /// No description provided for @reports_leak_detected_apt.
  ///
  /// In pt, this message translates to:
  /// **'Vazamento detectado no apto {aptNumber}'**
  String reports_leak_detected_apt(String aptNumber);

  /// No description provided for @reports_pending_scheduling.
  ///
  /// In pt, this message translates to:
  /// **'Agendamento Pendente'**
  String get reports_pending_scheduling;

  /// No description provided for @reports_responsible_unconfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Responsável não confirmou'**
  String get reports_responsible_unconfirmed;

  /// No description provided for @reports_building_occupied_percent.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% do edifício ocupado'**
  String reports_building_occupied_percent(int percent);

  /// No description provided for @reports_status_active.
  ///
  /// In pt, this message translates to:
  /// **'Ativa'**
  String get reports_status_active;

  /// No description provided for @reports_status_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get reports_status_maintenance;

  /// No description provided for @reports_free.
  ///
  /// In pt, this message translates to:
  /// **'Gratuito'**
  String get reports_free;

  /// No description provided for @reports_cost_per_hour.
  ///
  /// In pt, this message translates to:
  /// **'MZN {cost}/h'**
  String reports_cost_per_hour(String cost);

  /// No description provided for @register_min_3_chars.
  ///
  /// In pt, this message translates to:
  /// **'Deve ter pelo menos 3 caracteres'**
  String get register_min_3_chars;

  /// No description provided for @register_invalid_phone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone inválido'**
  String get register_invalid_phone;

  /// No description provided for @register_password_required.
  ///
  /// In pt, this message translates to:
  /// **'Senha é obrigatória'**
  String get register_password_required;

  /// No description provided for @register_password_min_length.
  ///
  /// In pt, this message translates to:
  /// **'Senha deve ter pelo menos 6 caracteres'**
  String get register_password_min_length;

  /// No description provided for @register_confirm_password_required.
  ///
  /// In pt, this message translates to:
  /// **'Confirmação de senha é obrigatória'**
  String get register_confirm_password_required;

  /// No description provided for @register_passwords_dont_match.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não correspondem'**
  String get register_passwords_dont_match;

  /// No description provided for @register_accept_terms_label.
  ///
  /// In pt, this message translates to:
  /// **'Aceito os Termos de Serviço'**
  String get register_accept_terms_label;

  /// No description provided for @avaliar_rate_service.
  ///
  /// In pt, this message translates to:
  /// **'Avalie o Serviço'**
  String get avaliar_rate_service;

  /// No description provided for @avaliar_service_completed.
  ///
  /// In pt, this message translates to:
  /// **'Serviço Realizado'**
  String get avaliar_service_completed;

  /// No description provided for @avaliar_service.
  ///
  /// In pt, this message translates to:
  /// **'Serviço'**
  String get avaliar_service;

  /// No description provided for @avaliar_general_cleaning.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza geral'**
  String get avaliar_general_cleaning;

  /// No description provided for @avaliar_select_rating.
  ///
  /// In pt, this message translates to:
  /// **'Selecione uma avaliação'**
  String get avaliar_select_rating;

  /// No description provided for @avaliar_very_dissatisfied.
  ///
  /// In pt, this message translates to:
  /// **'Muito insatisfeito 😞'**
  String get avaliar_very_dissatisfied;

  /// No description provided for @avaliar_dissatisfied.
  ///
  /// In pt, this message translates to:
  /// **'Insatisfeito 😕'**
  String get avaliar_dissatisfied;

  /// No description provided for @avaliar_neutral.
  ///
  /// In pt, this message translates to:
  /// **'Neutro 😐'**
  String get avaliar_neutral;

  /// No description provided for @avaliar_satisfied.
  ///
  /// In pt, this message translates to:
  /// **'Satisfeito 😊'**
  String get avaliar_satisfied;

  /// No description provided for @avaliar_very_satisfied.
  ///
  /// In pt, this message translates to:
  /// **'Muito satisfeito! 😁'**
  String get avaliar_very_satisfied;

  /// No description provided for @avaliar_what_worked_well.
  ///
  /// In pt, this message translates to:
  /// **'O que funcionou bem?'**
  String get avaliar_what_worked_well;

  /// No description provided for @avaliar_aspect_punctuality.
  ///
  /// In pt, this message translates to:
  /// **'Pontualidade'**
  String get avaliar_aspect_punctuality;

  /// No description provided for @avaliar_aspect_quality.
  ///
  /// In pt, this message translates to:
  /// **'Qualidade'**
  String get avaliar_aspect_quality;

  /// No description provided for @avaliar_aspect_politeness.
  ///
  /// In pt, this message translates to:
  /// **'Educação'**
  String get avaliar_aspect_politeness;

  /// No description provided for @avaliar_aspect_cleanliness.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza'**
  String get avaliar_aspect_cleanliness;

  /// No description provided for @avaliar_recommend_professional.
  ///
  /// In pt, this message translates to:
  /// **'Recomendaria este profissional?'**
  String get avaliar_recommend_professional;

  /// No description provided for @avaliar_yes_definitely.
  ///
  /// In pt, this message translates to:
  /// **'Sim, com certeza!'**
  String get avaliar_yes_definitely;

  /// No description provided for @avaliar_leave_comment.
  ///
  /// In pt, this message translates to:
  /// **'Deixe um comentário (opcional)'**
  String get avaliar_leave_comment;

  /// No description provided for @avaliar_share_experience.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhe sua experiência...'**
  String get avaliar_share_experience;

  /// No description provided for @avaliar_skip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get avaliar_skip;

  /// No description provided for @avaliar_send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get avaliar_send;

  /// No description provided for @avaliar_select_classification.
  ///
  /// In pt, this message translates to:
  /// **'Selecione uma classificação'**
  String get avaliar_select_classification;

  /// No description provided for @avaliar_thank_you.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado pela avaliação!'**
  String get avaliar_thank_you;

  /// No description provided for @items_apartment_title.
  ///
  /// In pt, this message translates to:
  /// **'Itens do Apartamento'**
  String get items_apartment_title;

  /// No description provided for @items_no_permission.
  ///
  /// In pt, this message translates to:
  /// **'Apenas síndico ou funcionário podem gerenciar itens.'**
  String get items_no_permission;

  /// No description provided for @items_no_delete_permission.
  ///
  /// In pt, this message translates to:
  /// **'Sem permissão para excluir itens.'**
  String get items_no_delete_permission;

  /// No description provided for @items_edit_item.
  ///
  /// In pt, this message translates to:
  /// **'Editar Item'**
  String get items_edit_item;

  /// No description provided for @items_new_item.
  ///
  /// In pt, this message translates to:
  /// **'Novo Item'**
  String get items_new_item;

  /// No description provided for @items_for_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Para o apartamento {name}'**
  String items_for_apartment(String name);

  /// No description provided for @items_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Item'**
  String get items_name_label;

  /// No description provided for @items_name_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Ar Condicionado, Geladeira, etc'**
  String get items_name_hint;

  /// No description provided for @items_description_label.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get items_description_label;

  /// No description provided for @items_description_hint.
  ///
  /// In pt, this message translates to:
  /// **'Adicione informações sobre o estado, marca, etc'**
  String get items_description_hint;

  /// No description provided for @items_quantity_label.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get items_quantity_label;

  /// No description provided for @items_quantity_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 1'**
  String get items_quantity_hint;

  /// No description provided for @items_estimated_value_label.
  ///
  /// In pt, this message translates to:
  /// **'Valor Estimado (MZN)'**
  String get items_estimated_value_label;

  /// No description provided for @items_estimated_value_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 1500.00'**
  String get items_estimated_value_hint;

  /// No description provided for @items_type_label.
  ///
  /// In pt, this message translates to:
  /// **'Tipo do Item'**
  String get items_type_label;

  /// No description provided for @items_type_furniture.
  ///
  /// In pt, this message translates to:
  /// **'Mobília'**
  String get items_type_furniture;

  /// No description provided for @items_type_appliance.
  ///
  /// In pt, this message translates to:
  /// **'Eletrodoméstico'**
  String get items_type_appliance;

  /// No description provided for @items_type_electronics.
  ///
  /// In pt, this message translates to:
  /// **'Eletrônico'**
  String get items_type_electronics;

  /// No description provided for @items_type_plumbing.
  ///
  /// In pt, this message translates to:
  /// **'Hidráulica'**
  String get items_type_plumbing;

  /// No description provided for @items_type_lighting.
  ///
  /// In pt, this message translates to:
  /// **'Iluminação'**
  String get items_type_lighting;

  /// No description provided for @items_type_structure.
  ///
  /// In pt, this message translates to:
  /// **'Estrutura'**
  String get items_type_structure;

  /// No description provided for @items_type_other.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get items_type_other;

  /// No description provided for @items_type_not_informed.
  ///
  /// In pt, this message translates to:
  /// **'Tipo não informado'**
  String get items_type_not_informed;

  /// No description provided for @items_update_item.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar Item'**
  String get items_update_item;

  /// No description provided for @items_add_item.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Item'**
  String get items_add_item;

  /// No description provided for @items_close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get items_close;

  /// No description provided for @items_name_required.
  ///
  /// In pt, this message translates to:
  /// **'Nome é obrigatório'**
  String get items_name_required;

  /// No description provided for @items_quantity_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade deve ser um número maior que zero'**
  String get items_quantity_invalid;

  /// No description provided for @items_quantity_max.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade máxima permitida é 9999'**
  String get items_quantity_max;

  /// No description provided for @items_created_success.
  ///
  /// In pt, this message translates to:
  /// **'Item criado com sucesso'**
  String get items_created_success;

  /// No description provided for @items_updated_success.
  ///
  /// In pt, this message translates to:
  /// **'Item atualizado com sucesso'**
  String get items_updated_success;

  /// No description provided for @items_save_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar item: {error}'**
  String items_save_error(String error);

  /// No description provided for @items_delete_title.
  ///
  /// In pt, this message translates to:
  /// **'Deletar Item?'**
  String get items_delete_title;

  /// No description provided for @items_delete_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita.'**
  String get items_delete_confirm;

  /// No description provided for @items_deleted_success.
  ///
  /// In pt, this message translates to:
  /// **'Item deletado com sucesso'**
  String get items_deleted_success;

  /// No description provided for @items_delete_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao deletar item: {error}'**
  String items_delete_error(String error);

  /// No description provided for @items_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os itens deste apartamento.'**
  String get items_load_error;

  /// No description provided for @items_check_connection.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua conexão e tente novamente'**
  String get items_check_connection;

  /// No description provided for @items_view_details.
  ///
  /// In pt, this message translates to:
  /// **'Ver Detalhes'**
  String get items_view_details;

  /// No description provided for @items_error_details_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do erro'**
  String get items_error_details_title;

  /// No description provided for @items_unknown_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro desconhecido'**
  String get items_unknown_error;

  /// No description provided for @items_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item cadastrado'**
  String get items_empty_title;

  /// No description provided for @items_empty_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicione itens para manter um registro do que há no apartamento'**
  String get items_empty_subtitle;

  /// No description provided for @items_add_first.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Primeiro Item'**
  String get items_add_first;

  /// No description provided for @common_not_available.
  ///
  /// In pt, this message translates to:
  /// **'N/A'**
  String get common_not_available;

  /// No description provided for @mp_cost_hint.
  ///
  /// In pt, this message translates to:
  /// **'0,00'**
  String get mp_cost_hint;

  /// No description provided for @mp_currency_prefix.
  ///
  /// In pt, this message translates to:
  /// **'MZN '**
  String get mp_currency_prefix;

  /// No description provided for @responder_title.
  ///
  /// In pt, this message translates to:
  /// **'Responder'**
  String get responder_title;

  /// No description provided for @responder_proposed_schedule.
  ///
  /// In pt, this message translates to:
  /// **'Agendamento Proposto'**
  String get responder_proposed_schedule;

  /// No description provided for @responder_service.
  ///
  /// In pt, this message translates to:
  /// **'Serviço'**
  String get responder_service;

  /// No description provided for @responder_service_example.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza geral - Apt. 402'**
  String get responder_service_example;

  /// No description provided for @responder_date_example.
  ///
  /// In pt, this message translates to:
  /// **'15 de Janeiro de 2026'**
  String get responder_date_example;

  /// No description provided for @responder_time_slot.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get responder_time_slot;

  /// No description provided for @responder_time_example.
  ///
  /// In pt, this message translates to:
  /// **'10:00 - 11:00'**
  String get responder_time_example;

  /// No description provided for @responder_responsible_example.
  ///
  /// In pt, this message translates to:
  /// **'João da Silva'**
  String get responder_responsible_example;

  /// No description provided for @responder_what_response.
  ///
  /// In pt, this message translates to:
  /// **'Qual é sua resposta?'**
  String get responder_what_response;

  /// No description provided for @responder_accept.
  ///
  /// In pt, this message translates to:
  /// **'Aceitar'**
  String get responder_accept;

  /// No description provided for @responder_decline.
  ///
  /// In pt, this message translates to:
  /// **'Recusar'**
  String get responder_decline;

  /// No description provided for @responder_select_new_datetime.
  ///
  /// In pt, this message translates to:
  /// **'Selecione uma nova data e hora'**
  String get responder_select_new_datetime;

  /// No description provided for @responder_select.
  ///
  /// In pt, this message translates to:
  /// **'Selecione'**
  String get responder_select;

  /// No description provided for @responder_hour.
  ///
  /// In pt, this message translates to:
  /// **'Hora'**
  String get responder_hour;

  /// No description provided for @responder_message_optional.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem (opcional)'**
  String get responder_message_optional;

  /// No description provided for @responder_decline_reason_hint.
  ///
  /// In pt, this message translates to:
  /// **'Descreva o motivo da recusa...'**
  String get responder_decline_reason_hint;

  /// No description provided for @responder_schedule_accepted.
  ///
  /// In pt, this message translates to:
  /// **'Agendamento aceito'**
  String get responder_schedule_accepted;

  /// No description provided for @responder_schedule_declined.
  ///
  /// In pt, this message translates to:
  /// **'Agendamento recusado'**
  String get responder_schedule_declined;

  /// No description provided for @settings_theme_changed.
  ///
  /// In pt, this message translates to:
  /// **'Tema alterado para {theme}'**
  String settings_theme_changed(String theme);

  /// No description provided for @error_update_with_details.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar: {error}'**
  String error_update_with_details(String error);

  /// No description provided for @error_delete_with_details.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao deletar: {error}'**
  String error_delete_with_details(String error);

  /// No description provided for @morador_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Morador'**
  String get morador_name_label;

  /// No description provided for @morador_since_date.
  ///
  /// In pt, this message translates to:
  /// **'Morador desde {date}'**
  String morador_since_date(String date);

  /// No description provided for @error_creating_request.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar solicitação'**
  String get error_creating_request;

  /// No description provided for @avaliar_placeholder_name.
  ///
  /// In pt, this message translates to:
  /// **'João da Silva'**
  String get avaliar_placeholder_name;

  /// No description provided for @historico_residents_title.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Moradores - {title}'**
  String historico_residents_title(String title);

  /// No description provided for @history_entry.
  ///
  /// In pt, this message translates to:
  /// **'Entrada'**
  String get history_entry;

  /// No description provided for @history_exit.
  ///
  /// In pt, this message translates to:
  /// **'Saída'**
  String get history_exit;

  /// No description provided for @history_duration.
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get history_duration;

  /// No description provided for @history_present.
  ///
  /// In pt, this message translates to:
  /// **'Presente'**
  String get history_present;

  /// No description provided for @reports_export_requests_excel.
  ///
  /// In pt, this message translates to:
  /// **'Solicitações (Excel)'**
  String get reports_export_requests_excel;

  /// No description provided for @reports_export_requests_pdf.
  ///
  /// In pt, this message translates to:
  /// **'Solicitações (PDF)'**
  String get reports_export_requests_pdf;

  /// No description provided for @reports_export_apartments_excel.
  ///
  /// In pt, this message translates to:
  /// **'Apartamentos (Excel)'**
  String get reports_export_apartments_excel;

  /// No description provided for @reports_export_residents_excel.
  ///
  /// In pt, this message translates to:
  /// **'Moradores (Excel)'**
  String get reports_export_residents_excel;

  /// No description provided for @reports_export_users_excel.
  ///
  /// In pt, this message translates to:
  /// **'Usuários (Excel)'**
  String get reports_export_users_excel;

  /// No description provided for @reports_export_agendamentos_excel.
  ///
  /// In pt, this message translates to:
  /// **'Agendamentos (Excel)'**
  String get reports_export_agendamentos_excel;

  /// No description provided for @reports_export_manutencoes_excel.
  ///
  /// In pt, this message translates to:
  /// **'Manutenções Preventivas (Excel)'**
  String get reports_export_manutencoes_excel;

  /// No description provided for @reports_export_ativos_excel.
  ///
  /// In pt, this message translates to:
  /// **'Ativos/Patrimônio (Excel)'**
  String get reports_export_ativos_excel;

  /// No description provided for @reports_export_sms_excel.
  ///
  /// In pt, this message translates to:
  /// **'Histórico SMS (Excel)'**
  String get reports_export_sms_excel;

  /// No description provided for @reports_export_kpi_excel.
  ///
  /// In pt, this message translates to:
  /// **'KPIs (Excel)'**
  String get reports_export_kpi_excel;

  /// No description provided for @reports_export_kpi_pdf.
  ///
  /// In pt, this message translates to:
  /// **'KPIs (PDF)'**
  String get reports_export_kpi_pdf;

  /// No description provided for @reports_export_complete.
  ///
  /// In pt, this message translates to:
  /// **'📦 Relatório Completo (Pasta)'**
  String get reports_export_complete;

  /// No description provided for @reports_export_complete_zip.
  ///
  /// In pt, this message translates to:
  /// **'📦 Relatório Completo (ZIP)'**
  String get reports_export_complete_zip;

  /// No description provided for @reports_exporting.
  ///
  /// In pt, this message translates to:
  /// **'Exportando...'**
  String get reports_exporting;

  /// No description provided for @reports_exporting_multiple.
  ///
  /// In pt, this message translates to:
  /// **'Exportando múltiplos arquivos...'**
  String get reports_exporting_multiple;

  /// No description provided for @reports_export_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Exportar relatórios'**
  String get reports_export_tooltip;

  /// No description provided for @reports_kpi_mttr.
  ///
  /// In pt, this message translates to:
  /// **'MTTR'**
  String get reports_kpi_mttr;

  /// No description provided for @reports_delay_stats.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas de Atraso'**
  String get reports_delay_stats;

  /// No description provided for @reports_distribution_by_type.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição por Tipo'**
  String get reports_distribution_by_type;

  /// No description provided for @reports_top_late_responsible.
  ///
  /// In pt, this message translates to:
  /// **'Top Responsáveis por Atraso'**
  String get reports_top_late_responsible;

  /// No description provided for @reports_monthly_evolution.
  ///
  /// In pt, this message translates to:
  /// **'Evolução Mensal'**
  String get reports_monthly_evolution;

  /// No description provided for @items_transfer_title.
  ///
  /// In pt, this message translates to:
  /// **'Transferir item'**
  String get items_transfer_title;

  /// No description provided for @items_transfer_button.
  ///
  /// In pt, this message translates to:
  /// **'Transferir'**
  String get items_transfer_button;

  /// No description provided for @items_update_state_title.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar estado do item'**
  String get items_update_state_title;

  /// No description provided for @items_update_state_button.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar estado'**
  String get items_update_state_button;

  /// No description provided for @items_movement_history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de movimentação'**
  String get items_movement_history;

  /// No description provided for @items_history_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar histórico'**
  String get items_history_load_error;

  /// No description provided for @items_history_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum histórico encontrado.'**
  String get items_history_empty;

  /// No description provided for @items_history_button.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get items_history_button;

  /// No description provided for @items_no_movement_found.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação encontrada para esse item.'**
  String get items_no_movement_found;

  /// No description provided for @items_movement_details.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da Movimentação'**
  String get items_movement_details;

  /// No description provided for @items_origin.
  ///
  /// In pt, this message translates to:
  /// **'Origem'**
  String get items_origin;

  /// No description provided for @items_destination.
  ///
  /// In pt, this message translates to:
  /// **'Destino'**
  String get items_destination;

  /// No description provided for @items_reason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo'**
  String get items_reason;

  /// No description provided for @items_observations.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get items_observations;

  /// No description provided for @items_transfer_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Transferir Item'**
  String get items_transfer_dialog_title;

  /// No description provided for @items_dest_apartment_id.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento destino (ID)'**
  String get items_dest_apartment_id;

  /// No description provided for @items_new_state_optional.
  ///
  /// In pt, this message translates to:
  /// **'Novo estado (opcional)'**
  String get items_new_state_optional;

  /// No description provided for @items_reason_optional.
  ///
  /// In pt, this message translates to:
  /// **'Motivo (opcional)'**
  String get items_reason_optional;

  /// No description provided for @items_observations_optional.
  ///
  /// In pt, this message translates to:
  /// **'Observações (opcional)'**
  String get items_observations_optional;

  /// No description provided for @items_transfer_success.
  ///
  /// In pt, this message translates to:
  /// **'Transferência realizada com sucesso'**
  String get items_transfer_success;

  /// No description provided for @items_transfer_fail.
  ///
  /// In pt, this message translates to:
  /// **'Falha na transferência'**
  String get items_transfer_fail;

  /// No description provided for @items_update_state_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar Estado'**
  String get items_update_state_dialog_title;

  /// No description provided for @items_new_state.
  ///
  /// In pt, this message translates to:
  /// **'Novo estado'**
  String get items_new_state;

  /// No description provided for @items_update_success.
  ///
  /// In pt, this message translates to:
  /// **'Estado atualizado com sucesso'**
  String get items_update_success;

  /// No description provided for @items_update_fail.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao atualizar estado'**
  String get items_update_fail;

  /// No description provided for @items_item_not_provided.
  ///
  /// In pt, this message translates to:
  /// **'Item não informado'**
  String get items_item_not_provided;

  /// No description provided for @items_update_state_menu.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar Estado'**
  String get items_update_state_menu;

  /// No description provided for @items_history_title.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Itens'**
  String get items_history_title;

  /// No description provided for @common_view_all.
  ///
  /// In pt, this message translates to:
  /// **'Ver tudo'**
  String get common_view_all;

  /// No description provided for @common_history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get common_history;

  /// No description provided for @common_close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get common_close;

  /// No description provided for @common_search_placeholder.
  ///
  /// In pt, this message translates to:
  /// **'Buscar item ou apartamento...'**
  String get common_search_placeholder;

  /// No description provided for @common_search_action.
  ///
  /// In pt, this message translates to:
  /// **'Buscar (placeholder)'**
  String get common_search_action;

  /// No description provided for @common_add.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get common_add;

  /// No description provided for @common_remove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get common_remove;

  /// No description provided for @common_save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get common_save;

  /// No description provided for @common_saving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando...'**
  String get common_saving;

  /// No description provided for @assets_item_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Item não encontrado'**
  String get assets_item_not_found;

  /// No description provided for @request_types_title.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de Solicitação'**
  String get request_types_title;

  /// No description provided for @request_types_add_new.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar novo tipo:'**
  String get request_types_add_new;

  /// No description provided for @request_types_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Elétrica, Vazamento'**
  String get request_types_hint;

  /// No description provided for @request_types_registered.
  ///
  /// In pt, this message translates to:
  /// **'Tipos cadastrados:'**
  String get request_types_registered;

  /// No description provided for @request_types_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum tipo cadastrado.'**
  String get request_types_empty;

  /// No description provided for @apartments_add_new.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Apartamento'**
  String get apartments_add_new;

  /// No description provided for @assets_management_title.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Ativos'**
  String get assets_management_title;

  /// No description provided for @assets_items_registered.
  ///
  /// In pt, this message translates to:
  /// **'{count} itens cadastrados'**
  String assets_items_registered(int count);

  /// No description provided for @assets_scan_qr.
  ///
  /// In pt, this message translates to:
  /// **'Escanear QR Code'**
  String get assets_scan_qr;

  /// No description provided for @assets_generate_batch_qr.
  ///
  /// In pt, this message translates to:
  /// **'Gerar QR Codes em Lote'**
  String get assets_generate_batch_qr;

  /// No description provided for @assets_search_placeholder.
  ///
  /// In pt, this message translates to:
  /// **'Buscar ativos'**
  String get assets_search_placeholder;

  /// No description provided for @assets_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Nome, código ou tipo...'**
  String get assets_search_hint;

  /// No description provided for @assets_filter_all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get assets_filter_all;

  /// No description provided for @assets_filter_available.
  ///
  /// In pt, this message translates to:
  /// **'Disponíveis'**
  String get assets_filter_available;

  /// No description provided for @assets_filter_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get assets_filter_maintenance;

  /// No description provided for @assets_filter_damaged.
  ///
  /// In pt, this message translates to:
  /// **'Danificados'**
  String get assets_filter_damaged;

  /// No description provided for @assets_filter_by_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Por Apto'**
  String get assets_filter_by_apartment;

  /// No description provided for @assets_results_count.
  ///
  /// In pt, this message translates to:
  /// **'{count} resultado(s)'**
  String assets_results_count(int count);

  /// No description provided for @assets_stat_total.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get assets_stat_total;

  /// No description provided for @assets_sort_by_name.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por nome'**
  String get assets_sort_by_name;

  /// No description provided for @assets_sort_by_code.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por código'**
  String get assets_sort_by_code;

  /// No description provided for @assets_sort_by_state.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por estado'**
  String get assets_sort_by_state;

  /// No description provided for @assets_label_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get assets_label_name;

  /// No description provided for @assets_label_code.
  ///
  /// In pt, this message translates to:
  /// **'Código'**
  String get assets_label_code;

  /// No description provided for @assets_label_state.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get assets_label_state;

  /// No description provided for @assets_fail_open_details.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao abrir detalhes'**
  String get assets_fail_open_details;

  /// No description provided for @assets_code_not_generated.
  ///
  /// In pt, this message translates to:
  /// **'Código não gerado'**
  String get assets_code_not_generated;

  /// No description provided for @assets_copy_code.
  ///
  /// In pt, this message translates to:
  /// **'Copiar código'**
  String get assets_copy_code;

  /// No description provided for @assets_code_copied.
  ///
  /// In pt, this message translates to:
  /// **'Código copiado'**
  String get assets_code_copied;

  /// No description provided for @assets_menu_qr_code.
  ///
  /// In pt, this message translates to:
  /// **'QR Code'**
  String get assets_menu_qr_code;

  /// No description provided for @assets_menu_edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get assets_menu_edit;

  /// No description provided for @assets_menu_transfer.
  ///
  /// In pt, this message translates to:
  /// **'Transferir'**
  String get assets_menu_transfer;

  /// No description provided for @assets_menu_generate_code.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Código'**
  String get assets_menu_generate_code;

  /// No description provided for @assets_menu_delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get assets_menu_delete;

  /// No description provided for @assets_no_results.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado'**
  String get assets_no_results;

  /// No description provided for @assets_no_items.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ativo cadastrado'**
  String get assets_no_items;

  /// No description provided for @assets_try_another_search.
  ///
  /// In pt, this message translates to:
  /// **'Tente outro termo de busca ou limpe os filtros.'**
  String get assets_try_another_search;

  /// No description provided for @assets_start_adding.
  ///
  /// In pt, this message translates to:
  /// **'Comece adicionando seu primeiro ativo.'**
  String get assets_start_adding;

  /// No description provided for @assets_add.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Ativo'**
  String get assets_add;

  /// No description provided for @assets_select_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Apartamento'**
  String get assets_select_apartment;

  /// No description provided for @assets_code_generated_with_value.
  ///
  /// In pt, this message translates to:
  /// **'Código gerado: {code}'**
  String assets_code_generated_with_value(String code);

  /// No description provided for @assets_code_generated_success.
  ///
  /// In pt, this message translates to:
  /// **'Código gerado com sucesso'**
  String get assets_code_generated_success;

  /// No description provided for @assets_code_generate_fail.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao gerar código'**
  String get assets_code_generate_fail;

  /// No description provided for @assets_close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get assets_close;

  /// No description provided for @assets_copy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get assets_copy;

  /// No description provided for @assets_edit_asset.
  ///
  /// In pt, this message translates to:
  /// **'Editar Ativo'**
  String get assets_edit_asset;

  /// No description provided for @assets_new_asset.
  ///
  /// In pt, this message translates to:
  /// **'Novo Ativo'**
  String get assets_new_asset;

  /// No description provided for @assets_field_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento'**
  String get assets_field_apartment;

  /// No description provided for @assets_field_name_required.
  ///
  /// In pt, this message translates to:
  /// **'Nome *'**
  String get assets_field_name_required;

  /// No description provided for @assets_field_description.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get assets_field_description;

  /// No description provided for @assets_field_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get assets_field_type;

  /// No description provided for @assets_field_quantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get assets_field_quantity;

  /// No description provided for @assets_state_new.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get assets_state_new;

  /// No description provided for @assets_state_available.
  ///
  /// In pt, this message translates to:
  /// **'Disponível'**
  String get assets_state_available;

  /// No description provided for @assets_state_used.
  ///
  /// In pt, this message translates to:
  /// **'Usado'**
  String get assets_state_used;

  /// No description provided for @assets_state_in_maintenance.
  ///
  /// In pt, this message translates to:
  /// **'Em manutenção'**
  String get assets_state_in_maintenance;

  /// No description provided for @assets_state_damaged.
  ///
  /// In pt, this message translates to:
  /// **'Danificado'**
  String get assets_state_damaged;

  /// No description provided for @assets_save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get assets_save;

  /// No description provided for @assets_asset_updated.
  ///
  /// In pt, this message translates to:
  /// **'Ativo atualizado'**
  String get assets_asset_updated;

  /// No description provided for @assets_asset_added.
  ///
  /// In pt, this message translates to:
  /// **'Ativo adicionado'**
  String get assets_asset_added;

  /// No description provided for @assets_transfer_asset.
  ///
  /// In pt, this message translates to:
  /// **'Transferir Ativo'**
  String get assets_transfer_asset;

  /// No description provided for @assets_link.
  ///
  /// In pt, this message translates to:
  /// **'Vincular'**
  String get assets_link;

  /// No description provided for @assets_move_to_stock.
  ///
  /// In pt, this message translates to:
  /// **'Mover para Stock'**
  String get assets_move_to_stock;

  /// No description provided for @assets_dest_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Apartamento destino'**
  String get assets_dest_apartment;

  /// No description provided for @assets_new_state.
  ///
  /// In pt, this message translates to:
  /// **'Novo estado'**
  String get assets_new_state;

  /// No description provided for @assets_field_reason_required.
  ///
  /// In pt, this message translates to:
  /// **'Motivo *'**
  String get assets_field_reason_required;

  /// No description provided for @assets_field_observations.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get assets_field_observations;

  /// No description provided for @assets_inform_reason.
  ///
  /// In pt, this message translates to:
  /// **'Informe o motivo da transferência'**
  String get assets_inform_reason;

  /// No description provided for @assets_session_expired.
  ///
  /// In pt, this message translates to:
  /// **'Sessão expirada. Faça login novamente.'**
  String get assets_session_expired;

  /// No description provided for @assets_transfer_completed.
  ///
  /// In pt, this message translates to:
  /// **'Transferência concluída'**
  String get assets_transfer_completed;

  /// No description provided for @assets_transfer_failed.
  ///
  /// In pt, this message translates to:
  /// **'Falha na transferência'**
  String get assets_transfer_failed;

  /// No description provided for @assets_delete_asset.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Ativo'**
  String get assets_delete_asset;

  /// No description provided for @assets_delete_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir este ativo?'**
  String get assets_delete_confirm;

  /// No description provided for @assets_delete_irreversible.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita.'**
  String get assets_delete_irreversible;

  /// No description provided for @assets_asset_deleted.
  ///
  /// In pt, this message translates to:
  /// **'Ativo excluído'**
  String get assets_asset_deleted;

  /// No description provided for @assets_files_saved.
  ///
  /// In pt, this message translates to:
  /// **'{count} arquivo(s) salvo(s)'**
  String assets_files_saved(int count);

  /// No description provided for @assets_search_by_code.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por Código'**
  String get assets_search_by_code;

  /// No description provided for @assets_patrimony_code.
  ///
  /// In pt, this message translates to:
  /// **'Código patrimônio'**
  String get assets_patrimony_code;

  /// No description provided for @assets_code_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Código \"{code}\" não encontrado.'**
  String assets_code_not_found(String code);

  /// No description provided for @assets_register.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar'**
  String get assets_register;

  /// No description provided for @assets_scan_qr_short.
  ///
  /// In pt, this message translates to:
  /// **'Escanear QR'**
  String get assets_scan_qr_short;

  /// No description provided for @assets_generate_codes.
  ///
  /// In pt, this message translates to:
  /// **'Gerar códigos'**
  String get assets_generate_codes;

  /// No description provided for @assets_search_by_name_desc_code.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por nome, descrição ou código'**
  String get assets_search_by_name_desc_code;

  /// No description provided for @assets_count.
  ///
  /// In pt, this message translates to:
  /// **'{count} ativo(s)'**
  String assets_count(int count);

  /// No description provided for @assets_code_label.
  ///
  /// In pt, this message translates to:
  /// **'Código: {code}'**
  String assets_code_label(String code);

  /// No description provided for @assets_code_not_generated_msg.
  ///
  /// In pt, this message translates to:
  /// **'Código de patrimônio não gerado'**
  String get assets_code_not_generated_msg;

  /// No description provided for @assets_show_qr.
  ///
  /// In pt, this message translates to:
  /// **'Exibir QR'**
  String get assets_show_qr;

  /// No description provided for @assets_no_items_loaded.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ativo carregado. Use o scanner para consultar um ativo.'**
  String get assets_no_items_loaded;

  /// No description provided for @assets_no_match_filter.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ativo corresponde ao filtro de busca.'**
  String get assets_no_match_filter;

  /// No description provided for @assets_consulted.
  ///
  /// In pt, this message translates to:
  /// **'Ativo consultado: {code}'**
  String assets_consulted(String code);

  /// No description provided for @assets_consult_fail.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao consultar ativo'**
  String get assets_consult_fail;

  /// No description provided for @assets_codes_generated.
  ///
  /// In pt, this message translates to:
  /// **'Códigos de patrimônio gerados'**
  String get assets_codes_generated;

  /// No description provided for @assets_codes_generate_fail.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao gerar códigos'**
  String get assets_codes_generate_fail;

  /// No description provided for @assets_qr_patrimony.
  ///
  /// In pt, this message translates to:
  /// **'QR do Patrimônio'**
  String get assets_qr_patrimony;

  /// No description provided for @assets_register_not_implemented.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro de ativo ainda não implementado'**
  String get assets_register_not_implemented;

  /// No description provided for @assets_detail_title.
  ///
  /// In pt, this message translates to:
  /// **'Ativo • {code}'**
  String assets_detail_title(String code);

  /// No description provided for @assets_refresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get assets_refresh;

  /// No description provided for @assets_error_load.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar ativo'**
  String get assets_error_load;

  /// No description provided for @assets_try_again.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get assets_try_again;

  /// No description provided for @assets_not_linked.
  ///
  /// In pt, this message translates to:
  /// **'(não vinculado)'**
  String get assets_not_linked;

  /// No description provided for @assets_stat_quantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get assets_stat_quantity;

  /// No description provided for @assets_stat_estimated_value.
  ///
  /// In pt, this message translates to:
  /// **'Valor estimado'**
  String get assets_stat_estimated_value;

  /// No description provided for @assets_stat_last_movement.
  ///
  /// In pt, this message translates to:
  /// **'Última movimentação'**
  String get assets_stat_last_movement;

  /// No description provided for @assets_details.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get assets_details;

  /// No description provided for @assets_acquisition_date.
  ///
  /// In pt, this message translates to:
  /// **'Data aquisição'**
  String get assets_acquisition_date;

  /// No description provided for @assets_identifier_code.
  ///
  /// In pt, this message translates to:
  /// **'Código identificador'**
  String get assets_identifier_code;

  /// No description provided for @assets_current_state.
  ///
  /// In pt, this message translates to:
  /// **'Estado atual'**
  String get assets_current_state;

  /// No description provided for @assets_notes.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get assets_notes;

  /// No description provided for @assets_movement_history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Movimentações'**
  String get assets_movement_history;

  /// No description provided for @assets_no_movement_registered.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação registrada'**
  String get assets_no_movement_registered;

  /// No description provided for @assets_movement.
  ///
  /// In pt, this message translates to:
  /// **'Movimentação'**
  String get assets_movement;

  /// No description provided for @assets_origin.
  ///
  /// In pt, this message translates to:
  /// **'Origem'**
  String get assets_origin;

  /// No description provided for @assets_destination.
  ///
  /// In pt, this message translates to:
  /// **'Destino'**
  String get assets_destination;

  /// No description provided for @assets_responsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get assets_responsible;

  /// No description provided for @assets_not_informed.
  ///
  /// In pt, this message translates to:
  /// **'Não informado'**
  String get assets_not_informed;

  /// No description provided for @assets_attachments.
  ///
  /// In pt, this message translates to:
  /// **'Anexos'**
  String get assets_attachments;

  /// No description provided for @assets_no_attachments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum anexo disponível'**
  String get assets_no_attachments;

  /// No description provided for @assets_footer.
  ///
  /// In pt, this message translates to:
  /// **'Owany • Gestão de Ativos'**
  String get assets_footer;

  /// No description provided for @assets_no_apartment_for_transfer.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum apartamento disponível para transferência.'**
  String get assets_no_apartment_for_transfer;

  /// No description provided for @assets_stock_without_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Estoque (sem apartamento)'**
  String get assets_stock_without_apartment;

  /// No description provided for @assets_apartment_block_label.
  ///
  /// In pt, this message translates to:
  /// **'Apt {numero} - Bloco {bloco}'**
  String assets_apartment_block_label(String numero, String bloco);

  /// No description provided for @assets_apartment_short.
  ///
  /// In pt, this message translates to:
  /// **'Apt {numero}'**
  String assets_apartment_short(String numero);

  /// No description provided for @assets_na.
  ///
  /// In pt, this message translates to:
  /// **'N/A'**
  String get assets_na;

  /// No description provided for @assets_motivo.
  ///
  /// In pt, this message translates to:
  /// **'Motivo'**
  String get assets_motivo;

  /// No description provided for @assets_observacoes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get assets_observacoes;

  /// No description provided for @assets_asset_title.
  ///
  /// In pt, this message translates to:
  /// **'Ativo • {codigo}'**
  String assets_asset_title(String codigo);

  /// No description provided for @common_refresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get common_refresh;

  /// No description provided for @assets_error_loading.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar'**
  String get assets_error_loading;

  /// No description provided for @assets_quantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get assets_quantity;

  /// No description provided for @assets_estimated_value.
  ///
  /// In pt, this message translates to:
  /// **'Valor Estimado'**
  String get assets_estimated_value;

  /// No description provided for @assets_last_movement.
  ///
  /// In pt, this message translates to:
  /// **'Última Movimentação'**
  String get assets_last_movement;

  /// No description provided for @assets_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get assets_type;

  /// No description provided for @assets_description.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get assets_description;

  /// No description provided for @assets_no_movements.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação registrada'**
  String get assets_no_movements;

  /// No description provided for @assets_state.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get assets_state;

  /// No description provided for @assets_no_apt_available.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum apartamento disponível para transferência'**
  String get assets_no_apt_available;

  /// No description provided for @assets_field_reason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo'**
  String get assets_field_reason;

  /// No description provided for @assets_no_apartment_transfer.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum apartamento para transferir'**
  String get assets_no_apartment_transfer;

  /// No description provided for @mp_register_execution.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Execução'**
  String get mp_register_execution;

  /// No description provided for @mp_execution_status.
  ///
  /// In pt, this message translates to:
  /// **'Status da Execução'**
  String get mp_execution_status;

  /// No description provided for @mp_execution_date.
  ///
  /// In pt, this message translates to:
  /// **'Data de Realização'**
  String get mp_execution_date;

  /// No description provided for @mp_select_date.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar data'**
  String get mp_select_date;

  /// No description provided for @mp_invoice.
  ///
  /// In pt, this message translates to:
  /// **'Nota Fiscal (opcional)'**
  String get mp_invoice;

  /// No description provided for @mp_invoice_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: NF-001234'**
  String get mp_invoice_hint;

  /// No description provided for @mp_status_concluida.
  ///
  /// In pt, this message translates to:
  /// **'Concluída'**
  String get mp_status_concluida;

  /// No description provided for @mp_status_em_andamento.
  ///
  /// In pt, this message translates to:
  /// **'Em Andamento'**
  String get mp_status_em_andamento;

  /// No description provided for @mp_status_cancelada.
  ///
  /// In pt, this message translates to:
  /// **'Cancelada'**
  String get mp_status_cancelada;

  /// No description provided for @mp_save_execution.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Execução'**
  String get mp_save_execution;

  /// No description provided for @mp_invoice_label.
  ///
  /// In pt, this message translates to:
  /// **'Nota Fiscal'**
  String get mp_invoice_label;

  /// No description provided for @residents_apt_label.
  ///
  /// In pt, this message translates to:
  /// **'Apto {numero}'**
  String residents_apt_label(String numero);

  /// No description provided for @residents_block_label.
  ///
  /// In pt, this message translates to:
  /// **'Bloco {bloco}'**
  String residents_block_label(String bloco);

  /// No description provided for @residents_floor_label.
  ///
  /// In pt, this message translates to:
  /// **'{andar}º andar'**
  String residents_floor_label(int andar);

  /// No description provided for @residents_no_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Sem apartamento vinculado'**
  String get residents_no_apartment;

  /// No description provided for @residents_no_account.
  ///
  /// In pt, this message translates to:
  /// **'Sem conta vinculada'**
  String get residents_no_account;

  /// No description provided for @residents_with_account.
  ///
  /// In pt, this message translates to:
  /// **'Com conta vinculada'**
  String get residents_with_account;

  /// No description provided for @residents_contact.
  ///
  /// In pt, this message translates to:
  /// **'Contato'**
  String get residents_contact;

  /// No description provided for @residents_resident.
  ///
  /// In pt, this message translates to:
  /// **'Morador'**
  String get residents_resident;

  /// No description provided for @residents_tenant.
  ///
  /// In pt, this message translates to:
  /// **'Inquilino'**
  String get residents_tenant;

  /// No description provided for @residents_owner_full.
  ///
  /// In pt, this message translates to:
  /// **'Proprietário'**
  String get residents_owner_full;

  /// No description provided for @residents_active.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get residents_active;

  /// No description provided for @residents_inactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get residents_inactive;

  /// No description provided for @residents_group_no_apartment.
  ///
  /// In pt, this message translates to:
  /// **'Sem apartamento'**
  String get residents_group_no_apartment;

  /// No description provided for @maintenance_my_requests.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Solicitações'**
  String get maintenance_my_requests;

  /// No description provided for @maintenance_all_requests.
  ///
  /// In pt, this message translates to:
  /// **'Todas as Solicitações'**
  String get maintenance_all_requests;

  /// No description provided for @maintenance_exporting.
  ///
  /// In pt, this message translates to:
  /// **'Exportando solicitações...'**
  String get maintenance_exporting;

  /// No description provided for @maintenance_export_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Exportar solicitações'**
  String get maintenance_export_tooltip;

  /// No description provided for @maintenance_export_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao exportar: {error}'**
  String maintenance_export_error(String error);

  /// No description provided for @maintenance_total_label.
  ///
  /// In pt, this message translates to:
  /// **'{count} solicitações'**
  String maintenance_total_label(int count);

  /// No description provided for @maintenance_deadline_label.
  ///
  /// In pt, this message translates to:
  /// **'Prazo: {date}'**
  String maintenance_deadline_label(String date);

  /// No description provided for @maintenance_overdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasada'**
  String get maintenance_overdue;

  /// No description provided for @maintenance_no_responsible.
  ///
  /// In pt, this message translates to:
  /// **'Sem responsável'**
  String get maintenance_no_responsible;

  /// No description provided for @maintenance_created_by.
  ///
  /// In pt, this message translates to:
  /// **'Por {name}'**
  String maintenance_created_by(String name);

  /// No description provided for @maintenance_status_em_analise.
  ///
  /// In pt, this message translates to:
  /// **'Em Análise'**
  String get maintenance_status_em_analise;

  /// No description provided for @maintenance_status_aguardando.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando'**
  String get maintenance_status_aguardando;

  /// No description provided for @maintenance_status_rejeitado.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitado'**
  String get maintenance_status_rejeitado;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
