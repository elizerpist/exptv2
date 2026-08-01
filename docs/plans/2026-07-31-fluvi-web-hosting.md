# Fluvi release web hosting acceptance checklist

| ID | Source instruction | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| WEB-01 | User: make the Fluvi worktree a release Flutter web host | `web/` platform scaffold | The Flutter project is configured for the web and has the required web entrypoint/assets | `flutter build web --release` → `✓ Built build/web` | DONE |
| WEB-02 | User: run it and provide a browser link | `build/web` serving process | The release output is served over HTTP and returns the Fluvi app entrypoint | `curl -I http://127.0.0.1:8090/` → `200 OK`; entrypoint content checked | DONE |
| WEB-03 | User: Fluvi uses its own explicit assets | `pubspec.yaml`, `assets/fluvi/` | Brand and action SVGs are registered explicitly and are present in the release output | Boundary test; build tree and HTTP checks return `200` for all three SVGs | DONE |
