import pytest
from datetime import datetime, timezone

from app.modules.users.availability import (
    WeeklyAvailability,
    appointment_start_fits_availability,
    explicit_empty_week,
    has_any_slot,
    legacy_availability_not_configured,
    normalize_utc,
    parse_interval_string,
    weekly_availability_to_storage_dict,
)


def test_parse_interval_string_valid():
    assert parse_interval_string("09:00-17:00") == (9 * 60, 17 * 60)


def test_parse_interval_string_rejects_overnight():
    with pytest.raises(ValueError):
        parse_interval_string("22:00-06:00")


def test_weekly_storage_normalizes_order():
    wa = WeeklyAvailability.model_validate(
        {
            "mon": ["14:00-18:00", "09:00-12:00"],
        }
    )
    d = weekly_availability_to_storage_dict(wa)
    assert d["mon"] == ["09:00-12:00", "14:00-18:00"]


def test_legacy_empty_dict():
    assert legacy_availability_not_configured({}) is True
    assert legacy_availability_not_configured(None) is True


def test_explicit_empty_week():
    payload = {k: [] for k in ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]}
    assert explicit_empty_week(payload) is True
    assert has_any_slot(payload) is False


def test_fits_availability_utc():
    weekly = {
        "mon": ["09:00-17:00"],
        "tue": [],
        "wed": [],
        "thu": [],
        "fri": [],
        "sat": [],
        "sun": [],
    }
    # Monday 2026-04-27 14:00 UTC (weekday Monday), inside [09:00,17:00) in UTC
    dt = datetime(2026, 4, 27, 14, 0, tzinfo=timezone.utc)
    assert appointment_start_fits_availability(dt, weekly, "UTC") is True
