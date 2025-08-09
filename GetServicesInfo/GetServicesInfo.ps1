function Get-ServicesInfo {
    param (
        [string[]]$ServiceNames = @('dps','sysmain','pcasvc','appinfo','diagtrack','eventlog','bfe','msmpeng','dnscache')
    )

    $aliases = @{
        'msmpeng' = 'WinDefend'  
    }
    $normalized = foreach ($n in $ServiceNames) {
        if ($aliases.ContainsKey($n)) { $aliases[$n] } else { $n }
    }

    $results = @()

    foreach ($name in $normalized) {
        $useCim = [bool](Get-Command -Name Get-CimInstance -ErrorAction SilentlyContinue)
        try {
            $service = if ($useCim) {
                Get-CimInstance -ClassName Win32_Service -Filter "Name='$name'" -ErrorAction Stop
            } else {
                Get-WmiObject -Class Win32_Service -Filter "Name='$name'" -ErrorAction Stop
            }
        } catch {
            Write-Warning "Ошибка при проверке службы '${name}'"
            continue
        }

        if ($service) {
            $startTime = $null
            if ($service.State -eq 'Running' -and $service.ProcessId -gt 0) {
                try {
                    $process   = Get-Process -Id $service.ProcessId -ErrorAction Stop
                    $startTime = $process.StartTime
                } catch {
                    Write-Verbose "Не удалось получить время запуска процесса для службы ${name}"
                }
            }

            $results += [PSCustomObject]@{
                Name      = $service.Name
                State     = $service.State
                StartMode = $service.StartMode
                ProcessId = $service.ProcessId
                StartTime = $startTime
            }
        } else {
            Write-Warning "Служба '${name}' не найдена"
        }
    }

    return $results
}

function Start-ServiceSafe {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        $svc = Get-Service -Name $Name -ErrorAction Stop
    } catch {
        Write-Warning "Служба '${Name}' не найдена."
        return
    }

    if ($svc.Status -eq 'Running') {
        Write-Host "⏭ ${Name} уже запущена."
        return
    }

    foreach ($dep in $svc.ServicesDependedOn) {
        try {
            $depSvc = Get-Service -Name $dep.Name -ErrorAction Stop
            if ($depSvc.Status -ne 'Running') {
                try { Set-Service -Name $depSvc.Name -StartupType Manual -ErrorAction Stop } catch {}
                try {
                    Start-Service -Name $depSvc.Name -ErrorAction Stop
                } catch {
                    & sc.exe config $($depSvc.Name) start= demand | Out-Null
                    & sc.exe start  $($depSvc.Name)               | Out-Null
                }
            }
        } catch {
            Write-Warning "Не удалось обработать зависимость '${($dep.Name)}' для '${Name}': $($_.Exception.Message)"
        }
    }

    $setOk = $true
    try {
        Set-Service -Name $Name -StartupType Automatic -ErrorAction Stop
    } catch {
        $setOk = $false
    }
    if (-not $setOk) {
        & sc.exe config $Name start= auto | Out-Null
    }

    try {
        Start-Service -Name $Name -ErrorAction Stop
        Write-Host "✔ ${Name} запущена и переведена в Automatic"
    } catch {
        & sc.exe start $Name | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✔ ${Name} запущена (через sc.exe)"
        } else {
            Write-Warning "✖ Не удалось запустить/включить ${Name}: $($_.Exception.Message)"
        }
    }
}

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Скрипт запущен не от имени администратора. Возможны ошибки 'Отказано в доступе'."
}

Clear-Host

$services = Get-ServicesInfo
$idx = 1
$services | ForEach-Object { $_ | Add-Member -NotePropertyName Index -NotePropertyValue $idx -Force; $idx++ }
$services | Sort-Object Index | Format-Table Index, Name, State, StartMode, ProcessId, StartTime -AutoSize

$choice = Read-Host "Включить службы? (all - все / номера через запятую, напр.: 1,3,5 / пусто - отмена)"

if ($choice -eq 'all' -or $choice -match '^\s*\d+(\s*,\s*\d+)*\s*$') {

    $targets = if ($choice -eq 'all') {
        $services
    } else {
        $nums = $choice -split '\s*,\s*' | ForEach-Object {[int]$_}
        $services | Where-Object { $nums -contains $_.Index }
    }

    foreach ($svc in $targets) {
        Start-ServiceSafe -Name $svc.Name
    }

    Clear-Host
    Write-Host "Службы включены."
    $services = Get-ServicesInfo
    $idx = 1
    $services | ForEach-Object { $_ | Add-Member -NotePropertyName Index -NotePropertyValue $idx -Force; $idx++ }
    $services | Sort-Object Index | Format-Table Index, Name, State, StartMode, ProcessId, StartTime -AutoSize

} elseif ($choice -ne '') {
    Write-Host "Неверный ввод. Ожидалось 'all' или список номеров через запятую."
} else {
    Write-Host "Ок, без изменений."
}
