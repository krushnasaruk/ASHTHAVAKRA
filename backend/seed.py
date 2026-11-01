"""
Demo seed script for H10 backend database.
Loads demo patients, plans, sessions, and flags.
All synthetic/demo records are explicitly labelled data_source = 'simulated'.
"""
import uuid
from datetime import datetime, timedelta
from backend.database import SessionLocal, Base, engine
from backend.models import PatientModel, PlanModel, SessionModel, RepetitionModel, FlagModel

Base.metadata.create_all(bind=engine)


def seed_database():
    db = SessionLocal()
    try:
        # Check if already seeded
        if db.query(PatientModel).count() > 0:
            print("Database already contains data; skipping seed.")
            return

        print("Seeding H10 demo database with simulated data...")
        now = datetime.utcnow()

        # Patients
        p1 = PatientModel(id=str(uuid.uuid4()), pseudonym="P-001", affected_hand="right", notes="Post-stroke rehabilitation trial", data_source="simulated")
        p2 = PatientModel(id=str(uuid.uuid4()), pseudonym="P-002", affected_hand="left", notes="Tendon repair recovery", data_source="simulated")
        p3 = PatientModel(id=str(uuid.uuid4()), pseudonym="P-003", affected_hand="right", notes="Post-trauma hand stiffness", data_source="simulated")
        db.add_all([p1, p2, p3])
        db.commit()

        # Plans
        plan1 = PlanModel(
            id=str(uuid.uuid4()), patient_id=p1.id, exercise_id="fist_clench",
            target_reps=10, target_rom_min=70.0, target_rom_max=100.0,
            hold_s=0.5, rest_s=2.0, sessions_per_week=5,
            stop_instruction="Stop if you feel sharp pain. Rest as needed.",
            fatigue_drop_threshold=20.0, valid_from=now - timedelta(days=14),
            set_by="Dr. Physiotherapist A", version=1
        )
        plan2 = PlanModel(
            id=str(uuid.uuid4()), patient_id=p2.id, exercise_id="finger_tap",
            target_reps=15, target_rom_min=65.0, target_rom_max=95.0,
            hold_s=0.3, rest_s=1.5, sessions_per_week=4,
            stop_instruction="Stop if you feel sharp pain. Rest as needed.",
            fatigue_drop_threshold=20.0, valid_from=now - timedelta(days=10),
            set_by="Dr. Physiotherapist B", version=1
        )
        db.add_all([plan1, plan2])
        db.commit()

        # Sessions for P1 (4 sessions)
        for i in range(4):
            s_time = now - timedelta(days=4 - i)
            s_id = str(uuid.uuid4())
            session = SessionModel(
                id=s_id,
                patient_id=p1.id,
                exercise_code="fist_clench",
                plan_version=1,
                started_at=s_time,
                ended_at=s_time + timedelta(seconds=120),
                duration_s=120.0,
                reps_completed=10,
                reps_target=10,
                reps_interrupted=0,
                mean_rom=60.0 + (i * 3.0), # Improving from 60 to 69
                max_rom=75.0 + (i * 2.0),
                mean_rep_duration_s=2.1,
                smoothness=0.82,
                hold_s=0.5,
                consistency=85.0 + i,
                consistency_components={"rom_ratio": 0.9, "timing_score": 0.85, "smooth_score": 0.82, "is_available": True},
                fatigue_drop_pct=12.0,
                pain_before=2,
                pain_after=2,
                fatigue_before=2,
                fatigue_after=3,
                note=f"Demo session {i + 1}",
                data_quality="good",
                data_source="simulated",
                device_id="H10-SIM-01",
                firmware="1.0.0",
                calibration_ref=f"cal_{p1.id}",
                client_version="1.0.0",
                created_at=s_time,
                received_at=s_time,
                is_deleted=False
            )
            db.add(session)

            # Repetitions
            for r in range(10):
                rep = RepetitionModel(
                    id=str(uuid.uuid4()),
                    session_id=s_id,
                    index=r,
                    start_ms=r * 2000,
                    end_ms=(r + 1) * 2000,
                    duration_s=2.0,
                    peak=70.0 + (i * 2.0),
                    mean=45.0,
                    min=5.0,
                    rom=65.0 + (i * 2.0),
                    hold_s=0.5,
                    smoothness=0.82,
                    quality="good",
                    status="complete"
                )
                db.add(rep)

        # Flag for P1
        flag1 = FlagModel(
            id=f"flag_{p1.id}_rom_below_plan",
            patient_id=p1.id,
            type="rom_below_plan",
            severity="review",
            created_at=now - timedelta(days=1),
            session_ids=[],
            message="Mean ROM below 70% plan target in recent sessions.",
            metric_values={"3_session_mean": 63.0},
            threshold_used={"target_rom_min": 70.0}
        )
        db.add(flag1)

        db.commit()
        print("Database successfully seeded with 3 demo patients, plans, sessions, and flags.")
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()
