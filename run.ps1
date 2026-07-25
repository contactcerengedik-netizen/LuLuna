# Luluna'yı Gemini + Supabase anahtarlarıyla çalıştırır.
# Anahtarlar config/gemini.json içinde (git-ignored) tutulur.
# Kullanım:  ./run.ps1            (varsayılan cihaz)
#            ./run.ps1 -d chrome  (belirli cihaz)

param(
    [string]$d = ""
)

$configFile = "config/gemini.json"
if (-not (Test-Path $configFile)) {
    Write-Error "config/gemini.json bulunamadi. config/gemini.example.json'u kopyalayip anahtarlarinizi yazin."
    exit 1
}

$flutterArgs = @("run", "--dart-define-from-file=$configFile")
if ($d -ne "") {
    $flutterArgs += @("-d", $d)
}

flutter @flutterArgs
