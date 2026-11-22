@echo off
chcp 65001 > nul
setlocal

REM Практическая работа: диагностика клиентского компьютера
REM Выполнил: Андрей Рязанцев
REM Дата: 22.11.2026

set "REPORT_FILE=%~dp0pc_report.txt"
set "OS_NAME=не удалось получить данные"
set "OS_VERSION=не удалось получить данные"
set "CPU_NAME=не удалось получить данные"
set "TOTAL_GB=не удалось получить данные"
set "FREE_GB=не удалось получить данные"
set "DISK_SIZE_GB=не удалось получить данные"
set "DISK_FREE_GB=не удалось получить данные"

REM Получаем сведения об операционной системе и процессоре
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption" 2^>nul') do set "OS_NAME=%%A"
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Version" 2^>nul') do set "OS_VERSION=%%A"
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)" 2^>nul') do set "CPU_NAME=%%A"

REM Получаем общий и свободный объём оперативной памяти в ГБ
for /f "delims=" %%A in ('powershell -NoProfile -Command "[math]::Floor((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize/1MB)" 2^>nul') do set "TOTAL_GB=%%A"
for /f "delims=" %%A in ('powershell -NoProfile -Command "[math]::Floor((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB)" 2^>nul') do set "FREE_GB=%%A"

REM Получаем размер диска C и свободное место в ГБ
for /f "delims=" %%A in ('powershell -NoProfile -Command "[math]::Floor(((Get-PSDrive -Name C).Used+(Get-PSDrive -Name C).Free)/1GB)" 2^>nul') do set "DISK_SIZE_GB=%%A"
for /f "delims=" %%A in ('powershell -NoProfile -Command "[math]::Floor((Get-PSDrive -Name C).Free/1GB)" 2^>nul') do set "DISK_FREE_GB=%%A"

REM Создаём новый отчёт рядом со скриптом
> "%REPORT_FILE%" echo Диагностика компьютера
>> "%REPORT_FILE%" echo ========================================

echo Диагностика компьютера
echo ========================================
echo.

echo Операционная система
echo Название: %OS_NAME%
echo Версия: %OS_VERSION%
echo Операционная система >> "%REPORT_FILE%"
echo Название: %OS_NAME% >> "%REPORT_FILE%"
echo Версия: %OS_VERSION% >> "%REPORT_FILE%"
echo.
echo. >> "%REPORT_FILE%"

echo Процессор
echo Модель: %CPU_NAME%
echo Процессор >> "%REPORT_FILE%"
echo Модель: %CPU_NAME% >> "%REPORT_FILE%"
echo.
echo. >> "%REPORT_FILE%"

echo Оперативная память
echo Всего памяти: %TOTAL_GB% ГБ
echo Свободно памяти: %FREE_GB% ГБ
echo Оперативная память >> "%REPORT_FILE%"
echo Всего памяти: %TOTAL_GB% ГБ >> "%REPORT_FILE%"
echo Свободно памяти: %FREE_GB% ГБ >> "%REPORT_FILE%"
echo.
echo. >> "%REPORT_FILE%"

echo Диск C
echo Общий размер: %DISK_SIZE_GB% ГБ
echo Свободно: %DISK_FREE_GB% ГБ
echo Диск C >> "%REPORT_FILE%"
echo Общий размер: %DISK_SIZE_GB% ГБ >> "%REPORT_FILE%"
echo Свободно: %DISK_FREE_GB% ГБ >> "%REPORT_FILE%"
echo.
echo. >> "%REPORT_FILE%"

REM Читаем названия программ из 64- и 32-битных разделов реестра
echo Установленные программы
echo Установленные программы >> "%REPORT_FILE%"

for /f "tokens=1,2,*" %%A in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do if not "%%C"=="" (echo %%C&echo %%C >> "%REPORT_FILE%")

for /f "tokens=1,2,*" %%A in ('reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do if not "%%C"=="" (echo %%C&echo %%C >> "%REPORT_FILE%")

echo.
echo Отчёт сохранён в файле pc_report.txt
echo Отчёт сохранён в файле pc_report.txt >> "%REPORT_FILE%"
pause
endlocal
