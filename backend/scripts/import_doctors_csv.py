"""Import doctor records from a CSV file into the database.

Expected CSV columns:
- Doctor Name
- Doctor Profile URL
- Doctor Image
- Experience (Years)
- Specialties
- Rating (Max 5)
- Consultation Fee (BDT)

Run from the backend folder, for example:
python scripts/import_doctors_csv.py scripts/data/doctors.csv
"""

from __future__ import annotations

import argparse
import asyncio
import csv
import hashlib
import re
import sys
from decimal import Decimal
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_ROOT = SCRIPT_DIR.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

import app.modules.ai.models  # noqa: F401
from app.core.security import hash_password
from app.database.session import AsyncSessionLocal
from app.modules.auth.models import User
from app.modules.users.models import DoctorProfile
from sqlalchemy import select

DEFAULT_CSV_PATH = SCRIPT_DIR / "data" / "doctors.csv"
PLACEHOLDER_PASSWORD = "imported-doctor-account"


def _clean(value: Any) -> str:
    if value is None:
        return ""
    return str(value).strip()


def _slugify(value: str, max_length: int = 48) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug[:max_length] or "doctor"


def _short_hash(value: str) -> str:
    return hashlib.sha1(value.encode("utf-8")).hexdigest()[:10]


def _parse_decimal(value: str) -> Decimal | None:
    value = _clean(value)
    if not value:
        return None
    return Decimal(value)


def _parse_int(value: str) -> int | None:
    value = _clean(value)
    if not value:
        return None
    return int(float(value))


def _build_identity(row: dict[str, str], row_number: int) -> tuple[str, str]:
    doctor_name = _clean(row.get("Doctor Name"))
    source_url = _clean(row.get("Doctor Profile URL"))
    seed = source_url or f"{doctor_name}:{row_number}"
    slug = _slugify(doctor_name or source_url or f"doctor-{row_number}")
    digest = _short_hash(seed)
    email = f"{slug}.{digest}@doctime-import.local"
    license_number = f"CSV-{digest.upper()}"
    return email, license_number


async def upsert_doctor(row: dict[str, str], row_number: int) -> str:
    full_name = _clean(row.get("Doctor Name"))
    source_profile_url = _clean(row.get("Doctor Profile URL"))
    profile_image_url = _clean(row.get("Doctor Image"))
    specialization = _clean(row.get("Specialties"))
    if not full_name:
        return f"row {row_number}: skipped because Doctor Name is empty"

    email, license_number = _build_identity(row, row_number)
    consultation_fee = _parse_decimal(row.get("Consultation Fee (BDT)"))
    rating = _parse_decimal(row.get("Rating (Max 5)"))
    years_experience = _parse_int(row.get("Experience (Years)"))

    async with AsyncSessionLocal() as session:
        user_result = await session.execute(select(User).where(User.email == email))
        user = user_result.scalar_one_or_none()
        if not user:
            user = User(
                email=email,
                password_hash=hash_password(PLACEHOLDER_PASSWORD),
                role="doctor",
                is_active=True,
                is_verified=True,
            )
            session.add(user)
            await session.flush()

        profile_result = await session.execute(
            select(DoctorProfile).where(DoctorProfile.source_profile_url == source_profile_url)
            if source_profile_url
            else select(DoctorProfile).where(DoctorProfile.user_id == user.id)
        )
        profile = profile_result.scalar_one_or_none()

        if not profile:
            profile = DoctorProfile(
                user_id=user.id,
                full_name=full_name,
                specialization=specialization,
                license_number=license_number,
            )
            session.add(profile)

        profile.full_name = full_name
        profile.specialization = specialization
        profile.license_number = license_number
        profile.source_profile_url = source_profile_url or None
        profile.profile_image_url = profile_image_url or None
        profile.consultation_fee = consultation_fee
        profile.rating = rating or Decimal("0")
        profile.years_experience = years_experience

        await session.commit()

    return f"imported {full_name}"


async def run_import(csv_path: Path) -> None:
    if not csv_path.exists():
        raise FileNotFoundError(f"CSV file not found: {csv_path}")

    with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)

    if not rows:
        print(f"No rows found in {csv_path}")
        return

    imported = 0
    skipped = 0

    for index, row in enumerate(rows, start=2):
        result = await upsert_doctor(row, index)
        if result.startswith("row ") and "skipped" in result:
            skipped += 1
        else:
            imported += 1
        print(result)

    print(f"Done. Imported: {imported}, skipped: {skipped}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Import doctors from a CSV file into the database")
    parser.add_argument(
        "csv_path",
        nargs="?",
        default=str(DEFAULT_CSV_PATH),
        help=f"Path to the doctor CSV file (default: {DEFAULT_CSV_PATH})",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    asyncio.run(run_import(Path(args.csv_path)))


if __name__ == "__main__":
    main()