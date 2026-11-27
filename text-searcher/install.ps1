Write-Host "=== Установка утилиты fsearch ===" -ForegroundColor Cyan

# Параметры репозитория dancheks/PyHelpers
$domain  = "raw." + "githubusercontent.com"
$user    = "dancheks"
$repo    = "PyHelpers"
$branch  = "main"
$folder  = "text-searcher"
$baseUrl = "https://$domain/$user/$repo/$branch/$folder"

$files   = @("pyproject.toml", "search_tool.py", "requirements.txt")

# 1. Проверяем, установлен ли Python
$pythonExists = Get-Command python -ErrorAction SilentlyContinue

if (-not $pythonExists) {
    Write-Host "[1/5] Python не найден. Устанавливаю через winget..." -ForegroundColor Yellow
    winget install -e --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "[1/5] Python уже установлен." -ForegroundColor Green
}

# 2. Создаём временную папку и скачиваем туда файлы утилиты
Write-Host "[2/5] Скачивание файлов из dancheks/PyHelpers..." -ForegroundColor Yellow
$tempDir = Join-Path $env:TEMP "fsearch_install_$(Get-Random)"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

try {
    foreach ($file in $files) {
        $fileUrl = "$baseUrl/$file"
        $destPath = Join-Path $tempDir $file
        try {
            Invoke-WebRequest -Uri $fileUrl -OutFile $destPath -ErrorAction Stop
        } catch {
            # Если requirements.txt отсутствует в папке, пропускаем без ошибки
            if ($file -ne "requirements.txt") {
                throw "Не удалось скачать обязательный файл $file ($fileUrl)"
            }
        }
    }

    Push-Location $tempDir

    # 3. Устанавливаем зависимости, если requirements.txt существует и не пустой
    if ((Test-Path "requirements.txt") -and ((Get-Item "requirements.txt").Length -gt 0)) {
        Write-Host "[3/5] Установка библиотек из requirements.txt..." -ForegroundColor Yellow
        python -m pip install --upgrade pip --quiet
        python -m pip install -r requirements.txt --quiet
    } else {
        Write-Host "[3/5] Дополнительные библиотеки не требуются." -ForegroundColor Green
    }

    # 4. Устанавливаем пакет и регистрируем команду fsearch
    Write-Host "[4/5] Регистрация команды fsearch..." -ForegroundColor Yellow
    python -m pip install . --quiet

} finally {
    Pop-Location
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

# 5. Проверяем и обновляем PATH
Write-Host "[5/5] Проверка переменной PATH..." -ForegroundColor Yellow
$scriptsDir = python -c "import sysconfig; print(sysconfig.get_path('scripts'))"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($userPath -notlike "*$scriptsDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$scriptsDir", "User")
    Write-Host "Путь $scriptsDir добавлен в PATH." -ForegroundColor Green
} else {
    Write-Host "Путь уже присутствует в PATH." -ForegroundColor Green
}

Write-Host "`nГотово! Перезапустите терминал и используйте: fsearch ""A1""" -ForegroundColor Cyan
