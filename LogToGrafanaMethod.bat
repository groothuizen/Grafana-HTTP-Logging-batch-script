rem Param 1: (string) Log Level -required-
rem Param 2: (string) Log Message -required-
rem IMPORTANT when inserting double quotes, escape the double quotes and the backslash like so: \\\"
:LogToGrafana
setlocal
    rem Get the current time in unix time and format it to a number that Grafana Loki can read:
    call :GetUnixTime UNIX_TIME
    set FORMATTED_UNIX_TIME=%UNIX_TIME%000000000
    rem
    rem Grafana logger API properties:
    set API_KEY=my_api_key
    set USERNAME=my_username
    set DATA_SOURCE_LINK=my_data_source_link
    rem
    rem Log labels:
    set SERVICE_NAME=my_service_name
    set SERVICE_NAMESPACE=my_service_namespace
    set DEPLOYMENT_ENVIRONMENT=production
    rem
    if not %1 == "" (
        set LOG_LEVEL=%~1
    ) else (
        echo Error code "87" at :LogToGrafana : first parameter: "Log Level" is not defined
        echo Aborting...
        rem ERROR_INVALID_PARAMETER
        exit /B 87
    )
    if not %2 == "" (
        set LOG_MESSAGE=%~2
    ) else (
        echo Error code "87" at :LogToGrafana : second parameter: "Log Message" is not defined
        echo Aborting...
        rem ERROR_INVALID_PARAMETER
        exit /B 87
    )
    rem
    curl -v -f -H "Content-Type:application/json" -H "Authorization:%USERNAME%:%API_KEY%" -s -X POST %DATA_SOURCE_LINK% -d "{\"streams\": [{ \"stream\": {\"language\": \"Curl\", \"source\": \"Shell\", \"service_name\": \"%SERVICE_NAME%\", \"service_namespace\": \"%SERVICE_NAMESPACE%\", \"deployment_environment\": \"%DEPLOYMENT_ENVIRONMENT%\", \"Level\": \"%LOG_LEVEL%\"}, \"values\": [ [ \"%FORMATTED_UNIX_TIME%\", \"%LOG_MESSAGE%\" ] ] }]}"
    rem
    if %ERRORLEVEL% == 22 (
        echo Error code "%ERRORLEVEL%" at :LogToGrafana : curl has failed unexpectedly, please check if the properties are set properly.
    )
    exit /B
endlocal
rem
:GetUnixTime
setlocal enableextensions
    for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do (
        set %%x)
    set /a z=(14 - 100%Month% %% 100) / 12, y= 10000%Year% %% 10000 - z
    set /a ut=y * 365 + y / 4 - y / 100 + y / 400 + (153 * (100%Month% %% 100 + 12 * z - 3) + 2) / 5 + Day - 719469
    set /a ut=ut * 86400 + 100%Hour% %% 100 * 3600 + 100%Minute% %% 100 * 60 + 100%Second% %% 100

endlocal & set "%1=%ut%" & exit /B
