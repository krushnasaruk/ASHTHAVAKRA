# H10 — Clinician Web Dashboard

The Clinician Web Dashboard (`admin/`) is an interactive desktop portal designed for physiotherapists to monitor rehabilitation progress, review movement quality alerts, and manage exercise prescriptions.

---

## 1. User Interface Structure

```mermaid
flowchart TD
    DASH[Clinician Dashboard Shell] --> TOP[Header: Clinic Name, Clinician ID, Connectivity Pill, Disclaimer]
    DASH --> RAIL[Navigation Rail: Overview, Patients, Audit Log]
    RAIL --> V_OVER[View 1: Clinical Overview]
    RAIL --> V_LIST[View 2: Enrolled Research Cohort]
    RAIL --> V_AUDIT[View 4: Clinical Action Audit Log]
    V_LIST -->|Select Patient| V_DET[View 3: Patient Detail]
    V_DET --> TAB_SESS[Tab 1: Sessions History & Breakdowns]
    V_DET --> TAB_PROG[Tab 2: Progress & Trend Trajectories]
    V_DET --> TAB_PLAN[Tab 3: Plan Versioning Editor]
    V_DET --> TAB_FLAG[Tab 4: Movement Flags & Review]
    V_DET --> TAB_EXP[Tab 5: PDF Report & Telemetry Export]
```

---

## 2. Views & Workflow

### 2.1 View 1: Clinical Overview
- **Metric Cards:**
  - Active Patients (Total enrolled in research study).
  - Open Clinical Flags (Amber warning alert with count of unreviewed items).
  - Sessions Completed Today (Daily adherence tracking).
  - 7-Day Adherence Rate (Cohort-wide average compliance percentage).
- **Priority Movement Flags Feed:**
  - Real-time feed of open movement alerts across all patients.
  - 1-Click "Acknowledge" button opening an interactive clinical review dialog.

### 2.2 View 2: Patient List
- Searchable and filterable table of all enrolled patients.
- Filter by affected side (`all`, `left`, `right`, `bilateral`).
- Direct indicators for baseline establishment status (`Established` vs `In Progress`).
- Quick navigation button to inspect individual patient telemetry.

### 2.3 View 3: Patient Detail (5 Tabs)
1. **Sessions:** Chronological session history with expandable tiles revealing per-repetition kinematics, hold times, and fatigue drops.
2. **Progress & Trends:** Visual progress bars tracking active ROM over time, plus 5-channel finger mobility breakdown using the Okabe-Ito color-blind safe palette.
3. **Plan Editor:** Inspects active plan parameters. Clicking *"Update / Version Plan"* opens a validated dialog requiring clinical justification, archiving the old version and provisioning the new prescription.
4. **Flags & Alerts:** Complete log of patient flags, highlighting severity (`review` vs `info`), rules violated, and clinician review notes.
5. **Export & Raw Data:**
   - **1-Click PDF Report:** Generates a publication-quality 1-page clinical rehabilitation summary report with mandatory non-medical prototype disclaimers.
   - **Telemetry CSV:** Exports raw session and repetition records for independent spreadsheet analysis or research statistics.

### 2.4 View 4: Clinical Action Audit Log
- Immutable chronological ledger recording all plan updates, versions, and flag acknowledgments with clinician identifiers and justifications.

