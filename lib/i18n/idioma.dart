enum Idioma { pt, en }

class I18n {
  final Idioma idioma;
  I18n(this.idioma);

  static Idioma idiomaAtual = Idioma.pt;
  static I18n get t => I18n(idiomaAtual);

  static const Map<String, Map<Idioma, String>> _texts = {
    // Common
    'common_cancel': {Idioma.pt: 'Cancelar', Idioma.en: 'Cancel'},
    'common_exit': {Idioma.pt: 'Sair', Idioma.en: 'Exit'},
    'common_loading': {Idioma.pt: 'Carregando...', Idioma.en: 'Loading...'},

    // Login
    'login_app_name': {Idioma.pt: 'Owany', Idioma.en: 'Owany'},
    'login_welcome': {Idioma.pt: 'Bem-vindo de volta!', Idioma.en: 'Welcome back!'},
    'login_identifier_label': {Idioma.pt: 'Telefone ou Usuário', Idioma.en: 'Phone or Username'},
    'login_password_label': {Idioma.pt: 'Senha', Idioma.en: 'Password'},
    'login_sign_in': {Idioma.pt: 'Entrar', Idioma.en: 'Sign In'},
    'login_need_access': {
      Idioma.pt: 'Precisa de acesso? Contacte o administrador do sistema.',
      Idioma.en: 'Need access? Contact the system administrator.',
    },
    'login_forgot_password': {Idioma.pt: 'Esqueceu sua senha?', Idioma.en: 'Forgot password?'},
    'login_required_field': {Idioma.pt: 'Campo obrigatório', Idioma.en: 'Required field'},
    'login_error_connection': {
      Idioma.pt: 'Não foi possível conectar ao servidor',
      Idioma.en: 'Unable to connect to server',
    },
    'login_error_credentials': {Idioma.pt: 'Usuário ou senha incorretos', Idioma.en: 'Invalid credentials'},
    'login_error_generic': {
      Idioma.pt: 'Ocorreu um erro. Tente novamente',
      Idioma.en: 'An error occurred. Please try again',
    },
    'login_processing': {Idioma.pt: 'Processando...', Idioma.en: 'Processing...'},
    'login_language_pt': {Idioma.pt: 'Português', Idioma.en: 'Portuguese'},
    'login_language_en': {Idioma.pt: 'English', Idioma.en: 'English'},

    // Settings
    'settings_title': {Idioma.pt: 'Configurações', Idioma.en: 'Settings'},
    'settings_account_preferences': {Idioma.pt: 'Preferências da Conta', Idioma.en: 'Account Preferences'},
    'settings_account_subtitle': {
      Idioma.pt: 'Gerencie sua experiência e segurança',
      Idioma.en: 'Manage your experience and security',
    },
    'settings_security': {Idioma.pt: 'Segurança', Idioma.en: 'Security'},
    'settings_change_password': {Idioma.pt: 'Alterar Senha', Idioma.en: 'Change Password'},
    'settings_change_password_subtitle': {
      Idioma.pt: 'Atualize sua senha regularmente',
      Idioma.en: 'Update your password regularly',
    },
    'settings_notifications': {Idioma.pt: 'Notificações', Idioma.en: 'Notifications'},
    'settings_notifications_push': {Idioma.pt: 'Notificações Push', Idioma.en: 'Push Notifications'},
    'settings_notifications_push_subtitle': {Idioma.pt: 'Alertas em tempo real', Idioma.en: 'Real-time alerts'},
    'settings_notifications_email': {Idioma.pt: 'Notificações por Email', Idioma.en: 'Email Notifications'},
    'settings_notifications_email_subtitle': {
      Idioma.pt: 'Resumo semanal de atividades',
      Idioma.en: 'Weekly activity summary',
    },
    'settings_appearance': {Idioma.pt: 'Aparência', Idioma.en: 'Appearance'},
    'settings_theme': {Idioma.pt: 'Tema', Idioma.en: 'Theme'},
    'settings_language': {Idioma.pt: 'Idioma', Idioma.en: 'Language'},
    'settings_language_subtitle': {Idioma.pt: 'Português • English', Idioma.en: 'Portuguese • English'},
    'settings_about': {Idioma.pt: 'Sobre', Idioma.en: 'About'},
    'settings_about_description': {
      Idioma.pt:
          'Sistema moderno de gestão de edifícios para facilitar o gerenciamento de apartamentos, solicitações de manutenção e comunicação com residentes.',
      Idioma.en:
          'Modern building management system to facilitate apartment management, maintenance requests, and resident communication.',
    },
    'settings_logout': {Idioma.pt: 'Sair da Conta', Idioma.en: 'Sign Out'},
    'settings_logout_confirm_title': {Idioma.pt: 'Confirmar Saída', Idioma.en: 'Confirm Sign Out'},
    'settings_logout_confirm_body': {
      Idioma.pt: 'Tem certeza que deseja sair da sua conta? Você precisará fazer login novamente.',
      Idioma.en: 'Are you sure you want to sign out? You will need to log in again.',
    },
    'settings_language_apply_restart': {
      Idioma.pt: 'Idioma será aplicado na próxima reinicialização',
      Idioma.en: 'Language will be applied on next restart',
    },

    // Manutencao Preventiva Detalhes
    'mp_details_title': {Idioma.pt: 'Detalhes da Manutenção', Idioma.en: 'Maintenance Details'},
    'mp_not_found': {Idioma.pt: 'Manutenção não encontrada', Idioma.en: 'Maintenance not found'},
    'mp_status_overdue': {Idioma.pt: 'Vencida', Idioma.en: 'Overdue'},
    'mp_status_alert': {Idioma.pt: 'Em Alerta', Idioma.en: 'Alert'},
    'mp_status_active': {Idioma.pt: 'Ativa', Idioma.en: 'Active'},
    'mp_info_general': {Idioma.pt: 'Informações Gerais', Idioma.en: 'General Information'},
    'mp_title': {Idioma.pt: 'Título', Idioma.en: 'Title'},
    'mp_type': {Idioma.pt: 'Tipo', Idioma.en: 'Type'},
    'mp_frequency': {Idioma.pt: 'Frequência', Idioma.en: 'Frequency'},
    'mp_status': {Idioma.pt: 'Status', Idioma.en: 'Status'},
    'mp_active': {Idioma.pt: 'Ativa', Idioma.en: 'Active'},
    'mp_inactive': {Idioma.pt: 'Inativa', Idioma.en: 'Inactive'},
    'mp_schedule': {Idioma.pt: 'Cronograma', Idioma.en: 'Schedule'},
    'mp_next_maintenance': {Idioma.pt: 'Próxima Manutenção', Idioma.en: 'Next Maintenance'},
    'mp_last_maintenance': {Idioma.pt: 'Última Manutenção', Idioma.en: 'Last Maintenance'},
    'mp_never_executed': {Idioma.pt: 'Nunca executada', Idioma.en: 'Never executed'},
    'mp_total_executions': {Idioma.pt: 'Total de Execuções', Idioma.en: 'Total Executions'},
    'mp_costs_supplier': {Idioma.pt: 'Custos e Fornecedor', Idioma.en: 'Costs and Supplier'},
    'mp_estimated_cost': {Idioma.pt: 'Custo Estimado', Idioma.en: 'Estimated Cost'},
    'mp_supplier': {Idioma.pt: 'Fornecedor', Idioma.en: 'Supplier'},
    'mp_phone': {Idioma.pt: 'Telefone', Idioma.en: 'Phone'},
    'mp_responsible': {Idioma.pt: 'Responsável', Idioma.en: 'Responsible'},
    'mp_name': {Idioma.pt: 'Nome', Idioma.en: 'Name'},
    'mp_not_assigned': {Idioma.pt: 'Não atribuído', Idioma.en: 'Not assigned'},
    'mp_created_by': {Idioma.pt: 'Criado por', Idioma.en: 'Created by'},
    'mp_last_update': {Idioma.pt: 'Última atualização', Idioma.en: 'Last update'},
    'mp_description': {Idioma.pt: 'Descrição', Idioma.en: 'Description'},
    'mp_notes': {Idioma.pt: 'Observações', Idioma.en: 'Notes'},
    'mp_edit': {Idioma.pt: 'Editar', Idioma.en: 'Edit'},
    'mp_conclude': {Idioma.pt: 'Concluir', Idioma.en: 'Complete'},
    'mp_history_empty': {Idioma.pt: 'Nenhuma execução registrada', Idioma.en: 'No execution recorded'},
    'mp_last_executions': {Idioma.pt: 'Últimas Execuções', Idioma.en: 'Latest Executions'},
    'mp_last_execution': {Idioma.pt: 'Última Execução', Idioma.en: 'Last Execution'},
    'mp_next_execution': {Idioma.pt: 'Próxima Execução', Idioma.en: 'Next Execution'},
    'mp_total_times': {Idioma.pt: 'vezes', Idioma.en: 'times'},
    'mp_conclude_execution': {Idioma.pt: 'Concluir Execução', Idioma.en: 'Complete Execution'},
    'mp_detailed_history': {Idioma.pt: 'Histórico Detalhado', Idioma.en: 'Detailed History'},
    'mp_conclude_title': {Idioma.pt: 'Concluir execução', Idioma.en: 'Complete execution'},
    'mp_done_what': {Idioma.pt: 'O que foi feito?', Idioma.en: 'What was done?'},
    'mp_done_hint': {Idioma.pt: 'Ex: Troca de peça e testes finais', Idioma.en: 'Ex: Part replacement and final tests'},
    'mp_additional_comments': {Idioma.pt: 'Comentários adicionais', Idioma.en: 'Additional comments'},
    'mp_comments_hint': {
      Idioma.pt: 'Ex: Necessário acompanhamento próximas 2 semanas',
      Idioma.en: 'Ex: Follow-up needed for next 2 weeks',
    },
    'mp_real_cost_optional': {Idioma.pt: 'Custo real (opcional)', Idioma.en: 'Actual cost (optional)'},
    'mp_execution_saved': {Idioma.pt: 'Execução registrada com sucesso', Idioma.en: 'Execution saved successfully'},
    'mp_execution_error': {Idioma.pt: 'Erro ao registrar execução', Idioma.en: 'Error saving execution'},

    // Manutencao Preventiva Lista
    'mp_list_title': {Idioma.pt: 'Manutenções Preventivas', Idioma.en: 'Preventive Maintenance'},
    'mp_list_filters': {Idioma.pt: 'Filtros', Idioma.en: 'Filters'},
    'mp_list_filter_status_title': {Idioma.pt: 'Por Status', Idioma.en: 'By Status'},
    'mp_list_filter_location_title': {Idioma.pt: 'Por Local', Idioma.en: 'By Location'},
    'mp_list_filter_all': {Idioma.pt: 'Todas', Idioma.en: 'All'},
    'mp_list_filter_general': {Idioma.pt: '🏢 Geral/Condomínio', Idioma.en: '🏢 General/Condo'},
    'mp_list_filter_apartment': {Idioma.pt: '🏠 Apartamento', Idioma.en: '🏠 Apartment'},
    'mp_list_search_hint': {Idioma.pt: 'Buscar manutenção...', Idioma.en: 'Search maintenance...'},
    'mp_list_status_active': {Idioma.pt: 'Ativas', Idioma.en: 'Active'},
    'mp_list_status_alert': {Idioma.pt: 'Com Alerta', Idioma.en: 'With Alert'},
    'mp_list_status_overdue': {Idioma.pt: 'Vencidas', Idioma.en: 'Overdue'},
    'mp_list_total': {Idioma.pt: 'Total', Idioma.en: 'Total'},
    'mp_list_summary': {Idioma.pt: 'Resumo', Idioma.en: 'Summary'},
    'mp_list_general_title': {Idioma.pt: '🏢 MANUTENÇÕES GERAIS/CONDOMÍNIO', Idioma.en: '🏢 GENERAL/CONDO MAINTENANCE'},
    'mp_list_general_subtitle': {Idioma.pt: 'Afetam todo o prédio', Idioma.en: 'Affect the whole building'},
    'mp_list_apartment_title': {Idioma.pt: '🏠 MANUTENÇÕES DE APARTAMENTOS', Idioma.en: '🏠 APARTMENT MAINTENANCE'},
    'mp_list_apartment_subtitle': {Idioma.pt: 'Específicas de unidades', Idioma.en: 'Unit-specific'},
    'mp_list_status_badge_overdue': {Idioma.pt: 'VENCIDA', Idioma.en: 'OVERDUE'},
    'mp_list_status_badge_alert': {Idioma.pt: 'ALERTA', Idioma.en: 'ALERT'},
    'mp_list_status_badge_active': {Idioma.pt: 'ATIVA', Idioma.en: 'ACTIVE'},
    'mp_list_type_general_badge': {Idioma.pt: 'GERAL', Idioma.en: 'GENERAL'},
    'mp_list_type_apartment_badge': {Idioma.pt: 'APARTAMENTO', Idioma.en: 'APARTMENT'},
    'mp_list_location_condo': {Idioma.pt: 'Condomínio', Idioma.en: 'Condominium'},
    'mp_list_location_apartment': {Idioma.pt: 'Apartamento', Idioma.en: 'Apartment'},
    'mp_list_type_label': {Idioma.pt: 'Tipo:', Idioma.en: 'Type:'},
    'mp_list_frequency_label': {Idioma.pt: 'Frequência:', Idioma.en: 'Frequency:'},
    'mp_list_responsible_label': {Idioma.pt: 'Responsável:', Idioma.en: 'Responsible:'},
    'mp_list_next_in': {Idioma.pt: 'Próximo em', Idioma.en: 'Next in'},
    'mp_list_estimated_cost': {Idioma.pt: 'Custo Estimado', Idioma.en: 'Estimated Cost'},
    'mp_list_conclude_execution': {Idioma.pt: 'Concluir Execução', Idioma.en: 'Complete Execution'},
    'mp_list_dialog_title': {Idioma.pt: 'Concluir execução', Idioma.en: 'Complete execution'},
    'mp_list_dialog_description_label': {
      Idioma.pt: 'Descreva o que foi feito (opcional)',
      Idioma.en: 'Describe what was done (optional)',
    },
    'mp_list_dialog_description_hint': {
      Idioma.pt: 'Ex: Troca de peça e testes finais',
      Idioma.en: 'e.g. Part replacement and final tests',
    },
    'mp_list_dialog_cost_label': {Idioma.pt: 'Custo real (opcional)', Idioma.en: 'Actual cost (optional)'},
    'mp_list_dialog_cost_hint': {Idioma.pt: '0,00', Idioma.en: '0.00'},
    'mp_list_dialog_confirm': {Idioma.pt: 'Concluir', Idioma.en: 'Complete'},
    'mp_list_empty_title': {Idioma.pt: 'Nenhuma manutenção encontrada', Idioma.en: 'No maintenance found'},
    'mp_list_empty_subtitle': {
      Idioma.pt: 'Ajuste os filtros para ver resultados',
      Idioma.en: 'Adjust filters to see results',
    },
    'mp_list_days_late_prefix': {Idioma.pt: 'Atrasado', Idioma.en: 'Late'},
    'mp_list_days_today': {Idioma.pt: 'Hoje', Idioma.en: 'Today'},
    'mp_list_days_tomorrow': {Idioma.pt: 'Amanhã', Idioma.en: 'Tomorrow'},
    'mp_list_days_in_prefix': {Idioma.pt: 'Em', Idioma.en: 'In'},
    'mp_list_days_suffix': {Idioma.pt: 'dias', Idioma.en: 'days'},

    // Manage Apartment Items
    'manage_items_title': {Idioma.pt: 'Gerenciar Itens', Idioma.en: 'Manage Items'},
    'manage_items_subtitle': {
      Idioma.pt: 'Adicione itens de patrimônio aos apartamentos',
      Idioma.en: 'Add heritage items to apartments',
    },
    'apartment': {Idioma.pt: 'Apartamento', Idioma.en: 'Apartment'},
    'select_apartment': {Idioma.pt: 'Escolha um apartamento...', Idioma.en: 'Choose an apartment...'},
    'item_name': {Idioma.pt: 'Nome do Item', Idioma.en: 'Item Name'},
    'description_optional': {Idioma.pt: 'Descrição (opcional)', Idioma.en: 'Description (optional)'},
    'save_item': {Idioma.pt: 'Salvar Item', Idioma.en: 'Save Item'},
    'required_field': {Idioma.pt: 'Campo obrigatório', Idioma.en: 'Required field'},
    'item_success': {Idioma.pt: 'Item adicionado com sucesso!', Idioma.en: 'Item added successfully!'},
    'item_error': {Idioma.pt: 'Erro ao salvar item', Idioma.en: 'Error saving item'},
    'loading_apartments': {Idioma.pt: 'Carregando apartamentos...', Idioma.en: 'Loading apartments...'},
    'no_apartments': {Idioma.pt: 'Nenhum apartamento disponível', Idioma.en: 'No apartments available'},
    'link_apartment_subtitle': {
      Idioma.pt: 'Vincule um usuário a um apartamento',
      Idioma.en: 'Link a user to an apartment',
    },
    'link_apartment': {Idioma.pt: 'Vincular Apartamento', Idioma.en: 'Link Apartment'},
    'link_success': {Idioma.pt: 'Apartamento vinculado com sucesso!', Idioma.en: 'Apartment linked successfully!'},
    'link_error': {Idioma.pt: 'Erro ao vincular apartamento', Idioma.en: 'Error linking apartment'},
    'user': {Idioma.pt: 'Usuário', Idioma.en: 'User'},

    // Register
    'register_create_account': {Idioma.pt: 'Criar Conta', Idioma.en: 'Create Account'},
    'register_fill_data': {
      Idioma.pt: 'Preencha os dados abaixo para registrar',
      Idioma.en: 'Fill in the data below to register',
    },
    'register_full_name': {Idioma.pt: 'Nome Completo', Idioma.en: 'Full Name'},
    'register_username': {Idioma.pt: 'Nome de Usuário', Idioma.en: 'Username'},
    'register_phone': {Idioma.pt: 'Telefone', Idioma.en: 'Phone'},
    'register_password': {Idioma.pt: 'Senha', Idioma.en: 'Password'},
    'register_confirm_password': {Idioma.pt: 'Confirmar Senha', Idioma.en: 'Confirm Password'},
    'register_accept_terms': {
      Idioma.pt: 'Você deve aceitar os termos de serviço',
      Idioma.en: 'You must accept the terms of service',
    },
    'register_success': {Idioma.pt: 'Registro realizado com sucesso!', Idioma.en: 'Registration successful!'},
    'register_error': {Idioma.pt: 'Erro ao registrar', Idioma.en: 'Registration error'},
    'register_name_required': {Idioma.pt: 'Nome é obrigatório', Idioma.en: 'Name is required'},
    'register_name_min_length': {
      Idioma.pt: 'Nome deve ter pelo menos 3 caracteres',
      Idioma.en: 'Name must have at least 3 characters',
    },
    'register_button': {Idioma.pt: 'Registrar', Idioma.en: 'Register'},
    'register_already_have_account': {Idioma.pt: 'Já tem uma conta?', Idioma.en: 'Already have an account?'},
    'register_login_link': {Idioma.pt: 'Faça login aqui', Idioma.en: 'Login here'},

    // Forgot Password
    'forgot_password_title': {Idioma.pt: 'Recuperar Senha', Idioma.en: 'Recover Password'},
    'forgot_password_step1_label': {Idioma.pt: 'Nome de Usuário ou Telefone', Idioma.en: 'Username or Phone'},
    'forgot_password_step1_button': {Idioma.pt: 'Solicitar Código', Idioma.en: 'Request Code'},
    'forgot_password_step2_title': {Idioma.pt: 'Verificação de Código', Idioma.en: 'Code Verification'},
    'forgot_password_step2_label': {Idioma.pt: 'Código de Verificação', Idioma.en: 'Verification Code'},
    'forgot_password_step2_button': {Idioma.pt: 'Verificar Código', Idioma.en: 'Verify Code'},
    'forgot_password_step3_title': {Idioma.pt: 'Nova Senha', Idioma.en: 'New Password'},
    'forgot_password_step3_password': {Idioma.pt: 'Nova Senha', Idioma.en: 'New Password'},
    'forgot_password_step3_confirm': {Idioma.pt: 'Confirmar Senha', Idioma.en: 'Confirm Password'},
    'forgot_password_step3_button': {Idioma.pt: 'Alterar Senha', Idioma.en: 'Change Password'},
    'forgot_password_resend': {Idioma.pt: 'Reenviar em {segundos}s', Idioma.en: 'Resend in {seconds}s'},
    'forgot_password_sms_sent': {Idioma.pt: 'SMS enviado', Idioma.en: 'SMS sent'},
    'forgot_password_error_invalid_login': {
      Idioma.pt: 'Digite um nome de login válido',
      Idioma.en: 'Enter a valid username',
    },

    // Dashboard
    'dashboard_title': {Idioma.pt: 'Dashboard', Idioma.en: 'Dashboard'},
    'dashboard_welcome': {Idioma.pt: 'Bem-vindo', Idioma.en: 'Welcome'},
    'dashboard_statistics': {Idioma.pt: 'Estatísticas', Idioma.en: 'Statistics'},
    'dashboard_recent_activity': {Idioma.pt: 'Atividade Recente', Idioma.en: 'Recent Activity'},
    'dashboard_no_activity': {Idioma.pt: 'Nenhuma atividade recente', Idioma.en: 'No recent activity'},

    // Maintenance List (Core)
    'maintenance_list_title': {Idioma.pt: 'Solicitações de Manutenção', Idioma.en: 'Maintenance Requests'},
    'maintenance_list_search': {Idioma.pt: 'Buscar solicitação...', Idioma.en: 'Search request...'},
    'maintenance_list_pending': {Idioma.pt: 'Pendente', Idioma.en: 'Pending'},
    'maintenance_list_in_progress': {Idioma.pt: 'Em Andamento', Idioma.en: 'In Progress'},
    'maintenance_list_completed': {Idioma.pt: 'Concluído', Idioma.en: 'Completed'},
    'maintenance_list_empty': {Idioma.pt: 'Nenhuma solicitação encontrada', Idioma.en: 'No requests found'},
    'maintenance_detail_title': {Idioma.pt: 'Detalhes da Solicitação', Idioma.en: 'Request Details'},
    'maintenance_detail_description': {Idioma.pt: 'Descrição', Idioma.en: 'Description'},
    'maintenance_detail_status': {Idioma.pt: 'Status', Idioma.en: 'Status'},
    'maintenance_detail_created': {Idioma.pt: 'Criado em', Idioma.en: 'Created on'},

    // Apartments
    'apartments_list_title': {Idioma.pt: 'Apartamentos', Idioma.en: 'Apartments'},
    'apartments_list_available': {Idioma.pt: 'Disponível', Idioma.en: 'Available'},
    'apartments_list_occupied': {Idioma.pt: 'Ocupado', Idioma.en: 'Occupied'},
    'apartments_list_maintenance': {Idioma.pt: 'Manutenção', Idioma.en: 'Maintenance'},
    'apartments_list_empty': {Idioma.pt: 'Nenhum apartamento encontrado', Idioma.en: 'No apartments found'},
    'apartments_detail_title': {Idioma.pt: 'Detalhes do Apartamento', Idioma.en: 'Apartment Details'},
    'apartments_detail_residents': {Idioma.pt: 'Moradores', Idioma.en: 'Residents'},
    'apartments_create_title': {Idioma.pt: 'Novo Apartamento', Idioma.en: 'New Apartment'},
    'apartments_number': {Idioma.pt: 'Número', Idioma.en: 'Number'},
    'apartments_block': {Idioma.pt: 'Bloco', Idioma.en: 'Block'},
    'apartments_floor': {Idioma.pt: 'Andar', Idioma.en: 'Floor'},

    // Schedules (Agendamentos)
    'schedule_list_title': {Idioma.pt: 'Agendamentos', Idioma.en: 'Schedules'},
    'schedule_detail_title': {Idioma.pt: 'Detalhes do Agendamento', Idioma.en: 'Schedule Details'},
    'schedule_create_title': {Idioma.pt: 'Novo Agendamento', Idioma.en: 'New Schedule'},
    'schedule_date': {Idioma.pt: 'Data', Idioma.en: 'Date'},
    'schedule_time': {Idioma.pt: 'Hora', Idioma.en: 'Time'},
    'schedule_empty': {Idioma.pt: 'Nenhum agendamento encontrado', Idioma.en: 'No schedules found'},

    // Users
    'users_list_title': {Idioma.pt: 'Usuários', Idioma.en: 'Users'},
    'users_add_title': {Idioma.pt: 'Novo Usuário', Idioma.en: 'New User'},
    'users_detail_title': {Idioma.pt: 'Detalhes do Usuário', Idioma.en: 'User Details'},
    'users_role': {Idioma.pt: 'Função', Idioma.en: 'Role'},
    'users_active': {Idioma.pt: 'Ativo', Idioma.en: 'Active'},
    'users_inactive': {Idioma.pt: 'Inativo', Idioma.en: 'Inactive'},

    // Profile
    'profile_title': {Idioma.pt: 'Meu Perfil', Idioma.en: 'My Profile'},
    'profile_edit': {Idioma.pt: 'Editar Perfil', Idioma.en: 'Edit Profile'},
    'profile_name': {Idioma.pt: 'Nome', Idioma.en: 'Name'},
    'profile_email': {Idioma.pt: 'Email', Idioma.en: 'Email'},
    'profile_phone': {Idioma.pt: 'Telefone', Idioma.en: 'Phone'},

    // Notifications
    'notifications_title': {Idioma.pt: 'Notificações', Idioma.en: 'Notifications'},
    'notifications_empty': {Idioma.pt: 'Nenhuma notificação', Idioma.en: 'No notifications'},
    'notifications_mark_read': {Idioma.pt: 'Marcar como lido', Idioma.en: 'Mark as read'},

    // Reports
    'reports_title': {Idioma.pt: 'Relatórios', Idioma.en: 'Reports'},
    'reports_generate': {Idioma.pt: 'Gerar Relatório', Idioma.en: 'Generate Report'},
    'reports_date_range': {Idioma.pt: 'Período', Idioma.en: 'Period'},

    // Generic Actions
    'action_save': {Idioma.pt: 'Salvar', Idioma.en: 'Save'},
    'action_delete': {Idioma.pt: 'Excluir', Idioma.en: 'Delete'},
    'action_edit': {Idioma.pt: 'Editar', Idioma.en: 'Edit'},
    'action_create': {Idioma.pt: 'Criar', Idioma.en: 'Create'},
    'action_back': {Idioma.pt: 'Voltar', Idioma.en: 'Back'},
    'action_yes': {Idioma.pt: 'Sim', Idioma.en: 'Yes'},
    'action_no': {Idioma.pt: 'Não', Idioma.en: 'No'},
    'success_saved': {Idioma.pt: 'Salvo com sucesso', Idioma.en: 'Saved successfully'},
    'success_deleted': {Idioma.pt: 'Excluído com sucesso', Idioma.en: 'Deleted successfully'},
    'error_generic': {Idioma.pt: 'Ocorreu um erro', Idioma.en: 'An error occurred'},
    'error_connection': {Idioma.pt: 'Erro de conexão', Idioma.en: 'Connection error'},
    'error_timeout': {Idioma.pt: 'Tempo limite excedido', Idioma.en: 'Request timeout'},
  };

  String text(String key) {
    return _texts[key]?[idioma] ?? _texts[key]?[Idioma.pt] ?? key;
  }
}
