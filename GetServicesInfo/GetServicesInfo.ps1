function Get-ServicesInfo {
    param (
        [string[]]$ServiceNames = @('dps', 'sysmain', 'pcasvc', 'appinfo', 'diagtrack', 'eventlog', 'bfe', 'msmpeng', 'dnscache')
    )

    $results = @()

    foreach ($name in $ServiceNames) {
        if (Get-Command -Name Get-CimInstance -ErrorAction SilentlyContinue) {
            try {
                $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='$name'" -ErrorAction Stop
                
                if ($service) {
                    $startTime = $null
                    if ($service.State -eq 'Running' -and $service.ProcessId -gt 0) {
                        try {
                            $process = Get-Process -Id $service.ProcessId -ErrorAction Stop
                            $startTime = $process.StartTime
                        }
                        catch {
                            Write-Debug "Не удалось получить время запуска процесса для службы $name"
                        }
                    }

                    $results += [PSCustomObject]@{
                        Name      = $service.Name
                        State     = $service.State
                        StartMode = $service.StartMode
                        ProcessId = $service.ProcessId
                        StartTime = $startTime
                    }
                }
                else {
                    Write-Warning "Служба '$name' не найдена"
                }
            }
            catch {
                Write-Warning "Ошибка CIM при проверке службы $name"
            }
        }
        else {
            try {
                $service = Get-WmiObject -ClassName Win32_Service -Filter "Name='$name'" -ErrorAction Stop
                
                if ($service) {
                    $startTime = $null
                    if ($service.State -eq 'Running' -and $service.ProcessId -gt 0) {
                        try {
                            $process = Get-Process -Id $service.ProcessId -ErrorAction Stop
                            $startTime = $process.StartTime
                        }
                        catch {
                            Write-Debug "Не удалось получить время запуска процесса для службы $name"
                        }
                    }

                    $results += [PSCustomObject]@{
                        Name      = $service.Name
                        State     = $service.State
                        StartMode = $service.StartMode
                        ProcessId = $service.ProcessId
                        StartTime = $startTime
                    }
                }
                else {
                    Write-Warning "Служба '$name' не найдена"
                }
            }
            catch {
                Write-Warning "Ошибка WMI при проверке службы $name"
            }
        }
    }

    return $results
}

Get-ServicesInfo | Format-Table -AutoSize -Wrap