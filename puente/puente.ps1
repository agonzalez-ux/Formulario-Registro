# Puente local: recibe del totem (la web) el nombre de la empresa y se lo pasa
# a la controladora de proyectores para actualizar el "Welcome text".
#
#   web (https, GitHub Pages) -> http://localhost:8123/welcome?value=Acme
#   este script               -> http://192.168.1.82:8080/update?id=wellcomeName&value=Acme

$Controladora = 'http://192.168.1.82:8080'
$CampoId      = 'wellcomeName'
$Puerto       = 8123
$Log          = Join-Path $PSScriptRoot 'puente.log'

Add-Type -AssemblyName System.Web

function Escribir($msg){
  Add-Content -Path $Log -Value ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $msg)
  # el log no crece sin limite
  if((Get-Item $Log).Length -gt 200KB){ Get-Content $Log -Tail 200 | Set-Content $Log }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Puerto/")
$listener.Prefixes.Add("http://127.0.0.1:$Puerto/")
try { $listener.Start() } catch { Escribir "No se pudo abrir el puerto $Puerto (ya hay otro puente en marcha?): $($_.Exception.Message)"; exit 1 }
Escribir "Puente iniciado en el puerto $Puerto -> $Controladora"

while($listener.IsListening){
  $ctx = $listener.GetContext()
  $req = $ctx.Request; $res = $ctx.Response
  try {
    # permisos para que la web (otro origen, https) pueda llamarnos
    $res.Headers.Add('Access-Control-Allow-Origin', '*')
    $res.Headers.Add('Access-Control-Allow-Methods', 'GET, OPTIONS')
    $res.Headers.Add('Access-Control-Allow-Headers', '*')
    $res.Headers.Add('Access-Control-Allow-Private-Network', 'true')

    if($req.HttpMethod -eq 'OPTIONS'){
      $res.StatusCode = 204
    }
    elseif($req.Url.AbsolutePath -eq '/welcome'){
      $valor = [System.Web.HttpUtility]::ParseQueryString($req.Url.Query)['value']
      if([string]::IsNullOrWhiteSpace($valor)){ $res.StatusCode = 400 }
      else {
        $url = "$Controladora/update?id=$([uri]::EscapeDataString($CampoId))&value=$([uri]::EscapeDataString($valor))"
        try {
          $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
          Escribir "OK  '$valor' -> controladora ($($r.StatusCode))"
          $res.StatusCode = 200
        } catch {
          Escribir "ERROR  '$valor' -> controladora: $($_.Exception.Message)"
          $res.StatusCode = 502
        }
      }
    }
    elseif($req.Url.AbsolutePath -eq '/ping'){ $res.StatusCode = 200 }
    else { $res.StatusCode = 404 }
  } catch {
    Escribir "ERROR interno: $($_.Exception.Message)"
    try { $res.StatusCode = 500 } catch {}
  } finally {
    $res.Close()
  }
}
