# Backend Scripts

## Doctor Availability Setup

### Set Common Availability for All Doctors

```bash
python scripts/set_doctor_availability.py
```

This sets the same availability slots (9 AM to 5 PM) across all days for every doctor who doesn't already have slots set.

**Options:**

- `--slots` — Time interval (default: `09:00-17:00`)
- `--timezone` — IANA timezone (default: `Asia/Dhaka`)
- `--force` — Update even if doctor already has availability

**Examples:**

Set 8 AM to 6 PM on all days:

```bash
python scripts/set_doctor_availability.py --slots 08:00-18:00
```

Use a different timezone:

```bash
python scripts/set_doctor_availability.py --timezone America/New_York
```

Override existing slots for all doctors:

```bash
python scripts/set_doctor_availability.py --force
```

---

## Doctor Data Import

### Import Doctors from CSV

```bash
alembic upgrade head
python scripts/import_doctors_csv.py scripts/data/doctors.csv
```

Place your CSV file in `scripts/data/doctors.csv` with columns:

- Doctor Name
- Doctor Profile URL
- Doctor Image
- Experience (Years)
- Specialties
- Rating (Max 5)
- Consultation Fee (BDT)
