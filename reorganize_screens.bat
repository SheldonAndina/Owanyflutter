@echo off
cd lib\screens

REM Copy core screens
copy dashboard_screen.dart core\
copy maintenance_list_screen.dart core\
copy maintenance_detail_screen.dart core\
copy maintenance_request_screen.dart core\
copy notifications_screen.dart core\

REM Copy apartment screens
copy apartments_screen.dart apartments\
copy apartment_detail_screen.dart apartments\
copy create_apartment_screen.dart apartments\
copy manage_apartment_items_screen.dart apartments\

REM Copy user screens
copy users_screen.dart users\
copy user_detail_screen.dart users\
copy add_user_screen.dart users\
copy edit_user_screen.dart users\
copy manage_residents_screen.dart users\

REM Copy utility screens
copy profile_screen.dart utility\
copy settings_screen.dart utility\
copy morador_detail_screen.dart utility\

echo Screens reorganizados com sucesso!
pause
