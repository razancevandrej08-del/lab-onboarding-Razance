@echo off
chcp 65001 > nul
setlocal

REM Практическая работа 8, часть 2: аудит клиентского компьютера
REM Выполнил: Андрей Рязанцев

set "REPORT_FILE=%~dp0pc_report.txt"
set "APPS_FILE=%TEMP%\client_apps_%RANDOM%.txt"
set "MATCH_FILE=%TEMP%\client_matches_%RANDOM%.txt"

set "OS_NAME="
set "OS_VERSION="
set "CPU_NAME="
set "TOTAL_GB="
set "FREE_GB="
set "DISK_SIZE_GB="
set "DISK_FREE_GB="
set "CHECKED=0"
set "RECOMMENDATIONS=0"
set "APPS_COUNT=0"

REM Начинаем новый отчёт
type nul > "%REPORT_FILE%"

REM Получаем дату и время запуска
set "RUN_DATE="
for /f "delims=" %%A in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'" 2^>nul') do set "RUN_DATE=%%A"
if not defined RUN_DATE set "RUN_DATE=не удалось получить дату и время"

call :log "АУДИТ КЛИЕНТСКОГО КОМПЬЮТЕРА"
call :log "Дата и время проверки: %RUN_DATE%"
call :log "=========================================="
call :log ""

REM Получаем сведения об операционной системе
echo Получение сведений об операционной системе...
set "OS_NAME="
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption" 2^>nul') do set "OS_NAME=%%A"
if not defined OS_NAME set "OS_NAME=не удалось получить данные"

set "OS_VERSION="
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Version" 2^>nul') do set "OS_VERSION=%%A"
if not defined OS_VERSION set "OS_VERSION=не удалось получить данные"

REM Получаем модель процессора
echo Получение сведений о процессоре...
set "CPU_NAME="
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)" 2^>nul') do set "CPU_NAME=%%A"
if not defined CPU_NAME set "CPU_NAME=не удалось получить данные"

REM Получаем объём оперативной памяти в гигабайтах
echo Получение сведений об оперативной памяти...
set "TOTAL_GB="
for /f "delims=" %%A in ('powershell -NoProfile -Command "[math]::Floor((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize/1MB)" 2^>nul') do set "TOTAL_GB=%%A"
if not defined TOTAL_GB set "TOTAL_GB=не удалось получить данные"

set "FREE_GB="
for /f "delims=" %%A in ('powershell -NoProfile -Command "[math]::Floor((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB)" 2^>nul') do set "FREE_GB=%%A"
if not defined FREE_GB set "FREE_GB=не удалось получить данные"

REM Получаем размер и свободное место на диске C
echo Получение сведений о диске C...
set "DISK_SIZE_GB="
for /f "delims=" %%A in ('powershell -NoProfile -Command "$d=Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\"; if($d){[math]::Floor($d.Size/1GB)}" 2^>nul') do set "DISK_SIZE_GB=%%A"
if not defined DISK_SIZE_GB set "DISK_SIZE_GB=не удалось получить данные"

set "DISK_FREE_GB="
for /f "delims=" %%A in ('powershell -NoProfile -Command "$d=Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\"; if($d){[math]::Floor($d.FreeSpace/1GB)}" 2^>nul') do set "DISK_FREE_GB=%%A"
if not defined DISK_FREE_GB set "DISK_FREE_GB=не удалось получить данные"

call :log ""
call :log "СВЕДЕНИЯ О КОМПЬЮТЕРЕ"
call :log "Операционная система: %OS_NAME%"
call :log "Версия: %OS_VERSION%"
call :log "Процессор: %CPU_NAME%"
call :log "Всего оперативной памяти: %TOTAL_GB% ГБ"
call :log "Свободно оперативной памяти: %FREE_GB% ГБ"
call :log "Размер диска C: %DISK_SIZE_GB% ГБ"
call :log "Свободно на диске C: %DISK_FREE_GB% ГБ"
call :log ""

REM Собираем названия программ из обеих веток реестра:
REM обычной ветки и WOW6432Node для 32-битных программ.
echo Сбор списка установленных программ...
set "APPS_FILE=%APPS_FILE%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$roots=@('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'); $names=foreach($r in $roots){Get-ChildItem -LiteralPath $r -ErrorAction SilentlyContinue | ForEach-Object { (Get-ItemProperty -LiteralPath $_.PSPath -Name DisplayName -ErrorAction SilentlyContinue).DisplayName }}; $names | Where-Object { $_ } | Sort-Object -Unique | Set-Content -LiteralPath $env:APPS_FILE -Encoding UTF8" 2>nul

if not exist "%APPS_FILE%" type nul > "%APPS_FILE%"

for /f "usebackq delims=" %%P in ("%APPS_FILE%") do set /a APPS_COUNT+=1

call :log "СПИСОК УСТАНОВЛЕННЫХ ПРОГРАММ"
if "%APPS_COUNT%"=="0" (
    call :log "Не удалось получить список программ из реестра."
) else (
    for /f "usebackq delims=" %%P in ("%APPS_FILE%") do call :log "  %%P"
)
call :log ""

REM Проверяем базовые категории офисного программного обеспечения
call :log "ПРОВЕРКА БАЗОВОГО ОФИСНОГО ПО"
call :log "------------------------------------------"

set /a CHECKED+=1
findstr /i /c:"Office" /c:"LibreOffice" /c:"OpenOffice" /c:"МойОфис" "%APPS_FILE%" > "%MATCH_FILE%"
if errorlevel 1 (
    set /a RECOMMENDATIONS+=1
    call :log "Офисный пакет: не обнаружен. Рекомендуется установить Microsoft Office, LibreOffice или другой утверждённый пакет."
) else (
    call :log "Офисный пакет: требование выполнено. Найдено:"
    call :show_matches
)

set /a CHECKED+=1
findstr /i /c:"Chrome" /c:"Firefox" /c:"Microsoft Edge" /c:"Яндекс" "%APPS_FILE%" > "%MATCH_FILE%"
if errorlevel 1 (
    set /a RECOMMENDATIONS+=1
    call :log "Браузер: не обнаружен в списке программ. Рекомендуется проверить наличие и настройку браузера."
) else (
    call :log "Браузер: найден. Обратите внимание, что Edge может быть компонентом Windows. Найдено:"
    call :show_matches
)

set /a CHECKED+=1
findstr /i /c:"Acrobat" /c:"Foxit" /c:"SumatraPDF" /c:"PDF" "%APPS_FILE%" > "%MATCH_FILE%"
if errorlevel 1 (
    set /a RECOMMENDATIONS+=1
    call :log "Программа для PDF: не обнаружена. Рекомендуется установить PDF-просмотрщик, например Acrobat Reader, Foxit Reader или SumatraPDF."
) else (
    call :log "Программа для PDF: требование выполнено. Найдено:"
    call :show_matches
)

set /a CHECKED+=1
findstr /i /c:"7-Zip" /c:"WinRAR" /c:"WinZip" "%APPS_FILE%" > "%MATCH_FILE%"
if errorlevel 1 (
    set /a RECOMMENDATIONS+=1
    call :log "Архиватор: не обнаружен. Для работы с вложениями рекомендуется установить 7-Zip или WinRAR."
) else (
    call :log "Архиватор: требование выполнено. Найдено:"
    call :show_matches
)

set /a CHECKED+=1
findstr /i /c:"Defender" /c:"Kaspersky" /c:"ESET" /c:"Dr.Web" /c:"NOD32" /c:"Антивирус" "%APPS_FILE%" > "%MATCH_FILE%"
if errorlevel 1 (
    set /a RECOMMENDATIONS+=1
    call :log "Антивирус: не обнаружен в списке программ. Рекомендуется проверить состояние Microsoft Defender или корпоративного антивируса."
) else (
    call :log "Антивирус: найден в списке программ. Рекомендуется дополнительно проверить, что защита включена. Найдено:"
    call :show_matches
)

call :log ""
call :log "ПРОВЕРКА ПРОГРАММ, НЕ ОТНОСЯЩИХСЯ К БАЗОВЫМ ОФИСНЫМ ЗАДАЧАМ"
call :log "Результаты являются рекомендацией к проверке, а не указанием к удалению."
call :log "Решение принимает администратор с учётом потребностей организации."
call :log "------------------------------------------"

REM Группа 1: игры и игровые платформы
findstr /i /c:"Steam" /c:"Epic Games" /c:"GOG" /c:"Origin" /c:"Ubisoft Connect" /c:"Battle.net" /c:"Riot" /c:"game" /c:"gaming" "%APPS_FILE%" > "%MATCH_FILE%"
if errorlevel 1 (
    call :log "Игры и игровые платформы: совпадений не обнаружено."
) else (
    set /a RECOMMENDATIONS+=1
    call :log "Игры и игровые платформы: найдены программы для проверки:"
    call :show_matches
)

REM Группа 2: торрент-клиенты и файлообменные программы
findstr /i /c:"torrent" /c:"uTorrent" /c:"BitTorrent" /c:"qBittorrent" /c:"Vuze" "%APPS_FILE%" > "%MATCH_FILE%"
if errorlevel 1 (
    call :log "Торрент-клиенты и файлообменные программы: совпадений не обнаружено."
) else (
    set /a RECOMMENDATIONS+=1
    call :log "Торрент-клиенты и файлообменные программы: найдены программы для проверки:"
    call :show_matches
)

REM Группа 3: личные мессенджеры и приложения для общения
findstr /i /c:"Discord" /c:"Telegram" /c:"WhatsApp" /c:"Viber" /c:"Skype" "%APPS_FILE%" > "%MATCH_FILE%"
if errorlevel 1 (
    call :log "Мессенджеры и приложения для общения: совпадений не обнаружено."
) else (
    set /a RECOMMENDATIONS+=1
    call :log "Мессенджеры и приложения для общения: проверьте соответствие корпоративному стандарту:"
    call :show_matches
)

REM Группа 4: развлечения и оформление
findstr /i /c:"Wallpaper Engine" /c:"OBS" /c:"Soundpad" /c:"VLC" /c:"KMPlayer" /c:"PotPlayer" "%APPS_FILE%" > "%MATCH_FILE%"
if errorlevel 1 (
    call :log "Развлекательные программы и оформление: совпадений не обнаружено."
) else (
    set /a RECOMMENDATIONS+=1
    call :log "Развлекательные программы и оформление: найдены программы для проверки:"
    call :show_matches
)

call :log ""
call :log "ИТОГ ПРОВЕРКИ"
call :log "Проверено категорий базового ПО: %CHECKED%"
call :log "Рекомендаций для проверки: %RECOMMENDATIONS%"
call :log "Список обнаруженных программ: %APPS_COUNT%"
call :log "Полный путь к отчёту: %REPORT_FILE%"
call :log "Временные файлы будут удалены."

del "%APPS_FILE%" >nul 2>&1
del "%MATCH_FILE%" >nul 2>&1

echo.
echo Проверка завершена.
echo Отчёт сохранён: "%REPORT_FILE%"
pause
endlocal
exit /b

REM Подпрограмма: выводит строку на экран и записывает её в отчёт
:log
echo(%~1
>>"%REPORT_FILE%" echo(%~1
exit /b

REM Подпрограмма: выводит в отчёт и на экран найденные совпадения
:show_matches
for /f "usebackq delims=" %%P in ("%MATCH_FILE%") do call :log "  %%P"
exit /b
