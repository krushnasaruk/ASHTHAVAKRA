<!-- OFA:START -->

## ONEFORALL — Zone Ownership (Auto-generated)

> ⚠️ This section is managed by ONEFORALL (ofa). Do not edit manually.
> Edit `.ofa/config.yml` and run `ofa sync` to update.

This project uses zone-based ownership for multi-developer AI collaboration.

### Current Ownership Map

| Zone | Owner | Paths | Notes |
|------|-------|-------|-------|
| frontend | @Bot | mobile/lib/screens/, mobile/lib/widgets/, mobile/packages/h10_core/lib/theme/, docs/vaishnavi_jare/ | Mobile & Web Patient UI screens, widgets, design tokens, and designer docs |
| backend | _unclaimed_ | backend/, simulator/ | FastAPI backend server, SQLite database, and ESP32 device simulator |
| shared | _unclaimed_ | shared/, mobile/packages/h10_core/ | Signal processing, protocols, and shared JSON schemas |
| ml | _unclaimed_ | ml/ | ML pipeline, Colab notebooks, and feature extraction |
| docs | _unclaimed_ | docs/ | Project documentation suite |

### Rules

1. **Check zone ownership before editing any file.**
2. **Do NOT modify files in zones owned by another developer.**
3. **Shared zones require review from all active zone owners.**
4. **Use feature branches, never commit to main directly.**
5. **Run `ofa guard` before committing to verify boundaries.**

### Additional Rules

- Never modify files outside your claimed zone without prior approval
- Preserve mandatory non-medical disclaimer banner across all screens
- Use Okabe-Ito color-blind safe palette for all 5 finger channels
- Maintain minimum 48x48 px touch targets for patient accessibility
- Ensure responsive layout within 440px mobile canvas container

<!-- OFA:END -->