"""Weekly availability parsing, validation, and appointment window checks."""

from __future__ import annotations

import re
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import HTTPException
from pydantic import BaseModel, Field, model_validator
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

# Wall-clock weekly template; keys stable for API/i18n.
WEEKDAY_KEYS: Tuple[str, ...] = ("mon", "tue", "wed", "thu", "fri", "sat", "sun")

INTERVAL_PATTERN = re.compile(r"^(\d{2}):(\d{2})-(\d{2}):(\d{2})$")

MIN_INTERVAL_MINUTES = 15
MAX_INTERVALS_PER_DAY = 8


class WeeklyAvailability(BaseModel):
    """Half-open intervals per day: [start, end) in wall-clock minutes."""

    mon: List[str] = Field(default_factory=list)
    tue: List[str] = Field(default_factory=list)
    wed: List[str] = Field(default_factory=list)
    thu: List[str] = Field(default_factory=list)
    fri: List[str] = Field(default_factory=list)
    sat: List[str] = Field(default_factory=list)
    sun: List[str] = Field(default_factory=list)

    @model_validator(mode="before")
    @classmethod
    def coerce_keys(cls, data: Any) -> Any:
        if data is None:
            return {k: [] for k in WEEKDAY_KEYS}
        if not isinstance(data, dict):
            raise ValueError("available_slots must be an object with weekday keys")
        out: Dict[str, List[str]] = {}
        for key in WEEKDAY_KEYS:
            v = data.get(key, [])
            if v is None:
                out[key] = []
            elif isinstance(v, list):
                out[key] = [str(x).strip() for x in v if str(x).strip()]
            else:
                raise ValueError(f"{key}: expected a list of interval strings")
        return out

    @model_validator(mode="after")
    def validate_intervals(self) -> WeeklyAvailability:
        for key in WEEKDAY_KEYS:
            intervals: List[str] = getattr(self, key)
            if len(intervals) > MAX_INTERVALS_PER_DAY:
                raise ValueError(f"{key}: at most {MAX_INTERVALS_PER_DAY} intervals per day")
            parsed: List[Tuple[int, int]] = []
            for s in intervals:
                start_m, end_m = parse_interval_string(s)
                if end_m - start_m < MIN_INTERVAL_MINUTES:
                    raise ValueError(
                        f"{key}: each interval must be at least {MIN_INTERVAL_MINUTES} minutes ({s})"
                    )
                parsed.append((start_m, end_m))
            parsed.sort(key=lambda x: x[0])
            for i in range(len(parsed) - 1):
                if parsed[i][1] > parsed[i + 1][0]:
                    raise ValueError(f"{key}: overlapping intervals")
        return self


def parse_interval_string(s: str) -> Tuple[int, int]:
    m = INTERVAL_PATTERN.match(s.strip())
    if not m:
        raise ValueError(f"Invalid interval format (expected HH:mm-HH:mm): {s!r}")
    h1, mn1, h2, mn2 = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
    if h1 > 23 or mn1 > 59 or h2 > 23 or mn2 > 59:
        raise ValueError(f"Invalid time in interval: {s!r}")
    start_m = h1 * 60 + mn1
    end_m = h2 * 60 + mn2
    if end_m <= start_m:
        raise ValueError(
            "Overnight intervals are not supported; end must be after start on the same day"
        )
    return start_m, end_m


def weekly_availability_to_storage_dict(model: WeeklyAvailability) -> Dict[str, List[str]]:
    out: Dict[str, List[str]] = {}
    for key in WEEKDAY_KEYS:
        raw: List[str] = getattr(model, key)
        normalized: List[str] = []
        for s in raw:
            start_m, end_m = parse_interval_string(s)
            normalized.append(
                f"{start_m // 60:02d}:{start_m % 60:02d}-{end_m // 60:02d}:{end_m % 60:02d}"
            )

        def sort_key(item: str) -> int:
            a, _ = parse_interval_string(item)
            return a

        normalized.sort(key=sort_key)
        out[key] = normalized
    return out


def try_parse_weekly(data: Any) -> Optional[WeeklyAvailability]:
    if data is None:
        return WeeklyAvailability()
    try:
        return WeeklyAvailability.model_validate(data)
    except ValueError:
        return None


def legacy_availability_not_configured(raw: Any) -> bool:
    """True when doctor has never set structured weekly data (legacy row)."""
    if raw is None:
        return True
    if isinstance(raw, dict) and len(raw) == 0:
        return True
    return False


def explicit_empty_week(raw: Any) -> bool:
    """True when structured data exists but every day has no intervals."""
    if legacy_availability_not_configured(raw):
        return False
    model = try_parse_weekly(raw)
    if model is None:
        return False
    return not any(len(getattr(model, k)) > 0 for k in WEEKDAY_KEYS)


def has_any_slot(raw: Any) -> bool:
    if legacy_availability_not_configured(raw):
        return False
    model = try_parse_weekly(raw)
    if model is None:
        return False
    return any(len(getattr(model, k)) > 0 for k in WEEKDAY_KEYS)


def resolve_zoneinfo(tz_name: str) -> ZoneInfo:
    try:
        return ZoneInfo(tz_name.strip())
    except ZoneInfoNotFoundError as e:
        raise HTTPException(status_code=400, detail=f"Unknown availability_timezone: {tz_name}") from e


def appointment_start_fits_availability(
    scheduled_at_utc: datetime,
    weekly_dict: Dict[str, Any],
    tz_name: str,
) -> bool:
    tz = resolve_zoneinfo(tz_name)
    local = scheduled_at_utc.astimezone(tz)
    wd = local.weekday()
    key = WEEKDAY_KEYS[wd]

    model = try_parse_weekly(weekly_dict)
    if model is None:
        return False
    intervals: List[str] = getattr(model, key)
    minutes_floor = local.hour * 60 + local.minute

    for s in intervals:
        start_m, end_m = parse_interval_string(s)
        if start_m <= minutes_floor < end_m:
            return True
    return False


def normalize_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def validate_timezone_required_for_slots(
    available_slots: Optional[Dict[str, Any]],
    availability_timezone: Optional[str],
) -> None:
    if has_any_slot(available_slots) and not (availability_timezone and availability_timezone.strip()):
        raise HTTPException(
            status_code=400,
            detail="availability_timezone is required when weekly hours are set",
        )
