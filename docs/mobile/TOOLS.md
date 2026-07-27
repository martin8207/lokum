# Lokum Mobile Development Tools

## Operating System

- Windows 11

## IDE

- Visual Studio Code

## Framework

- Flutter
- Dart

## Mobile

- Android SDK
- Android Emulator

## Version Control

- Git
- GitHub

## Recommended VS Code Extensions

- Flutter
- Dart
- Continue
- YAML (Red Hat)
- Error Lens
- Pubspec Assist
- Flutter Widget Snippets

## Infrastructure Related

- Ubuntu Server 26.04
- Docker
- Docker Compose
- Nginx
- PostgreSQL

## Data Tools (Python)

`tools/excel_to_json.py` regenerates `mobile/assets/data/menu.json` from
`database/excel/products_master.xlsx` — this is the file the app actually
reads. Run it after every menu update in the spreadsheet:

```powershell
pip install -r tools/requirements.txt
python tools/excel_to_json.py
```
