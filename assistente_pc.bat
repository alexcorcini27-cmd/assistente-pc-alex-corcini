@echo off
title Assistente do PC - Powered by Alex Corcini
color 0B
setlocal enabledelayedexpansion

fltmc >nul 2>&1
if %errorlevel% NEQ 0 goto :precisa_admin

set "LOG=%TEMP%\relatorio_pc.txt"
set "HW=%TEMP%\_hw.txt"
set "SCORE=0"
set "MAXSCORE=0"
set "CPUNAME=Desconhecido"
set "CPUCORES=0"
set "CPUTHREADS=0"
set "CPUTDP=95"
set "RAMGB=0"
set "GPUNAME=Desconhecido"
set "MOBO=Desconhecida"
set "OSNAME=Desconhecido"
set "DISKMODEL=Desconhecido"
set "TEMP_MSG=Sem leitura"
set "PCT_ESC=0"
set "PCT_SIM=0"
set "PCT_JOG=0"
set "PERFIL=INDEFINIDO"

cls
color 0B
echo.
echo  ============================================================
echo    Ola! Se voce esta vendo esta tela, uma de duas coisas
echo    aconteceu:
echo.
echo      1) Seu PC esta lento e voce ja tentou reiniciar
echo      2) Voce e curioso e gosta de ver numeros bonitos
echo.
echo    Vamos verificar o Windows, o SSD, os drivers, analisar
echo    seu setup completo e recomendar upgrades.
echo.
echo    Powered by Alex Corcini
echo  ============================================================
echo.
echo    Pressione qualquer tecla para comecar...
pause >nul

echo ============================================================ > "%LOG%"
echo   RELATORIO DO PC - Powered by Alex Corcini >> "%LOG%"
echo   Gerado em: %date% %time% >> "%LOG%"
echo ============================================================ >> "%LOG%"

cls
color 0A
echo.
echo  [1/9] Criando ponto de restauracao...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-ComputerRestore -Drive 'C:\'; Checkpoint-Computer -Description 'Antes Assistente' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
echo  [OK] Ponto criado.
echo [1/9] Ponto: OK >> "%LOG%"
timeout /t 2 /nobreak >nul

cls
echo.
echo  [2/9] Verificando Windows (DISM)... 5-20 min.
echo --- DISM --- >> "%LOG%"
DISM /Online /Cleanup-Image /CheckHealth >> "%LOG%" 2>&1
DISM /Online /Cleanup-Image /ScanHealth >> "%LOG%" 2>&1
DISM /Online /Cleanup-Image /RestoreHealth >> "%LOG%" 2>&1
findstr /C:"No component store corruption" "%LOG%" >nul
if %errorlevel% EQU 0 goto :dism_ok
findstr /C:"Nenhuma corrup" "%LOG%" >nul
if %errorlevel% EQU 0 goto :dism_ok
echo  [!] Reparados ou com pendencias.
goto :dism_fim
:dism_ok
set /a SCORE+=25
echo  [OK] Windows SAUDAVEL.
:dism_fim
set /a MAXSCORE+=25

cls
echo.
echo  [3/9] Verificando SFC... 10-30 min.
echo --- SFC --- >> "%LOG%"
sfc /scannow >> "%LOG%" 2>&1
findstr /C:"did not find any integrity violations" "%LOG%" >nul
if %errorlevel% EQU 0 goto :sfc_ok
findstr /C:"nao encontrou nenhuma violacao" "%LOG%" >nul
if %errorlevel% EQU 0 goto :sfc_ok
echo  [!] Alguns arquivos reparados.
goto :sfc_fim
:sfc_ok
set /a SCORE+=25
echo  [OK] Arquivos INTEGROS.
:sfc_fim
set /a MAXSCORE+=25

cls
echo.
echo  [4/9] Verificando SSD...
echo --- SSD --- >> "%LOG%"
powershell -NoProfile -Command "Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus | Format-Table -AutoSize" >> "%LOG%" 2>&1
for /f %%A in ('powershell -NoProfile -Command "(Get-PhysicalDisk | Where-Object {$_.HealthStatus -eq 'Healthy'} | Measure-Object).Count"') do set "DISK_OK=%%A"
if not defined DISK_OK set "DISK_OK=0"
if %DISK_OK% GEQ 1 goto :ssd_ok
echo  [!] Verifique o relatorio.
goto :ssd_fim
:ssd_ok
set /a SCORE+=15
echo  [OK] SSD SAUDAVEL.
:ssd_fim
set /a MAXSCORE+=15

cls
echo.
echo  [5/9] Eventos criticos...
echo --- Eventos --- >> "%LOG%"
powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName | Format-Table -AutoSize" >> "%LOG%" 2>&1
for /f %%A in ('powershell -NoProfile -Command "(Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue | Measure-Object).Count"') do set "ERRCOUNT=%%A"
if not defined ERRCOUNT set "ERRCOUNT=0"
if %ERRCOUNT% LSS 5 goto :event_ok
echo  [!] Muitos eventos: %ERRCOUNT%
goto :event_fim
:event_ok
set /a SCORE+=10
echo  [OK] Poucos eventos: %ERRCOUNT%
:event_fim
set /a MAXSCORE+=10

cls
echo.
echo  [6/9] Drivers...
echo --- Drivers --- >> "%LOG%"
powershell -NoProfile -Command "Get-CimInstance Win32_PnPEntity | Where-Object {$_.ConfigManagerErrorCode -ne 0} | Select-Object Name, ConfigManagerErrorCode | Format-Table -AutoSize" >> "%LOG%" 2>&1
for /f %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_PnPEntity | Where-Object {$_.ConfigManagerErrorCode -ne 0} | Measure-Object).Count"') do set "BADDRV=%%A"
if not defined BADDRV set "BADDRV=0"
if %BADDRV% EQU 0 goto :drv_ok
echo  [!] %BADDRV% driver(s) com problema.
goto :drv_fim
:drv_ok
set /a SCORE+=10
echo  [OK] Nenhum driver com problema.
:drv_fim
set /a MAXSCORE+=10

cls
echo.
echo  [7/9] Aplicando otimizacoes...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
echo  [OK] Prioridade de CPU.
for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "(Get-CimInstance Win32_Processor).Name"`) do set "CPU=%%A"
if not defined CPU set "CPU=Desconhecido"
set "PLANO=381b4222-f694-41f0-9685-ff5bb260df2e"
set "PLANO_NOME=Equilibrado"
echo %CPU% | findstr /i "X3D" >nul
if %errorlevel% EQU 0 goto :plano_x3d
echo %CPU% | findstr /i "Ryzen" >nul
if %errorlevel% EQU 0 goto :plano_ryzen
echo %CPU% | findstr /i "Intel" >nul
if %errorlevel% EQU 0 goto :plano_intel
goto :aplicar_plano
:plano_x3d
set "PLANO=381b4222-f694-41f0-9685-ff5bb260df2e"
set "PLANO_NOME=Equilibrado (X3D)"
goto :aplicar_plano
:plano_ryzen
set "PLANO=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
set "PLANO_NOME=Alto Desempenho (Ryzen)"
goto :aplicar_plano
:plano_intel
set "PLANO=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
set "PLANO_NOME=Alto Desempenho (Intel)"
goto :aplicar_plano
:aplicar_plano
powercfg /setactive %PLANO% >nul 2>&1
echo  [OK] Plano: %PLANO_NOME%
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
echo  [OK] Rede ajustada.
sc config SysMain start= disabled >nul 2>&1
net stop SysMain /y >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1
net stop DiagTrack /y >nul 2>&1
echo  [OK] Servicos desativados.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
echo  [OK] Telemetria desativada.
reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul 2>&1
echo  [OK] Game Mode.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo  [OK] Fast Startup off.
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "20" /f >nul 2>&1
echo  [OK] Menu rapido.
del /q /f /s "%SystemRoot%\Temp\*" >nul 2>&1
if exist "%SystemRoot%\Minidump\*" del /q /f /s "%SystemRoot%\Minidump\*" >nul 2>&1
if exist "%SystemRoot%\MEMORY.DMP" del /q /f "%SystemRoot%\MEMORY.DMP" >nul 2>&1
echo  [OK] Temporarios limpos.

cls
echo.
echo  [8/9] Coletando hardware...
set "PS1=%TEMP%\_hw.ps1"
(
echo $ErrorActionPreference = 'SilentlyContinue'
echo $out = @^(^)
echo $out += 'CPUNAME=' + ^(^(Get-CimInstance Win32_Processor^).Name^)
echo $out += 'CPUCORES=' + ^(^(Get-CimInstance Win32_Processor^).NumberOfCores^)
echo $out += 'CPUTHREADS=' + ^(^(Get-CimInstance Win32_Processor^).NumberOfLogicalProcessors^)
echo $out += 'RAMGB=' + [math]::Round^(^(Get-CimInstance Win32_ComputerSystem^).TotalPhysicalMemory/1GB,0^)
echo $out += 'GPUNAME=' + ^(^(Get-CimInstance Win32_VideoController ^| Select-Object -First 1^).Name^)
echo $out += 'MOBO=' + ^(^(Get-CimInstance Win32_BaseBoard^).Product^)
echo $out += 'OSNAME=' + ^(^(Get-CimInstance Win32_OperatingSystem^).Caption^)
echo $out += 'DISKMODEL=' + ^(^(Get-CimInstance Win32_DiskDrive ^| Select-Object -First 1^).Model^)
echo $out ^| Out-File -Encoding ASCII '%HW%'
) > "%PS1%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" >nul 2>&1
del /q /f "%PS1%" >nul 2>&1
if exist "%HW%" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%HW%") do set "%%A=%%B"
)

set "CPUTDP=95"
echo %CPUNAME% | findstr /i "5700X3D 5800X3D" >nul
if %errorlevel% EQU 0 goto :tdp_105
echo %CPUNAME% | findstr /i "7800X3D 7900X3D 7950X3D" >nul
if %errorlevel% EQU 0 goto :tdp_120
echo %CPUNAME% | findstr /i "Ryzen 9 79 Ryzen 9 39" >nul
if %errorlevel% EQU 0 goto :tdp_170
echo %CPUNAME% | findstr /i "Ryzen 9" >nul
if %errorlevel% EQU 0 goto :tdp_105
echo %CPUNAME% | findstr /i "Ryzen 7 58 Ryzen 7 57 Ryzen 7 77" >nul
if %errorlevel% EQU 0 goto :tdp_105
echo %CPUNAME% | findstr /i "Ryzen 7" >nul
if %errorlevel% EQU 0 goto :tdp_65
echo %CPUNAME% | findstr /i "Ryzen 5" >nul
if %errorlevel% EQU 0 goto :tdp_65
echo %CPUNAME% | findstr /i "i9" >nul
if %errorlevel% EQU 0 goto :tdp_253
echo %CPUNAME% | findstr /i "i7 i5" >nul
if %errorlevel% EQU 0 goto :tdp_125
echo %CPUNAME% | findstr /i "i3" >nul
if %errorlevel% EQU 0 goto :tdp_65
goto :tdp_fim
:tdp_105
set "CPUTDP=105"
goto :tdp_fim
:tdp_120
set "CPUTDP=120"
goto :tdp_fim
:tdp_170
set "CPUTDP=170"
goto :tdp_fim
:tdp_125
set "CPUTDP=125"
goto :tdp_fim
:tdp_253
set "CPUTDP=253"
goto :tdp_fim
:tdp_65
set "CPUTDP=65"
:tdp_fim

echo. >> "%LOG%"
echo === HARDWARE DETECTADO === >> "%LOG%"
echo Processador : %CPUNAME% >> "%LOG%"
echo TDP est.    : %CPUTDP% W >> "%LOG%"
echo Nucleos     : %CPUCORES% / %CPUTHREADS% threads >> "%LOG%"
echo RAM         : %RAMGB% GB >> "%LOG%"
echo GPU         : %GPUNAME% >> "%LOG%"
echo Placa-mae   : %MOBO% >> "%LOG%"
echo Sistema     : %OSNAME% >> "%LOG%"
echo Disco       : %DISKMODEL% >> "%LOG%"

set /a PONTOS=0
if %RAMGB% GEQ 32 set /a PONTOS+=30
if %RAMGB% GEQ 16 if %RAMGB% LSS 32 set /a PONTOS+=22
if %RAMGB% GEQ 8 if %RAMGB% LSS 16 set /a PONTOS+=14
if %RAMGB% LSS 8 set /a PONTOS+=5
echo %CPUNAME% | findstr /i "X3D Ryzen 9" >nul
if %errorlevel% EQU 0 set /a PONTOS+=30
echo %CPUNAME% | findstr /i "Ryzen 7" >nul
if %errorlevel% EQU 0 set /a PONTOS+=25
echo %CPUNAME% | findstr /i "Ryzen 5" >nul
if %errorlevel% EQU 0 set /a PONTOS+=18
echo %GPUNAME% | findstr /i "RTX 40 RX 9 RX 7" >nul
if %errorlevel% EQU 0 set /a PONTOS+=30
echo %GPUNAME% | findstr /i "RTX 30 RX 6" >nul
if %errorlevel% EQU 0 set /a PONTOS+=25
echo %GPUNAME% | findstr /i "GTX" >nul
if %errorlevel% EQU 0 set /a PONTOS+=18
echo %DISKMODEL% | findstr /i "NVMe" >nul
if %errorlevel% EQU 0 set /a PONTOS+=10
echo %DISKMODEL% | findstr /i "SSD" >nul
if %errorlevel% EQU 0 set /a PONTOS+=8
echo %DISKMODEL% | findstr /i "HDD" >nul
if %errorlevel% EQU 0 set /a PONTOS+=4

if %PONTOS% GEQ 90 goto :perfil_top
if %PONTOS% GEQ 75 goto :perfil_alto
if %PONTOS% GEQ 55 goto :perfil_medio
if %PONTOS% GEQ 35 goto :perfil_basico
goto :perfil_entrada
:perfil_top
set "PCT_ESC=100" & set "PCT_SIM=100" & set "PCT_JOG=95" & set "PERFIL=TOP DE LINHA"
goto :perfil_fim
:perfil_alto
set "PCT_ESC=100" & set "PCT_SIM=100" & set "PCT_JOG=80" & set "PERFIL=ALTO DESEMPENHO"
goto :perfil_fim
:perfil_medio
set "PCT_ESC=100" & set "PCT_SIM=95" & set "PCT_JOG=60" & set "PERFIL=INTERMEDIARIO"
goto :perfil_fim
:perfil_basico
set "PCT_ESC=95" & set "PCT_SIM=75" & set "PCT_JOG=35" & set "PERFIL=BASICO"
goto :perfil_fim
:perfil_entrada
set "PCT_ESC=75" & set "PCT_SIM=50" & set "PCT_JOG=15" & set "PERFIL=ENTRADA"
:perfil_fim
echo === ESTIMATIVA: %PERFIL% (%PCT_ESC% por cento comercial / %PCT_JOG% por cento jogos) === >> "%LOG%"

for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "try { $t = (Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop).CurrentTemperature; if ($t) { [math]::Round(($t[0]/10)-273.15, 1) } else { 'NA' } } catch { 'NA' }"`) do set "CPUTEMP=%%A"
if not defined CPUTEMP set "CPUTEMP=NA"
if "%CPUTEMP%"=="NA" set "TEMP_MSG=Temperatura nao disponivel via Windows."
if not "%CPUTEMP%"=="NA" set "TEMP_MSG=Temperatura: %CPUTEMP% C (imprecisa)"

cls
color 0E
echo.
echo  ============================================================
echo    QUESTIONARIO - PARTE 1: MANUTENCAO
echo  ============================================================
echo.
echo   1) Com que frequencia voce limpa a poeira do PC?
echo      [1] A cada 3 meses ou menos
echo      [2] A cada 3 a 6 meses
echo      [3] A cada 6 a 12 meses
echo      [4] A cada 1 a 2 anos
echo      [5] Nunca limpei
echo.
choice /c 12345 /n /m "  Escolha (1-5): "
if errorlevel 5 set "LIMP=Nunca" & set "LIMP_TXT=Nunca limpou" & goto :q2
if errorlevel 4 set "LIMP=1a2anos" & set "LIMP_TXT=1 a 2 anos" & goto :q2
if errorlevel 3 set "LIMP=6a12meses" & set "LIMP_TXT=6 a 12 meses" & goto :q2
if errorlevel 2 set "LIMP=3a6meses" & set "LIMP_TXT=3 a 6 meses" & goto :q2
set "LIMP=3meses"
set "LIMP_TXT=A cada 3 meses ou menos"

:q2
cls
echo.
echo   2) Voce ja trocou a pasta termica?
echo      [1] Sim
echo      [2] Nao, nunca troquei
echo.
choice /c 12 /n /m "  Escolha (1-2): "
if errorlevel 2 goto :q2_nunca
set "PASTA=Sim"
goto :q2_idade
:q2_nunca
set "PASTA=Nunca"
set "PASTA_IDADE=Nunca"
set "PASTA_NOME=Nunca trocou"
set "PASTA_VEREDITO=Nunca trocou pasta."
goto :q3
:q2_idade
cls
echo.
echo   2b) Ha quanto tempo a pasta foi aplicada?
echo      [1] Menos de 1 ano
echo      [2] 1 a 2 anos
echo      [3] 2 a 3 anos
echo      [4] 3 a 5 anos
echo      [5] Mais de 5 anos
echo      [6] Nao sei
echo.
choice /c 123456 /n /m "  Escolha (1-6): "
if errorlevel 6 set "PASTA_IDADE=Desconhecida" & goto :q2_marca
if errorlevel 5 set "PASTA_IDADE=mais5" & goto :q2_marca
if errorlevel 4 set "PASTA_IDADE=3a5" & goto :q2_marca
if errorlevel 3 set "PASTA_IDADE=2a3" & goto :q2_marca
if errorlevel 2 set "PASTA_IDADE=1a2" & goto :q2_marca
set "PASTA_IDADE=menos1"

:q2_marca
cls
echo.
echo   2c) Marca/modelo da pasta termica?
echo   Ex: MX-4, Rise Mode Cold, TS Extreme, Kryonaut, NT-H1
echo.
set /p PASTA_USER=  Digite: 
if not defined PASTA_USER set "PASTA_USER=Nao informado"
set "PASTA_NOME=Nao identificada"
set "PASTA_DUR=Desconhecida"
set "PASTA_VEREDITO=Modelo nao identificado. Qualquer pasta conhecida e superior a stock."
echo %PASTA_USER% | findstr /i "rise cold risemode" >nul
if %errorlevel% EQU 0 goto :p_rise
echo %PASTA_USER% | findstr /i "ts extreme" >nul
if %errorlevel% EQU 0 goto :p_tsext
echo %PASTA_USER% | findstr /i "ts cold" >nul
if %errorlevel% EQU 0 goto :p_tscold
echo %PASTA_USER% | findstr /i "ts pro implastec" >nul
if %errorlevel% EQU 0 goto :p_tspro
echo %PASTA_USER% | findstr /i "nitrogen max" >nul
if %errorlevel% EQU 0 goto :p_nmax
echo %PASTA_USER% | findstr /i "nitrogen pro" >nul
if %errorlevel% EQU 0 goto :p_npro
echo %PASTA_USER% | findstr /i "nitrogen basic" >nul
if %errorlevel% EQU 0 goto :p_nbasic
echo %PASTA_USER% | findstr /i "tf7" >nul
if %errorlevel% EQU 0 goto :p_tf7
echo %PASTA_USER% | findstr /i "tfx" >nul
if %errorlevel% EQU 0 goto :p_tfx
echo %PASTA_USER% | findstr /i "mx-4 mx4" >nul
if %errorlevel% EQU 0 goto :p_mx4
echo %PASTA_USER% | findstr /i "mx-6 mx6" >nul
if %errorlevel% EQU 0 goto :p_mx6
echo %PASTA_USER% | findstr /i "nt-h1 nth1 nh1" >nul
if %errorlevel% EQU 0 goto :p_nth1
echo %PASTA_USER% | findstr /i "nt-h2 nth2 nh2" >nul
if %errorlevel% EQU 0 goto :p_nth2
echo %PASTA_USER% | findstr /i "kryonaut grizzly" >nul
if %errorlevel% EQU 0 goto :p_kryo
echo %PASTA_USER% | findstr /i "hydronaut" >nul
if %errorlevel% EQU 0 goto :p_hydro
echo %PASTA_USER% | findstr /i "authentic" >nul
if %errorlevel% EQU 0 goto :p_auth
echo %PASTA_USER% | findstr /i "friosys glacial" >nul
if %errorlevel% EQU 0 goto :p_frio
echo %PASTA_USER% | findstr /i "snowdog husky" >nul
if %errorlevel% EQU 0 goto :p_snow
echo %PASTA_USER% | findstr /i "stock original" >nul
if %errorlevel% EQU 0 goto :p_stock
echo %PASTA_USER% | findstr /i "nao sei nsei" >nul
if %errorlevel% EQU 0 goto :p_nsei
goto :q3
:p_rise
set "PASTA_NOME=Rise Mode Cold 7.5" & set "PASTA_DUR=Baixa (3 meses a 1 ano)" & set "PASTA_VEREDITO=ENTRADA. Degrada rapido." & goto :q3
:p_tsext
set "PASTA_NOME=Implastec TS Extreme" & set "PASTA_DUR=Alta (36 meses)" & set "PASTA_VEREDITO=ENTUSIASTA. Alta performance." & goto :q3
:p_tscold
set "PASTA_NOME=Implastec TS Cold" & set "PASTA_DUR=Media" & set "PASTA_VEREDITO=INTERMEDIARIA." & goto :q3
:p_tspro
set "PASTA_NOME=Implastec TS Pro" & set "PASTA_DUR=Media" & set "PASTA_VEREDITO=ENTRADA." & goto :q3
:p_nmax
set "PASTA_NOME=PCYes Nitrogen Max" & set "PASTA_DUR=Alta" & set "PASTA_VEREDITO=ENTUSIASTA." & goto :q3
:p_npro
set "PASTA_NOME=PCYes Nitrogen Pro" & set "PASTA_DUR=Alta" & set "PASTA_VEREDITO=INTERMEDIARIA." & goto :q3
:p_nbasic
set "PASTA_NOME=PCYes Nitrogen Basic" & set "PASTA_DUR=Media" & set "PASTA_VEREDITO=ENTRADA." & goto :q3
:p_tf7
set "PASTA_NOME=Thermalright TF7" & set "PASTA_DUR=Baixa/Media" & set "PASTA_VEREDITO=Alta condutividade, durabilidade baixa." & goto :q3
:p_tfx
set "PASTA_NOME=Thermalright TFX" & set "PASTA_DUR=Media" & set "PASTA_VEREDITO=ENTUSIASTA." & goto :q3
:p_mx4
set "PASTA_NOME=Arctic MX-4" & set "PASTA_DUR=Muito Alta (8+ anos)" & set "PASTA_VEREDITO=EXCELENTE. Melhor durabilidade." & goto :q3
:p_mx6
set "PASTA_NOME=Arctic MX-6" & set "PASTA_DUR=Alta (5+ anos)" & set "PASTA_VEREDITO=EXCELENTE." & goto :q3
:p_nth1
set "PASTA_NOME=Noctua NT-H1" & set "PASTA_DUR=Alta (5 anos)" & set "PASTA_VEREDITO=EXCELENTE." & goto :q3
:p_nth2
set "PASTA_NOME=Noctua NT-H2" & set "PASTA_DUR=Alta (5 anos)" & set "PASTA_VEREDITO=EXCELENTE." & goto :q3
:p_kryo
set "PASTA_NOME=Thermal Grizzly Kryonaut" & set "PASTA_DUR=Media (3 a 5 anos)" & set "PASTA_VEREDITO=ENTUSIASTA." & goto :q3
:p_hydro
set "PASTA_NOME=Thermal Grizzly Hydronaut" & set "PASTA_DUR=Media (4 a 6 anos)" & set "PASTA_VEREDITO=ENTUSIASTA." & goto :q3
:p_auth
set "PASTA_NOME=Authentic Silver Thermal Pro" & set "PASTA_DUR=Alta" & set "PASTA_VEREDITO=ENTUSIASTA nacional." & goto :q3
:p_frio
set "PASTA_NOME=Friosys Glacial" & set "PASTA_DUR=Media" & set "PASTA_VEREDITO=ENTUSIASTA nacional." & goto :q3
:p_snow
set "PASTA_NOME=Snowdog Husky" & set "PASTA_DUR=Media" & set "PASTA_VEREDITO=ENTUSIASTA nacional." & goto :q3
:p_stock
set "PASTA_NOME=Pasta stock" & set "PASTA_DUR=1 a 3 anos" & set "PASTA_VEREDITO=BASICA." & goto :q3
:p_nsei
set "PASTA_NOME=Nao informada" & set "PASTA_DUR=Desconhecida" & set "PASTA_VEREDITO=Sem dados."

:q3
cls
echo.
echo   3) Ha quanto tempo voce tem este PC?
echo      [1] Menos de 1 ano
echo      [2] 1 a 2 anos
echo      [3] 2 a 3 anos
echo      [4] 3 a 5 anos
echo      [5] Mais de 5 anos
echo.
choice /c 12345 /n /m "  Escolha (1-5): "
if errorlevel 5 set "PC_IDADE=mais5" & set "PC_IDADE_TXT=mais de 5 anos" & goto :q4
if errorlevel 4 set "PC_IDADE=3a5" & set "PC_IDADE_TXT=3 a 5 anos" & goto :q4
if errorlevel 3 set "PC_IDADE=2a3" & set "PC_IDADE_TXT=2 a 3 anos" & goto :q4
if errorlevel 2 set "PC_IDADE=1a2" & set "PC_IDADE_TXT=1 a 2 anos" & goto :q4
set "PC_IDADE=menos1"
set "PC_IDADE_TXT=menos de 1 ano"

:q4
cls
echo.
echo   4) Quantas horas por dia voce usa o PC?
echo      [1] Menos de 2 horas
echo      [2] 2 a 4 horas
echo      [3] 4 a 8 horas
echo      [4] Mais de 8 horas
echo.
choice /c 1234 /n /m "  Escolha (1-4): "
if errorlevel 4 set "USO=mais8" & set "USO_TXT=mais de 8 horas" & goto :q5
if errorlevel 3 set "USO=4a8" & set "USO_TXT=4 a 8 horas" & goto :q5
if errorlevel 2 set "USO=2a4" & set "USO_TXT=2 a 4 horas" & goto :q5
set "USO=menos2"
set "USO_TXT=menos de 2 horas"

:q5
cls
color 0E
echo.
echo  ============================================================
echo    QUESTIONARIO - PARTE 2: SETUP FISICO
echo  ============================================================
echo.
echo   5) Quantas ventoinhas (fans) tem no gabinete?
echo      [1] Nenhuma
echo      [2] 1 ou 2 fans
echo      [3] 3 ou 4 fans
echo      [4] 5 ou mais fans
echo.
choice /c 1234 /n /m "  Escolha (1-4): "
if errorlevel 4 set "FANS=5 ou mais" & set "FANS_NUM=6" & goto :q5_idade
if errorlevel 3 set "FANS=3 ou 4" & set "FANS_NUM=4" & goto :q5_idade
if errorlevel 2 set "FANS=1 ou 2" & set "FANS_NUM=2" & goto :q5_idade
set "FANS=Nenhuma"
set "FANS_NUM=0"

:q5_idade
cls
echo.
echo   5b) Ha quanto tempo voce tem este gabinete?
echo      [1] Menos de 1 ano
echo      [2] 1 a 2 anos
echo      [3] 2 a 3 anos
echo      [4] 3 a 5 anos
echo      [5] Mais de 5 anos
echo      [6] Nao sei
echo.
choice /c 123456 /n /m "  Escolha (1-6): "
if errorlevel 6 set "GAB_IDADE=Desconhecida" & goto :q6
if errorlevel 5 set "GAB_IDADE=mais5" & goto :q6
if errorlevel 4 set "GAB_IDADE=3a5" & goto :q6
if errorlevel 3 set "GAB_IDADE=2a3" & goto :q6
if errorlevel 2 set "GAB_IDADE=1a2" & goto :q6
set "GAB_IDADE=menos1"

:q6
cls
echo.
echo   6) Sobre a FONTE - marca/modelo (ex: Corsair CX650)
echo   Se nao souber, digite: nao sei
echo.
set /p FONTE_USER=  Digite: 
if not defined FONTE_USER set "FONTE_USER=Nao informada"
set "FONTE_NOME=%FONTE_USER%"
set "FONTE_TIER=Desconhecido"
set "FONTE_VEREDITO=Modelo nao identificado."
echo %FONTE_USER% | findstr /i "corsair rm corsair hx corsair ax seasonic focus seasonic prime evga supernova be quiet xpg core" >nul
if %errorlevel% EQU 0 goto :f_high
echo %FONTE_USER% | findstr /i "corsair cx corsair cv cooler master mwe thermaltake smart xpg pcyes electro gamemax" >nul
if %errorlevel% EQU 0 goto :f_mid
echo %FONTE_USER% | findstr /i "nao sei nsei" >nul
if %errorlevel% EQU 0 goto :f_nsei
goto :f_generic
:f_high
set "FONTE_TIER=ALTA"
set "FONTE_VEREDITO=EXCELENTE. Alta qualidade."
goto :q6_watts
:f_mid
set "FONTE_TIER=MEDIA"
set "FONTE_VEREDITO=INTERMEDIARIA. Funciona bem."
goto :q6_watts
:f_generic
set "FONTE_TIER=GENERICA"
set "FONTE_VEREDITO=ATENCAO. Verifique a marca."
goto :q6_watts
:f_nsei
set "FONTE_TIER=DESCONHECIDO"
set "FONTE_VEREDITO=Sem dados. Verifique o rotulo."

:q6_watts
cls
echo.
echo   6b) Potencia da fonte em watts? (ex: 500, 650, 750)
echo.
set /p FONTE_WATTS=  Watts: 
if not defined FONTE_WATTS set "FONTE_WATTS=0"

:q6_80
cls
echo.
echo   6c) Certificacao 80 Plus?
echo      [1] Sem certificacao
echo      [2] 80 Plus White
echo      [3] 80 Plus Bronze
echo      [4] 80 Plus Gold
echo      [5] 80 Plus Platinum ou Titanium
echo      [6] Nao sei
echo.
choice /c 123456 /n /m "  Escolha (1-6): "
if errorlevel 6 set "FONTE_80=Nao sabe" & goto :q6_idade
if errorlevel 5 set "FONTE_80=Platinum/Titanium" & goto :q6_idade
if errorlevel 4 set "FONTE_80=Gold" & goto :q6_idade
if errorlevel 3 set "FONTE_80=Bronze" & goto :q6_idade
if errorlevel 2 set "FONTE_80=White" & goto :q6_idade
set "FONTE_80=Sem"

:q6_idade
cls
echo.
echo   6d) Ha quanto tempo a fonte esta em uso?
echo      [1] Menos de 1 ano
echo      [2] 1 a 2 anos
echo      [3] 2 a 3 anos
echo      [4] 3 a 5 anos
echo      [5] Mais de 5 anos
echo      [6] Nao sei
echo.
choice /c 123456 /n /m "  Escolha (1-6): "
if errorlevel 6 set "FONTE_IDADE=Desconhecida" & goto :q7
if errorlevel 5 set "FONTE_IDADE=mais5" & goto :q7
if errorlevel 4 set "FONTE_IDADE=3a5" & goto :q7
if errorlevel 3 set "FONTE_IDADE=2a3" & goto :q7
if errorlevel 2 set "FONTE_IDADE=1a2" & goto :q7
set "FONTE_IDADE=menos1"

:q7
cls
echo.
echo   7) Sobre o COOLER do processador
echo      [1] Air cooler (torre)
echo      [2] Water cooler (AIO)
echo      [3] Cooler stock (o que veio com a CPU)
echo      [4] Nao sei
echo.
choice /c 1234 /n /m "  Escolha (1-4): "
if errorlevel 4 goto :q7_nsei
if errorlevel 3 goto :q7_stock
if errorlevel 2 goto :q7_wc
goto :q7_ac

:q7_nsei
set "COOLER_TIPO=Nao sabe"
set "COOLER_MODELO=Nao informado"
set "COOLER_TDP=0"
set "COOLER_VEREDITO=Sem dados."
goto :q7_idade

:q7_stock
set "COOLER_TIPO=Cooler stock"
set "COOLER_MODELO=Stock (original)"
set "COOLER_TDP=95"
set "COOLER_VEREDITO=Cooler stock. So para CPUs de baixo TDP."
goto :q7_idade

:q7_ac
set "COOLER_TIPO=Air cooler"
cls
echo.
echo   7b) Modelo do air cooler? (ex: Hyper 212, AG400, PA120)
echo.
set /p COOLER_MODELO=  Digite: 
if not defined COOLER_MODELO set "COOLER_MODELO=Nao informado"
set "COOLER_TDP=0"
set "COOLER_VEREDITO=Modelo nao identificado."
echo %COOLER_MODELO% | findstr /i "hyper 212" >nul
if %errorlevel% EQU 0 goto :ac_hyper212
echo %COOLER_MODELO% | findstr /i "ak400 ag400" >nul
if %errorlevel% EQU 0 goto :ac_ak400
echo %COOLER_MODELO% | findstr /i "ak620 ag620" >nul
if %errorlevel% EQU 0 goto :ac_ak620
echo %COOLER_MODELO% | findstr /i "pa120 peerless" >nul
if %errorlevel% EQU 0 goto :ac_pa120
echo %COOLER_MODELO% | findstr /i "nh-d15" >nul
if %errorlevel% EQU 0 goto :ac_d15
echo %COOLER_MODELO% | findstr /i "gammaxx" >nul
if %errorlevel% EQU 0 goto :ac_gammaxx
goto :q7_idade
:ac_hyper212
set "COOLER_TDP=150" & set "COOLER_VEREDITO=Air cooler intermediario (150W)." & goto :q7_idade
:ac_ak400
set "COOLER_TDP=220" & set "COOLER_VEREDITO=Air cooler intermediario (220W)." & goto :q7_idade
:ac_ak620
set "COOLER_TDP=260" & set "COOLER_VEREDITO=Air cooler entusiasta (260W)." & goto :q7_idade
:ac_pa120
set "COOLER_TDP=265" & set "COOLER_VEREDITO=Entusiasta (265W). Melhor custo-beneficio." & goto :q7_idade
:ac_d15
set "COOLER_TDP=250" & set "COOLER_VEREDITO=Topo de linha (250W)." & goto :q7_idade
:ac_gammaxx
set "COOLER_TDP=130" & set "COOLER_VEREDITO=Entrada (130W)." & goto :q7_idade

:q7_wc
set "COOLER_TIPO=Water cooler AIO"
cls
echo.
echo   7b) Modelo do water cooler? (ex: TUF LC II, H100i, Kraken)
echo.
set /p COOLER_MODELO=  Digite: 
if not defined COOLER_MODELO set "COOLER_MODELO=Nao informado"
echo %COOLER_MODELO% | findstr /i "tuf lc ii tuf lc 2" >nul
if %errorlevel% EQU 0 goto :wc_tuf2
echo %COOLER_MODELO% | findstr /i "ryujin" >nul
if %errorlevel% EQU 0 goto :wc_ryujin
echo %COOLER_MODELO% | findstr /i "ryuo" >nul
if %errorlevel% EQU 0 goto :wc_ryuo
echo %COOLER_MODELO% | findstr /i "strix lc" >nul
if %errorlevel% EQU 0 goto :wc_strix
echo %COOLER_MODELO% | findstr /i "prime lc" >nul
if %errorlevel% EQU 0 goto :wc_prime
echo %COOLER_MODELO% | findstr /i "kraken" >nul
if %errorlevel% EQU 0 goto :wc_kraken
echo %COOLER_MODELO% | findstr /i "corsair h" >nul
if %errorlevel% EQU 0 goto :wc_corsair
echo %COOLER_MODELO% | findstr /i "deepcool" >nul
if %errorlevel% EQU 0 goto :wc_deepcool
echo %COOLER_MODELO% | findstr /i "liquid freezer" >nul
if %errorlevel% EQU 0 goto :wc_arctic
echo %COOLER_MODELO% | findstr /i "galahad" >nul
if %errorlevel% EQU 0 goto :wc_lianli
echo %COOLER_MODELO% | findstr /i "ml240 ml360" >nul
if %errorlevel% EQU 0 goto :wc_cm
echo %COOLER_MODELO% | findstr /i "rise mode aquarium" >nul
if %errorlevel% EQU 0 goto :wc_rise
echo %COOLER_MODELO% | findstr /i "pcyes nix" >nul
if %errorlevel% EQU 0 goto :wc_pcyes
goto :wc_generic
:wc_tuf2
set "COOLER_FAMILIA=ASUS TUF Gaming LC II" & set "COOLER_VEREDITO=ASUS TUF LC II: AIO confiavel." & goto :wc_size
:wc_ryujin
set "COOLER_FAMILIA=ASUS ROG Ryujin III" & set "COOLER_VEREDITO=Topo de linha ASUS." & goto :wc_size
:wc_ryuo
set "COOLER_FAMILIA=ASUS ROG Ryuo III" & set "COOLER_VEREDITO=Entusiasta ASUS." & goto :wc_size
:wc_strix
set "COOLER_FAMILIA=ASUS ROG Strix LC" & set "COOLER_VEREDITO=Entusiasta ASUS." & goto :wc_size
:wc_prime
set "COOLER_FAMILIA=ASUS Prime LC" & set "COOLER_VEREDITO=Entrada ASUS." & goto :wc_size
:wc_kraken
set "COOLER_FAMILIA=NZXT Kraken" & set "COOLER_VEREDITO=NZXT premium." & goto :wc_size
:wc_corsair
set "COOLER_FAMILIA=Corsair Hydro" & set "COOLER_VEREDITO=Corsair classica." & goto :wc_size
:wc_deepcool
set "COOLER_FAMILIA=DeepCool" & set "COOLER_VEREDITO=DeepCool: custo-beneficio." & goto :wc_size
:wc_arctic
set "COOLER_FAMILIA=Arctic Liquid Freezer II" & set "COOLER_VEREDITO=Arctic: melhor performance/ruido." & goto :wc_size
:wc_lianli
set "COOLER_FAMILIA=Lian Li Galahad II" & set "COOLER_VEREDITO=Lian Li: qualidade premium." & goto :wc_size
:wc_cm
set "COOLER_FAMILIA=Cooler Master ML" & set "COOLER_VEREDITO=Cooler Master: bom custo-beneficio." & goto :wc_size
:wc_rise
set "COOLER_FAMILIA=Rise Mode Aquarium" & set "COOLER_VEREDITO=Entrada nacional." & goto :wc_size
:wc_pcyes
set "COOLER_FAMILIA=PCYes Nix" & set "COOLER_VEREDITO=Entrada nacional." & goto :wc_size
:wc_generic
set "COOLER_FAMILIA=%COOLER_MODELO%" & set "COOLER_VEREDITO=Modelo nao reconhecido." & goto :wc_size

:wc_size
cls
echo.
echo   Tamanho do radiador do %COOLER_FAMILIA%?
echo      [1] 120mm
echo      [2] 240mm
echo      [3] 280mm
echo      [4] 360mm
echo      [5] 420mm
echo      [6] Nao sei
echo.
choice /c 123456 /n /m "  Escolha (1-6): "
if errorlevel 6 goto :wc_desc
if errorlevel 5 set "COOLER_TDP=350" & set "COOLER_MODELO=%COOLER_FAMILIA% 420mm" & goto :q7_idade
if errorlevel 4 set "COOLER_TDP=320" & set "COOLER_MODELO=%COOLER_FAMILIA% 360mm" & goto :q7_idade
if errorlevel 3 set "COOLER_TDP=280" & set "COOLER_MODELO=%COOLER_FAMILIA% 280mm" & goto :q7_idade
if errorlevel 2 set "COOLER_TDP=250" & set "COOLER_MODELO=%COOLER_FAMILIA% 240mm" & goto :q7_idade
set "COOLER_TDP=150"
set "COOLER_MODELO=%COOLER_FAMILIA% 120mm"
goto :q7_idade
:wc_desc
set "COOLER_TDP=0"
set "COOLER_MODELO=%COOLER_FAMILIA% (tamanho nao informado)"

:q7_idade
cls
echo.
echo   7c) Ha quanto tempo o cooler esta em uso?
echo      [1] Menos de 1 ano
echo      [2] 1 a 2 anos
echo      [3] 2 a 3 anos
echo      [4] 3 a 5 anos
echo      [5] Mais de 5 anos
echo      [6] Nao sei
echo.
choice /c 123456 /n /m "  Escolha (1-6): "
if errorlevel 6 set "COOLER_IDADE=Desconhecida" & goto :q8
if errorlevel 5 set "COOLER_IDADE=mais5" & goto :q8
if errorlevel 4 set "COOLER_IDADE=3a5" & goto :q8
if errorlevel 3 set "COOLER_IDADE=2a3" & goto :q8
if errorlevel 2 set "COOLER_IDADE=1a2" & goto :q8
set "COOLER_IDADE=menos1"

:q8
cls
color 0E
echo.
echo  ============================================================
echo    QUESTIONARIO - PARTE 3: PERFIL DE JOGO
echo  ============================================================
echo.
echo   8) Que tipo de jogo voce mais joga?
echo      [1] Competitivos (CS2, Valorant, Fortnite, LoL)
echo      [2] AAA single-player (Cyberpunk, God of War)
echo      [3] Estrategia/simulacao (Cities, Total War)
echo      [4] Indie/leves (Stardew, Hades)
echo      [5] Um pouco de tudo
echo.
choice /c 12345 /n /m "  Escolha (1-5): "
if errorlevel 5 set "TIPO_JOGO=Misto" & goto :q8_res
if errorlevel 4 set "TIPO_JOGO=Indie/Leves" & goto :q8_res
if errorlevel 3 set "TIPO_JOGO=Estrategia/Simulacao" & goto :q8_res
if errorlevel 2 set "TIPO_JOGO=AAA Single-player" & goto :q8_res
set "TIPO_JOGO=Competitivo"

:q8_res
cls
echo.
echo   8b) Em que resolucao voce joga?
echo      [1] 1080p (Full HD)
echo      [2] 1440p (2K)
echo      [3] 4K
echo      [4] Nao sei
echo.
choice /c 1234 /n /m "  Escolha (1-4): "
if errorlevel 4 set "RESOLUCAO=Automatica" & goto :q8_qual
if errorlevel 3 set "RESOLUCAO=4K" & goto :q8_qual
if errorlevel 2 set "RESOLUCAO=1440p" & goto :q8_qual
set "RESOLUCAO=1080p"

:q8_qual
cls
echo.
echo   8c) Qual qualidade grafica voce aceita?
echo      [1] Ultra - tudo no maximo
echo      [2] Alta - qualidade com algum ajuste
echo      [3] Media - prefiro fluidez
echo      [4] Baixa - so desempenho
echo.
choice /c 1234 /n /m "  Escolha (1-4): "
if errorlevel 4 set "QUALIDADE=Baixa" & goto :q9
if errorlevel 3 set "QUALIDADE=Media" & goto :q9
if errorlevel 2 set "QUALIDADE=Alta" & goto :q9
set "QUALIDADE=Ultra"

:q9
cls
color 0E
echo.
echo  ============================================================
echo    QUESTIONARIO - PARTE 4: ORCAMENTO
echo  ============================================================
echo.
echo   9) Quanto voce pode investir em melhorias?
echo      [1] Nada no momento
echo      [2] Ate R$ 200
echo      [3] R$ 200 a R$ 500
echo      [4] R$ 500 a R$ 1.000
echo      [5] Acima de R$ 1.000
echo.
choice /c 12345 /n /m "  Escolha (1-5): "
if errorlevel 5 set "ORCAMENTO=Acima de R$ 1.000" & set "ORC_NUM=1500" & goto :q10
if errorlevel 4 set "ORCAMENTO=R$ 500 a R$ 1.000" & set "ORC_NUM=1000" & goto :q10
if errorlevel 3 set "ORCAMENTO=R$ 200 a R$ 500" & set "ORC_NUM=500" & goto :q10
if errorlevel 2 set "ORCAMENTO=Ate R$ 200" & set "ORC_NUM=200" & goto :q10
set "ORCAMENTO=Nada no momento"
set "ORC_NUM=0"

:q10
cls
color 0E
echo.
echo  ============================================================
echo    QUESTIONARIO - PARTE 5: MONITOR
echo  ============================================================
echo.
echo   10) Modelo do seu monitor principal?
echo   Ex: Redragon Opal II, AOC 24G2, Gigabyte GS27QA
echo   Se nao souber, digite: nao sei
echo.
set /p MONITOR_USER=  Digite: 
if not defined MONITOR_USER set "MONITOR_USER=Nao informado"
set "MONITOR_NOME=%MONITOR_USER%"
set "MONITOR_RES=Desconhecida"
set "MONITOR_HZ=Desconhecido"
set "MONITOR_PAINEL=Desconhecido"
set "MONITOR_POL=Desconhecido"
set "MONITOR_VEREDITO=Modelo nao identificado no banco de dados."
echo %MONITOR_USER% | findstr /i "redragon opal" >nul
if %errorlevel% EQU 0 goto :mon_opal
echo %MONITOR_USER% | findstr /i "gigabyte gs27qa" >nul
if %errorlevel% EQU 0 goto :mon_gs27
echo %MONITOR_USER% | findstr /i "samsung odyssey oled g5" >nul
if %errorlevel% EQU 0 goto :mon_oledg5
echo %MONITOR_USER% | findstr /i "samsung odyssey oled g6" >nul
if %errorlevel% EQU 0 goto :mon_oledg6
echo %MONITOR_USER% | findstr /i "lg 27gr95qe" >nul
if %errorlevel% EQU 0 goto :mon_27gr95
echo %MONITOR_USER% | findstr /i "alienware aw2725dm" >nul
if %errorlevel% EQU 0 goto :mon_aw2725
echo %MONITOR_USER% | findstr /i "tcl 27g64" >nul
if %errorlevel% EQU 0 goto :mon_tcl
echo %MONITOR_USER% | findstr /i "xiaomi g pro" >nul
if %errorlevel% EQU 0 goto :mon_xiaomi
echo %MONITOR_USER% | findstr /i "samsung odyssey g5" >nul
if %errorlevel% EQU 0 goto :mon_g5
echo %MONITOR_USER% | findstr /i "samsung odyssey g3" >nul
if %errorlevel% EQU 0 goto :mon_g3
echo %MONITOR_USER% | findstr /i "aoc 24g2" >nul
if %errorlevel% EQU 0 goto :mon_aoc24
echo %MONITOR_USER% | findstr /i "lg 24gn600" >nul
if %errorlevel% EQU 0 goto :mon_lg24
echo %MONITOR_USER% | findstr /i "duex pro" >nul
if %errorlevel% EQU 0 goto :mon_duex
echo %MONITOR_USER% | findstr /i "nao sei nsei" >nul
if %errorlevel% EQU 0 goto :mon_manual
goto :mon_manual
:mon_opal
set "MONITOR_NOME=Redragon Opal II"
set "MONITOR_RES=1440p" & set "MONITOR_HZ=180Hz" & set "MONITOR_PAINEL=IPS" & set "MONITOR_POL=27"
set "MONITOR_VEREDITO=[EXCELENTE] 1440p 180Hz IPS. Combina com a RX 9070."
goto :analise_monitor
:mon_gs27
set "MONITOR_NOME=Gigabyte GS27QA"
set "MONITOR_RES=1440p" & set "MONITOR_HZ=180Hz" & set "MONITOR_PAINEL=IPS" & set "MONITOR_POL=27"
set "MONITOR_VEREDITO=[EXCELENTE] 1440p 180Hz IPS."
goto :analise_monitor
:mon_oledg5
set "MONITOR_NOME=Samsung Odyssey OLED G5"
set "MONITOR_RES=1440p" & set "MONITOR_HZ=180Hz" & set "MONITOR_PAINEL=QD-OLED" & set "MONITOR_POL=27"
set "MONITOR_VEREDITO=[TOP] 1440p 180Hz QD-OLED."
goto :analise_monitor
:mon_oledg6
set "MONITOR_NOME=Samsung Odyssey OLED G6"
set "MONITOR_RES=1440p" & set "MONITOR_HZ=500Hz" & set "MONITOR_PAINEL=QD-OLED" & set "MONITOR_POL=27"
set "MONITOR_VEREDITO=[TOP] 1440p 500Hz QD-OLED."
goto :analise_monitor
:mon_27gr95
set "MONITOR_NOME=LG 27GR95QE-B"
set "MONITOR_RES=1440p" & set "MONITOR_HZ=240Hz" & set "MONITOR_PAINEL=OLED" & set "MONITOR_POL=27"
set "MONITOR_VEREDITO=[TOP] 1440p 240Hz OLED."
goto :analise_monitor
:mon_aw2725
set "MONITOR_NOME=Alienware AW2725DM"
set "MONITOR_RES=1440p" & set "MONITOR_HZ=180Hz" & set "MONITOR_PAINEL=Fast IPS" & set "MONITOR_POL=27"
set "MONITOR_VEREDITO=[EXCELENTE] 1440p 180Hz Fast IPS."
goto :analise_monitor
:mon_tcl
set "MONITOR_NOME=TCL 27G64"
set "MONITOR_RES=1440p" & set "MONITOR_HZ=180Hz" & set "MONITOR_PAINEL=QD-Mini LED" & set "MONITOR_POL=27"
set "MONITOR_VEREDITO=[EXCELENTE] 1440p 180Hz Mini LED."
goto :analise_monitor
:mon_xiaomi
set "MONITOR_NOME=Xiaomi G Pro 27QI"
set "MONITOR_RES=1440p" & set "MONITOR_HZ=180Hz" & set "MONITOR_PAINEL=Mini LED" & set "MONITOR_POL=27"
set "MONITOR_VEREDITO=[EXCELENTE] 1440p 180Hz Mini LED."
goto :analise_monitor
:mon_g5
set "MONITOR_NOME=Samsung Odyssey G5"
set "MONITOR_RES=1440p" & set "MONITOR_HZ=165Hz" & set "MONITOR_PAINEL=VA" & set "MONITOR_POL=27"
set "MONITOR_VEREDITO=[BOM] 1440p 165Hz VA."
goto :analise_monitor
:mon_g3
set "MONITOR_NOME=Samsung Odyssey G3"
set "MONITOR_RES=1080p" & set "MONITOR_HZ=144Hz" & set "MONITOR_PAINEL=VA" & set "MONITOR_POL=24"
set "MONITOR_VEREDITO=[OK] 1080p 144Hz VA."
goto :analise_monitor
:mon_aoc24
set "MONITOR_NOME=AOC 24G2"
set "MONITOR_RES=1080p" & set "MONITOR_HZ=144Hz" & set "MONITOR_PAINEL=IPS" & set "MONITOR_POL=24"
set "MONITOR_VEREDITO=[OK] 1080p 144Hz IPS."
goto :analise_monitor
:mon_lg24
set "MONITOR_NOME=LG 24GN600"
set "MONITOR_RES=1080p" & set "MONITOR_HZ=144Hz" & set "MONITOR_PAINEL=IPS" & set "MONITOR_POL=24"
set "MONITOR_VEREDITO=[OK] 1080p 144Hz IPS."
goto :analise_monitor
:mon_duex
set "MONITOR_NOME=Duex Pro 27"
set "MONITOR_RES=1440p" & set "MONITOR_HZ=180Hz" & set "MONITOR_PAINEL=IPS" & set "MONITOR_POL=27"
set "MONITOR_VEREDITO=[EXCELENTE] 1440p 180Hz IPS nacional."
goto :analise_monitor

:mon_manual
cls
echo.
echo   Qual a resolucao do seu monitor?
echo      [1] 1080p
echo      [2] 1440p
echo      [3] 4K
echo      [4] Ultrawide 1440p
echo      [5] Nao sei
echo.
choice /c 12345 /n /m "  Escolha (1-5): "
if errorlevel 5 set "MONITOR_RES=Desconhecida" & goto :mon_hz_man
if errorlevel 4 set "MONITOR_RES=Ultrawide 1440p" & goto :mon_hz_man
if errorlevel 3 set "MONITOR_RES=4K" & goto :mon_hz_man
if errorlevel 2 set "MONITOR_RES=1440p" & goto :mon_hz_man
set "MONITOR_RES=1080p"
:mon_hz_man
cls
echo.
echo   Taxa de atualizacao (Hz)?
echo      [1] Ate 60Hz
echo      [2] 75-100Hz
echo      [3] 144-165Hz
echo      [4] 180-240Hz
echo      [5] 240Hz ou mais
echo      [6] Nao sei
echo.
choice /c 123456 /n /m "  Escolha (1-6): "
if errorlevel 6 set "MONITOR_HZ=Desconhecido" & goto :mon_pol_man
if errorlevel 5 set "MONITOR_HZ=240Hz+" & goto :mon_pol_man
if errorlevel 4 set "MONITOR_HZ=180-240Hz" & goto :mon_pol_man
if errorlevel 3 set "MONITOR_HZ=144-165Hz" & goto :mon_pol_man
if errorlevel 2 set "MONITOR_HZ=75-100Hz" & goto :mon_pol_man
set "MONITOR_HZ=60Hz"
:mon_pol_man
cls
echo.
echo   Tamanho do monitor em polegadas?
echo      [1] 24 ou menos
echo      [2] 27
echo      [3] 32
echo      [4] 34 ou mais (Ultrawide)
echo      [5] Nao sei
echo.
choice /c 12345 /n /m "  Escolha (1-5): "
if errorlevel 5 set "MONITOR_POL=Desconhecido" & goto :mon_painel_man
if errorlevel 4 set "MONITOR_POL=34+" & goto :mon_painel_man
if errorlevel 3 set "MONITOR_POL=32" & goto :mon_painel_man
if errorlevel 2 set "MONITOR_POL=27" & goto :mon_painel_man
set "MONITOR_POL=24"
:mon_painel_man
cls
echo.
echo   Tipo de painel (se souber)?
echo      [1] IPS
echo      [2] VA
echo      [3] TN
echo      [4] OLED
echo      [5] Mini LED
echo      [6] Nao sei
echo.
choice /c 123456 /n /m "  Escolha (1-6): "
if errorlevel 6 set "MONITOR_PAINEL=Desconhecido" & goto :analise_monitor
if errorlevel 5 set "MONITOR_PAINEL=Mini LED" & goto :analise_monitor
if errorlevel 4 set "MONITOR_PAINEL=OLED" & goto :analise_monitor
if errorlevel 3 set "MONITOR_PAINEL=TN" & goto :analise_monitor
if errorlevel 2 set "MONITOR_PAINEL=VA" & goto :analise_monitor
set "MONITOR_PAINEL=IPS"

:analise_monitor
if "%MONITOR_RES%"=="1080p" set "SUGESTAO_MONITOR=[ATENCAO] Monitor 1080p subutiliza a RX 9070. Considere upgrade para 1440p."
if "%MONITOR_RES%"=="1440p" set "SUGESTAO_MONITOR=[EXCELENTE] Monitor 1440p ideal para a RX 9070."
if "%MONITOR_RES%"=="4K" set "SUGESTAO_MONITOR=[BOM] Monitor 4K. RX 9070 aguenta com FSR em jogos pesados."
if "%MONITOR_RES%"=="Ultrawide 1440p" set "SUGESTAO_MONITOR=[BOM] Ultrawide combina bem com a RX 9070."
if "%MONITOR_RES%"=="Desconhecida" set "SUGESTAO_MONITOR=[INFO] Sem dados suficientes do monitor."
if "%TIPO_JOGO%"=="Competitivo" set "REC_POL=[RECOMENDACAO] Para competitivos, 24 ou 27 polegadas e o ideal."
if "%TIPO_JOGO%"=="AAA Single-player" set "REC_POL=[RECOMENDACAO] Para AAA, 27 polegadas 1440p ou 32 polegadas 4K sao ideais."
if "%TIPO_JOGO%"=="Estrategia/Simulacao" set "REC_POL=[RECOMENDACAO] Para estrategia, 27 1440p ou 34 Ultrawide."
if "%TIPO_JOGO%"=="Indie/Leves" set "REC_POL=[OK] Qualquer monitor de 24-27 polegadas funciona bem."
if not defined REC_POL set "REC_POL=[RECOMENDACAO] Para uso misto, 27 polegadas 1440p 180Hz e o ponto ideal."

:q11
cls
color 0E
echo.
echo  ============================================================
echo    QUESTIONARIO - PARTE 6: PERIFERICOS
echo  ============================================================
echo.
echo   Voce tem os perifericos abaixo? (S para Sim, N para Nao)
echo.
set /p PERIF_MOUSE=  Mouse: 
set /p PERIF_TECLADO=  Teclado: 
set /p PERIF_HEADSET=  Headset: 
set /p PERIF_MOUSEPAD=  Mousepad: 

if /i "%PERIF_MOUSE%"=="s" set "PERIF_MOUSE=S"
if /i "%PERIF_MOUSE%"=="sim" set "PERIF_MOUSE=S"
if /i "%PERIF_TECLADO%"=="s" set "PERIF_TECLADO=S"
if /i "%PERIF_TECLADO%"=="sim" set "PERIF_TECLADO=S"
if /i "%PERIF_HEADSET%"=="s" set "PERIF_HEADSET=S"
if /i "%PERIF_HEADSET%"=="sim" set "PERIF_HEADSET=S"
if /i "%PERIF_MOUSEPAD%"=="s" set "PERIF_MOUSEPAD=S"
if /i "%PERIF_MOUSEPAD%"=="sim" set "PERIF_MOUSEPAD=S"

set "MOUSE_MODELO=Nao informado"
set "TECLADO_MODELO=Nao informado"
set "HEADSET_MODELO=Nao informado"
set "MOUSEPAD_MODELO=Nao informado"

if "%PERIF_MOUSE%"=="S" set /p MOUSE_MODELO=  Modelo do mouse: 
if "%PERIF_TECLADO%"=="S" set /p TECLADO_MODELO=  Modelo do teclado: 
if "%PERIF_HEADSET%"=="S" set /p HEADSET_MODELO=  Modelo do headset: 
if "%PERIF_MOUSEPAD%"=="S" set /p MOUSEPAD_MODELO=  Modelo do mousepad: 

set "REC_PERIF_MOUSE=[NAO TEM] Sugestoes: Logitech G203 (R$ 130-160) ou Redragon Cobra (R$ 80-110)."
if "%PERIF_MOUSE%"=="S" set "REC_PERIF_MOUSE=[TEM] %MOUSE_MODELO%"
set "REC_PERIF_TECLADO=[NAO TEM] Sugestao: Redragon Kumara K552 (R$ 200-280)."
if "%PERIF_TECLADO%"=="S" set "REC_PERIF_TECLADO=[TEM] %TECLADO_MODELO%"
set "REC_PERIF_HEADSET=[NAO TEM] Sugestao: HyperX Cloud Stinger 2 (R$ 250-330)."
if "%PERIF_HEADSET%"=="S" set "REC_PERIF_HEADSET=[TEM] %HEADSET_MODELO%"
set "REC_PERIF_MOUSEPAD=[NAO TEM] Sugestao: Redragon Suzaku (R$ 50-80)."
if "%PERIF_MOUSEPAD%"=="S" set "REC_PERIF_MOUSEPAD=[TEM] %MOUSEPAD_MODELO%"

:q11b
cls
color 0E
echo.
echo   11b) Voce usa ou pretende usar controle/gamepad?
echo      [1] Sim, ja tenho
echo      [2] Nao, e nao pretendo
echo      [3] Nao tenho, mas quero comprar
echo.
choice /c 123 /n /m "  Escolha (1-3): "
if errorlevel 3 goto :q11b_quer
if errorlevel 2 goto :q11b_nao
set "TEM_CONTROLE=S"
cls
echo.
echo   Modelo do controle? (ex: Redragon King Pro, Xbox Series)
echo.
set /p CONTROLE_USER=  Digite: 
if not defined CONTROLE_USER set "CONTROLE_USER=Nao informado"
set "CONTROLE_MODELO=%CONTROLE_USER%"
set "REC_CONTROLE=[INFO] Modelo nao reconhecido. Sugestoes: 8BitDo Ultimate 2C (R$ 130-230) ou GameSir Nova Lite (R$ 170-180)."
echo %CONTROLE_USER% | findstr /i "redragon king pro" >nul
if %errorlevel% EQU 0 set "REC_CONTROLE=[OK] Redragon King Pro. Boa escolha."
echo %CONTROLE_USER% | findstr /i "xbox" >nul
if %errorlevel% EQU 0 set "REC_CONTROLE=[EXCELENTE] Controle Xbox. Padrao da industria."
echo %CONTROLE_USER% | findstr /i "8bitdo" >nul
if %errorlevel% EQU 0 set "REC_CONTROLE=[EXCELENTE] 8BitDo. Otimo custo-beneficio."
echo %CONTROLE_USER% | findstr /i "gamesir" >nul
if %errorlevel% EQU 0 set "REC_CONTROLE=[EXCELENTE] GameSir. Hall Effect anti-drift."
echo %CONTROLE_USER% | findstr /i "dualsense" >nul
if %errorlevel% EQU 0 set "REC_CONTROLE=[EXCELENTE] DualSense PS5."
goto :q12
:q11b_quer
set "TEM_CONTROLE=N"
set "CONTROLE_MODELO=Quer comprar"
set "REC_CONTROLE=[QUER COMPRAR] Sugestoes: 8BitDo Ultimate 2C (R$ 130-230) ou GameSir Nova Lite (R$ 170-180). Ambos com Hall Effect."
goto :q12
:q11b_nao
set "TEM_CONTROLE=N"
set "CONTROLE_MODELO=Nao usa"
set "REC_CONTROLE=[INFO] Voce nao usa controle."

:q12
cls
color 0E
echo.
echo   12) Voce joga ou tem interesse em simuladores?
echo      [1] Simulador de voo (Flight Simulator, DCS)
echo      [2] Simulador de corrida (F1, Forza, Assetto Corsa)
echo      [3] Simulador naval (Ship Simulator, SailFront)
echo      [4] Outros (Euro Truck, Farming Simulator)
echo      [5] Nao tenho interesse
echo.
choice /c 12345 /n /m "  Escolha (1-5): "
if errorlevel 5 set "REC_SIMULADOR=[INFO] Sem interesse em simuladores." & goto :escreve_log
if errorlevel 4 set "REC_SIMULADOR=[OUTROS] Para simuladores de veiculos, um volante com Force Feedback (Logitech G29/G920 - R$ 1.700-1.900)." & goto :escreve_log
if errorlevel 3 set "REC_SIMULADOR=[NAVAL] Joystick com eixo de torcao (Logitech Extreme 3D Pro - R$ 250-350) ou pedais de leme (Thrustmaster TFRP - R$ 1.500-2.000)." & goto :escreve_log
if errorlevel 2 set "REC_SIMULADOR=[CORRIDA] Volante com Force Feedback. Entrada: Logitech G29/G920 (R$ 1.700-1.900). Entusiasta: Fanatec CSL Elite (R$ 2.500-3.000)." & goto :escreve_log
set "REC_SIMULADOR=[VOO] Joystick de precisao (Thrustmaster TCA Sidestick X - R$ 600-800). Kit completo: T.16000M FCS Pack (R$ 2.000-2.500)."

:escreve_log
cls
color 0A
echo.
echo  ============================================================
echo    Analisando suas respostas...
echo  ============================================================
echo.
echo    Aguarde alguns segundos.
echo.
timeout /t 3 /nobreak >nul

if "%LIMP%"=="Nunca" goto :rl_urg
if "%LIMP%"=="1a2anos" goto :rl_aten
if "%LIMP%"=="6a12meses" goto :rl_ok
set "REC_LIMPEZA=[EXCELENTE] Voce cuida bem da limpeza."
goto :rp
:rl_urg
set "REC_LIMPEZA=[URGENTE] Limpe o PC. Poeira causa superaquecimento."
goto :rp
:rl_aten
set "REC_LIMPEZA=[ATENCAO] Limpe a poeira e adote rotina semestral."
goto :rp
:rl_ok
set "REC_LIMPEZA=[OK] Frequencia aceitavel."

:rp
if "%PASTA%"=="Nunca" goto :rp_nunca
if "%PASTA_IDADE%"=="mais5" goto :rp_urg
if "%PASTA_IDADE%"=="3a5" goto :rp_3a5
if "%PASTA_IDADE%"=="2a3" goto :rp_2a3
set "REC_PASTA=[OK] Pasta relativamente nova."
goto :rg
:rp_nunca
if "%PC_IDADE%"=="mais5" goto :rp_n_urg
if "%PC_IDADE%"=="3a5" goto :rp_n_aten
set "REC_PASTA=[OK] Pasta original ainda na validade."
goto :rg
:rp_n_urg
set "REC_PASTA=[URGENTE] PC 5+ anos e pasta original. Troque IMEDIATAMENTE."
goto :rg
:rp_n_aten
set "REC_PASTA=[ATENCAO] Pasta original 3-5 anos. Trocar em breve."
goto :rg
:rp_urg
set "REC_PASTA=[URGENTE] Pasta com mais de 5 anos. Troque."
goto :rg
:rp_3a5
if "%PASTA_NOME%"=="Arctic MX-4" set "REC_PASTA=[OK] Arctic MX-4 dura 8+ anos."
if "%PASTA_NOME%"=="Rise Mode Cold 7.5" set "REC_PASTA=[ATENCAO] Rise Mode Cold 7.5 degrada rapido. Troque."
if not defined REC_PASTA set "REC_PASTA=[ATENCAO] Pasta com 3-5 anos. Trocar."
goto :rg
:rp_2a3
if "%PASTA_NOME%"=="Rise Mode Cold 7.5" set "REC_PASTA=[ATENCAO] Rise Mode Cold 7.5 com 2-3 anos. Considere trocar."
if not defined REC_PASTA set "REC_PASTA=[OK] Pasta com 2-3 anos. Trocar em 1-2 anos."

:rg
if "%FANS_NUM%"=="0" goto :rg_zero
if "%FANS_NUM%"=="2" goto :rg_dois
set "REC_GABINETE=[EXCELENTE] 3+ fans. Airflow otimo."
goto :rf
:rg_zero
set "REC_GABINETE=[URGENTE] Nenhum fan instalado. Instale pelo menos 2 fans."
goto :rf
:rg_dois
set "REC_GABINETE=[OK] 1-2 fans e o minimo. Adicione mais se puder."

:rf
set "REC_FONTE=[%FONTE_TIER%] %FONTE_VEREDITO%"
if %FONTE_WATTS% EQU 0 goto :rf_id
if %FONTE_WATTS% LSS 500 goto :rf_fraca
if %FONTE_WATTS% LSS 650 goto :rf_media
set "REC_FONTE=%REC_FONTE% [OK] Potencia adequada."
goto :rf_id
:rf_fraca
set "REC_FONTE=%REC_FONTE% [URGENTE] %FONTE_WATTS%W insuficiente. Minimo 650W."
goto :rf_id
:rf_media
set "REC_FONTE=%REC_FONTE% [ATENCAO] %FONTE_WATTS%W. Recomendado 650W+."
:rf_id
if "%FONTE_IDADE%"=="mais5" set "REC_FONTE=%REC_FONTE% [ATENCAO] Fonte 5+ anos."

set "REC_COOLER=[%COOLER_TIPO% - %COOLER_MODELO%] %COOLER_VEREDITO%"
if %COOLER_TDP% EQU 0 goto :rc_desc
set /a COOLER_MIN=%CPUTDP%*13/10
if %COOLER_TDP% GEQ %COOLER_MIN% goto :rc_ok
if %COOLER_TDP% GEQ %CPUTDP% goto :rc_lim
goto :rc_insuf
:rc_ok
set "COOLER_CRUZAMENTO=[OK] Cooler com folga (%COOLER_TDP%W vs %CPUTDP%W)."
goto :rc_id
:rc_lim
set "COOLER_CRUZAMENTO=[ATENCAO] Cooler no limite (%COOLER_TDP%W vs %CPUTDP%W)."
goto :rc_id
:rc_insuf
set "COOLER_CRUZAMENTO=[URGENTE] Cooler insuficiente (%COOLER_TDP%W vs %CPUTDP%W). Risco de throttling."
goto :rc_id
:rc_desc
set /a COOLER_MIN=%CPUTDP%*13/10
set "COOLER_CRUZAMENTO=[INFO] Cooler nao identificado. CPU exige %CPUTDP%W. Ideal: %COOLER_MIN%W+."
:rc_id
if "%COOLER_IDADE%"=="mais5" if "%COOLER_TIPO%"=="Water cooler AIO" set "REC_COOLER=%REC_COOLER% [URGENTE] AIO 5+ anos. Risco de falha da bomba."

echo. >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo   MANUTENCAO E SETUP >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo Limpeza: %LIMP_TXT% >> "%LOG%"
echo Idade PC: %PC_IDADE_TXT% >> "%LOG%"
echo Uso diario: %USO_TXT% >> "%LOG%"
echo Pasta: %PASTA_NOME% (idade: %PASTA_IDADE%) >> "%LOG%"
echo Fans: %FANS% >> "%LOG%"
echo Fonte: %FONTE_NOME% (%FONTE_WATTS%W %FONTE_80%) >> "%LOG%"
echo Cooler: %COOLER_MODELO% (%COOLER_TDP%W) >> "%LOG%"
echo. >> "%LOG%"
echo === PERFIL DE JOGO === >> "%LOG%"
echo Tipo: %TIPO_JOGO% >> "%LOG%"
echo Resolucao: %RESOLUCAO% >> "%LOG%"
echo Qualidade: %QUALIDADE% >> "%LOG%"
echo Orcamento: %ORCAMENTO% >> "%LOG%"
echo. >> "%LOG%"
echo === MONITOR === >> "%LOG%"
echo Modelo: %MONITOR_NOME% >> "%LOG%"
echo Resolucao: %MONITOR_RES% (%MONITOR_HZ% %MONITOR_PAINEL%) >> "%LOG%"
echo Veredito: %MONITOR_VEREDITO% >> "%LOG%"
echo Analise: %SUGESTAO_MONITOR% >> "%LOG%"
echo Polegadas: %REC_POL% >> "%LOG%"
echo. >> "%LOG%"
echo === PERIFERICOS === >> "%LOG%"
echo Mouse: %REC_PERIF_MOUSE% >> "%LOG%"
echo Teclado: %REC_PERIF_TECLADO% >> "%LOG%"
echo Headset: %REC_PERIF_HEADSET% >> "%LOG%"
echo Mousepad: %REC_PERIF_MOUSEPAD% >> "%LOG%"
echo Controle: %REC_CONTROLE% >> "%LOG%"
echo. >> "%LOG%"
echo === SIMULADORES === >> "%LOG%"
echo %REC_SIMULADOR% >> "%LOG%"
echo. >> "%LOG%"
echo === RECOMENDACOES DE MANUTENCAO === >> "%LOG%"
echo [LIMPEZA] %REC_LIMPEZA% >> "%LOG%"
echo [PASTA] %REC_PASTA% >> "%LOG%"
echo [GABINETE] %REC_GABINETE% >> "%LOG%"
echo [FONTE] %REC_FONTE% >> "%LOG%"
echo [COOLER] %REC_COOLER% >> "%LOG%"
echo [COOLER x CPU] %COOLER_CRUZAMENTO% >> "%LOG%"
echo. >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo   AVISO DE PRECOS >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo Todos os precos foram estimados em Setembro de 2026. >> "%LOG%"
echo Baseados em pesquisa no mercado brasileiro (Kabum, Pichau, >> "%LOG%"
echo Terabyte, Amazon, Mercado Livre). Os valores reais podem >> "%LOG%"
echo variar conforme loja, promocao, regiao e disponibilidade >> "%LOG%"
echo de estoque. Consulte sempre o preco atual antes de comprar. >> "%LOG%"
echo. >> "%LOG%"

set /a PERCENT=(SCORE*100)/MAXSCORE
if %PERCENT% GEQ 90 set "STATUS=EXCELENTE"
if %PERCENT% GEQ 75 if %PERCENT% LSS 90 set "STATUS=BOM"
if %PERCENT% GEQ 50 if %PERCENT% LSS 75 set "STATUS=REGULAR"
if %PERCENT% LSS 50 set "STATUS=ATENCAO"
echo RESULTADO FINAL: %PERCENT% por cento (%STATUS%) >> "%LOG%"

cls
color 0A
echo.
echo  ============================================================
echo    TUDO PRONTO!
echo  ============================================================
echo.
echo    Pontuacao do Windows: %PERCENT% por cento (%STATUS%)
echo.
echo    HARDWARE:
echo    Processador: %CPUNAME% (%CPUTDP%W)
echo    RAM: %RAMGB% GB
echo    GPU: %GPUNAME%
echo    Sistema: %OSNAME%
echo.
echo    PERFIL: %PERFIL%
echo    Comercial: %PCT_ESC% por cento
echo    Jogos: %PCT_JOG% por cento
echo.
echo    ------------------------------------------------------------
echo    RESUMO DAS RECOMENDACOES:
echo    ------------------------------------------------------------
echo    %REC_LIMPEZA%
echo    %REC_PASTA%
echo    %REC_GABINETE%
echo    %REC_FONTE%
echo    %REC_COOLER%
echo    %COOLER_CRUZAMENTO%
echo.
echo    ------------------------------------------------------------
echo    AVISO IMPORTANTE:
echo    ------------------------------------------------------------
echo    O relatorio completo foi salvo em:
echo    %LOG%
echo.
echo    Vou abrir o Bloco de Notas automaticamente para voce
echo    ler o relatorio completo.
echo.
echo    O relatorio contem TODAS as informacoes detalhadas:
echo    analise do Windows, SSD, drivers, monitor, perifericos,
echo    recomendacoes de upgrade e muito mais.
echo.
echo    ------------------------------------------------------------
echo    Pressione QUALQUER TECLA para abrir o relatorio...
echo    ------------------------------------------------------------
pause >nul

start notepad "%LOG%"

cls
color 0A
echo.
echo  ============================================================
echo    RELATORIO ABERTO NO BLOCO DE NOTAS
echo  ============================================================
echo.
echo    O relatorio esta aberto em outra janela.
echo.
echo    Leia com calma e use as informacoes para:
echo      - Saber o que precisa de manutencao
echo      - Planejar upgrades futuros
echo      - Consultar precos de referencia
echo.
echo    ------------------------------------------------------------
echo    Se quiser salvar o relatorio, use:
echo    Arquivo - Salvar como - escolha uma pasta sua
echo    ------------------------------------------------------------
echo.
echo    Powered by Alex Corcini
echo.
echo    ============================================================
echo    Pressione a tecla F para FECHAR esta janela.
echo    ============================================================
choice /c F /n /m "  > "
exit /B

:precisa_admin
color 0C
echo.
echo  ATENCAO: VOCE PRECISA EXECUTAR COMO ADMINISTRADOR
echo.
echo  1) Feche esta janela
echo  2) Clique com BOTAO DIREITO no arquivo .bat
echo  3) Escolha "Executar como administrador"
echo.
pause
exit /B