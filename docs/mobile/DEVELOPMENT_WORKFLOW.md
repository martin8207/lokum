# Lokum Mobile Development Workflow

## Sprint Process

1. Receive Sprint package
2. Copy or replace files
3. Format code

```powershell
dart format .
```

4. Update dependencies if pubspec.yaml changed

```powershell
flutter pub get
```

5. Analyze project

```powershell
flutter analyze
```

6. Run tests

```powershell
flutter test
```

7. Start application

```powershell
flutter run
```

8. Visual verification
- UI
- Console
- Device behavior

9. Git check

```powershell
git status
```

10. Commit and push

```powershell
git add .
git commit -m "Sprint XX - description"
git push
```

## Rules

- No push with compilation errors.
- Every Sprint must be stable.
- One Sprint = one completed feature.
