Write-Host "=== Установка утилиты fsearch ===" -ForegroundColor Cyan

# 1. Проверяем, установлен ли Python
$pythonExists = Get-Command python -ErrorAction SilentlyContinue

if (-not $pythonExists) {
    Write-Host "[1/4] Python не найден. Устанавливаю через winget..." -ForegroundColor Yellow
    winget install -e --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
    
    # Обновляем переменные окружения в текущей сессии
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "[1/4] Python уже установлен." -ForegroundColor Green
}

# 2. Устанавливаем зависимости из requirements.txt (если файл не пустой)
if (Test-Path "requirements.txt") {
    Write-Host "[2/4] Проверка и установка библиотек..." -ForegroundColor Yellow
    python -m pip install --upgrade pip --quiet
    python -m pip install -r requirements.txt --quiet
}

# 3. Устанавливаем саму утилиту как системный пакет
Write-Host "[3/4] Регистрация команды fsearch..." -ForegroundColor Yellow
python -m pip install . --quiet

# 4. Проверяем, есть ли папка Scripts от Python в пользовательском PATH
Write-Host "[4/4] Проверка переменной PATH..." -ForegroundColor Yellow
$scriptsDir = python -c "import sysconfig; print(sysconfig.get_path('scripts'))"
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

if ($userPath -notlike "*$scriptsDir*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$scriptsDir", "User")
    Write-Host "Путь $scriptsDir добавлен в PATH." -ForegroundColor Green
} else {
    Write-Host "Путь уже присутствует в PATH." -ForegroundColor Green
}

Write-Host "`nГотово! Перезапустите терминал и используйте команду: fsearch ""A1""" -ForegroundColor Cyan
