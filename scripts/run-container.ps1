param(
  [ValidateSet("up", "down", "reset", "logs", "status", "auth-claude", "auth-codex", "help")]
  [string] $Command = "up"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

function Show-Usage {
  @"
Usage: pwsh scripts/run-container.ps1 [up|down|reset|logs|status|auth-claude|auth-codex|help]

Windows uses Docker Compose:
  up           Build and start OpenAlice
  down         Stop OpenAlice
  reset        Stop OpenAlice and delete the persistent volume
  logs         Follow OpenAlice logs
  status       Show Compose service status
  auth-claude  Run Claude OAuth in the container
  auth-codex   Run Codex OAuth in the container
"@
}

function Invoke-DockerCompose {
  docker compose @args
}

switch ($Command) {
  "help" { Show-Usage }
  "up" { Invoke-DockerCompose up -d --build }
  "down" { Invoke-DockerCompose down }
  "reset" { Invoke-DockerCompose down -v }
  "logs" { Invoke-DockerCompose logs -f openalice }
  "status" { Invoke-DockerCompose ps }
  "auth-claude" { Invoke-DockerCompose exec --user node openalice claude }
  "auth-codex" { Invoke-DockerCompose exec --user node openalice codex login }
}
