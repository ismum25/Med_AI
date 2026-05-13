"""Set common availability slots for all doctors.

This script assigns the same weekly availability to all doctors who don't already have slots.
You can customize the slots and timezone in the script.

Run from the backend folder:
python scripts/set_doctor_availability.py
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
BACKEND_ROOT = SCRIPT_DIR.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

import app.modules.ai.models  # noqa: F401
from app.database.session import AsyncSessionLocal
from app.modules.auth.models import User
from app.modules.users.availability import (
    WEEKDAY_KEYS,
    WeeklyAvailability,
    weekly_availability_to_storage_dict,
)
from app.modules.users.models import DoctorProfile
from sqlalchemy import select

# Default slots: 9 AM to 5 PM on all days
DEFAULT_SLOTS = "09:00-17:00"
DEFAULT_TIMEZONE = "Asia/Dhaka"


async def set_availability(
    slots: str = DEFAULT_SLOTS,
    timezone: str = DEFAULT_TIMEZONE,
    skip_existing: bool = True,
) -> None:
    """Set availability for all doctors.
    
    Args:
        slots: Time interval string like "09:00-17:00"
        timezone: IANA timezone name like "Asia/Dhaka"
        skip_existing: If True, only update doctors with no existing slots
    """
    try:
        model = WeeklyAvailability(**{key: [slots] for key in WEEKDAY_KEYS})
        slot_dict = weekly_availability_to_storage_dict(model)
        print(f"Setting slots: {slots}")
        print(f"Timezone: {timezone}")
        print(f"Weekday structure:\n{slot_dict}\n")
    except ValueError as e:
        print(f"Error: Invalid slots format or timezone: {e}")
        return

    async with AsyncSessionLocal() as session:
        result = await session.execute(select(DoctorProfile))
        doctors = result.scalars().all()

        if not doctors:
            print("No doctors found in database.")
            return

        updated = 0
        skipped = 0

        for doctor in doctors:
            has_existing_slots = doctor.available_slots and any(
                doctor.available_slots.get(k) for k in WEEKDAY_KEYS
            )

            if has_existing_slots and skip_existing:
                print(f"Skipped {doctor.full_name} (already has availability)")
                skipped += 1
                continue

            doctor.available_slots = slot_dict
            doctor.availability_timezone = timezone
            updated += 1
            print(f"Updated {doctor.full_name}")

        await session.commit()

    print(f"\nDone. Updated: {updated}, skipped: {skipped}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Set common availability slots for all doctors"
    )
    parser.add_argument(
        "--slots",
        default=DEFAULT_SLOTS,
        help=f"Time slot format HH:mm-HH:mm (default: {DEFAULT_SLOTS})",
    )
    parser.add_argument(
        "--timezone",
        default=DEFAULT_TIMEZONE,
        help=f"IANA timezone (default: {DEFAULT_TIMEZONE})",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Update even if doctor already has availability set",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    asyncio.run(
        set_availability(
            slots=args.slots,
            timezone=args.timezone,
            skip_existing=not args.force,
        )
    )


if __name__ == "__main__":
    main()
