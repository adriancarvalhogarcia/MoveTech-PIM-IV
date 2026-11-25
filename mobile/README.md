# MoveTech Mobile

Código do aplicativo Flutter do MoveTech (PIM IV).

O passo a passo completo, as validações e a documentação técnica estão no
`README.md` da pasta acima. Os scripts da raiz do pacote já chamam os
scripts desta pasta:

| Script | Chamado por |
|---|---|
| `configurar.ps1` | `..\3_gerar_apk.ps1` e `..\5_rodar_no_emulador.ps1` |
| `gerar_apk.ps1` | `..\3_gerar_apk.ps1` |
| `configurar.sh` | GitHub Actions (`.github/workflows/gerar-apk.yml`) |

Comandos úteis dentro desta pasta, depois de configurada:

```powershell
flutter test       # testes de unidade
flutter analyze    # análise estática
flutter run        # roda no emulador ou no celular pelo cabo
```
