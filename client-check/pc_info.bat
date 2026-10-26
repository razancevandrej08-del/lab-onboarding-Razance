@echo off
chcp 65001 > nul

REM =================================================================
REM Тема: Инструментальные средства ревьюирования, проверки на стороне клиента.
REM Выполнил: Фамилия
REM Дата: 26.10.2026
REM =================================================================

REM Установка пути к файлу отчета в папке скрипта
set "REPORT_FILE=%~dp0pc_report.txt"

REM Очищаем файл отчета, если он существовал, и пишем заголовок
echo ========================================== > "%REPORT_FILE%"
echo   ОТЧЕТ О ДИАГНОСТИКЕ КЛИЕНТСКОГО КОМПЬЮТЕРА >> "%REPORT_FILE%"
echo ========================================== >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

REM =================================================================
REM БЛОК 2: Вывод заголовка в консоль
REM =================================================================
cls
echo ==========================================
echo       ДИАГНОСТИКА КОМПЬЮТЕРА
echo ==========================================
echo.

REM =================================================================
REM БЛОК 3: Сведения об операционной системе
REM =================================================================
echo [Операционная система]
echo [Операционная система] >> "%REPORT_FILE%"

for /f "tokens=2 delims==" %%i in ('wmic os get Caption /value 2^>nul') do (
    if not "%%i"=="" (
        echo Название: %%i
        echo Название: %%i >> "%REPORT_FILE%"
    )
)
for /f "tokens=2 delims==" %%i in ('wmic os get Version /value 2^>nul') do (
    if not "%%i"=="" (
        echo Версия:   %%i
        echo Версия:   %%i >> "%REPORT_FILE%"
    )
)
echo.
echo. >> "%REPORT_FILE%"

REM =================================================================
REM БЛОК 4: Сведения об обработчике (Процессор)
REM =================================================================
echo [Процессор]
echo [Процессор] >> "%REPORT_FILE%"

for /f "tokens=2 delims==" %%i in ('wmic cpu get Name /value 2^>nul') do (
    if not "%%i"=="" (
        echo Модель: %%i
        echo Модель: %%i >> "%REPORT_FILE%"
    )
)
echo.
echo. >> "%REPORT_FILE%"

REM =================================================================
REM БЛОК 5: Сведения об оперативной памяти
REM =================================================================
echo [Оперативная память]
echo [Оперативная память] >> "%REPORT_FILE%"

for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /value 2^>nul') do (
    set "total_kb=%%i"
)
for /f "tokens=2 delims==" %%i in ('wmic os get FreePhysicalMemory /value 2^>nul') do (
    set "free_kb=%%i"
)

REM Перевод из КБ в ГБ (деление на 1048576)
set /a total_gb=%total_kb% / 1048576
set /a free_gb=%free_kb% / 1048576

echo Всего памяти:    %total_gb% ГБ
echo Свободно памяти: %free_gb% ГБ
echo Всего памяти:    %total_gb% ГБ >> "%REPORT_FILE%"
echo Свободно памяти: %free_gb% ГБ >> "%REPORT_FILE%"
echo.
echo. >> "%REPORT_FILE%"

REM =================================================================
REM БЛОК 6: Свободное место на диске C
REM =================================================================
echo [Диск C]
echo [Диск C] >> "%REPORT_FILE%"

for /f "tokens=2 delims==" %%i in ('wmic logicaldisk where "DeviceID='C:'" get Size /value 2^>nul') do (
    set "disk_size_b=%%i"
)
for /f "tokens=2 delims==" %%i in ('wmic logicaldisk where "DeviceID='C:'" get FreeSpace /value 2^>nul') do (
    set "disk_free_b=%%i"
)

REM Перевод из Байт в ГБ (разбиваем число, так как 32-битный cmd не переваривает числа больше 2 млрд напрямую)
REM Используем обходной путь деления больших чисел через отсечение последних 6 знаков (деление на 1000000)
set "size_trimmed=%disk_size_b:~0,-6%"
set "free_trimmed=%disk_free_b:~0,-6%"
set /a disk_size_gb=%size_trimmed% / 1073
set /a disk_free_gb=%free_trimmed% / 1073

echo Общий размер диска C: %disk_size_gb% ГБ
echo Свободно на диске C:  %disk_free_gb% ГБ
echo Общий размер диска C: %disk_size_gb% ГБ >> "%REPORT_FILE%"
echo Свободно на диске C:  %disk_free_gb% ГБ >> "%REPORT_FILE%"
echo.
echo. >> "%REPORT_FILE%"

REM =================================================================
REM БЛОК 7: Список установленных программ (Через реестр)
REM =================================================================
echo [Установленные программы]
echo [Установленные программы] >> "%REPORT_FILE%"

REM Поиск в 64-битном разделе реестра
for /f "tokens=2,*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /f DisplayName 2^>nul ^| findstr "DisplayName"') do (
    echo %%b
    echo %%b >> "%REPORT_FILE%"
)

REM Поиск в 32-битном разделе реестра (WOW6432Node)
for /f "tokens=2,*" %%a in ('reg query "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /f DisplayName 2^>nul ^| findstr "DisplayName"') do (
    echo %%b
    echo %%b >> "%REPORT_FILE%"
)

echo.
echo. >> "%REPORT_FILE%"
echo ==========================================
echo Отчёт сохранён в файл pc_report.txt
echo ==========================================
echo.

REM =================================================================
REM БЛОК 10: Фиксация окна
REM =================================================================
pause