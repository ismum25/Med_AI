import uuid
from typing import Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

TOOLS = [
    {
        "name": "get_patient_profile",
        "description": "Retrieve a patient's profile information including name, blood type, and allergies.",
        "input_schema": {
            "type": "object",
            "properties": {
                "patient_id": {"type": "string", "description": "UUID of the patient"}
            },
            "required": ["patient_id"],
        },
    },
    {
        "name": "get_medical_reports",
        "description": "Get a list of verified medical reports for a patient with extracted data.",
        "input_schema": {
            "type": "object",
            "properties": {
                "patient_id": {"type": "string", "description": "UUID of the patient"},
                "report_type": {"type": "string", "description": "Filter by: blood_test, xray, mri, urine, other"},
                "limit": {"type": "integer", "default": 5},
            },
            "required": ["patient_id"],
        },
    },
    {
        "name": "get_appointments",
        "description": "Get appointments for the current user.",
        "input_schema": {
            "type": "object",
            "properties": {
                "status": {"type": "string", "description": "Filter: pending, confirmed, completed, cancelled"},
                "limit": {"type": "integer", "default": 5},
            },
        },
    },
    {
        "name": "search_lab_trends",
        "description": "Get historical values for a specific lab parameter to show trends over time.",
        "input_schema": {
            "type": "object",
            "properties": {
                "patient_id": {"type": "string", "description": "UUID of the patient"},
                "parameter_name": {"type": "string", "description": "Lab parameter name e.g. Hemoglobin, Glucose"},
            },
            "required": ["patient_id", "parameter_name"],
        },
    },
]


async def execute_tool(
    tool_name: str,
    tool_input: Dict[str, Any],
    caller_id: uuid.UUID,
    caller_role: str,
    db: AsyncSession,
) -> str:
    from app.modules.users.models import PatientProfile
    from app.modules.reports.models import MedicalReport, ExtractedReportData
    from app.modules.appointments.models import Appointment

    if tool_name == "get_patient_profile":
        patient_id = uuid.UUID(tool_input["patient_id"])
        if caller_role == "patient" and patient_id != caller_id:
            return '{"error": "Access denied"}'

        result = await db.execute(select(PatientProfile).where(PatientProfile.user_id == patient_id))
        patient = result.scalar_one_or_none()
        if not patient:
            return '{"error": "Patient not found"}'

        return str({
            "full_name": patient.full_name,
            "date_of_birth": patient.date_of_birth,
            "blood_type": patient.blood_type,
            "allergies": patient.allergies,
        })

    elif tool_name == "get_medical_reports":
        patient_id = uuid.UUID(tool_input["patient_id"])
        if caller_role == "patient" and patient_id != caller_id:
            return '{"error": "Access denied"}'

        limit = tool_input.get("limit", 5)
        report_type = tool_input.get("report_type")

        query = select(MedicalReport).where(
            MedicalReport.patient_id == patient_id,
            MedicalReport.ocr_status == "verified",
        )
        if report_type:
            query = query.where(MedicalReport.report_type == report_type)
        query = query.order_by(MedicalReport.created_at.desc()).limit(limit)

        reports_result = await db.execute(query)
        reports = reports_result.scalars().all()

        summaries = []
        for r in reports:
            ext_result = await db.execute(
                select(ExtractedReportData).where(ExtractedReportData.report_id == r.id)
            )
            ext = ext_result.scalar_one_or_none()
            summaries.append({
                "report_id": str(r.id),
                "title": r.title,
                "type": r.report_type,
                "date": r.report_date,
                "data": ext.data if ext else None,
            })
        return str(summaries)

    elif tool_name == "get_appointments":
        limit = tool_input.get("limit", 5)
        status_filter = tool_input.get("status")

        if caller_role == "doctor":
            query = select(Appointment).where(Appointment.doctor_id == caller_id)
        else:
            query = select(Appointment).where(Appointment.patient_id == caller_id)

        if status_filter:
            query = query.where(Appointment.status == status_filter)
        query = query.order_by(Appointment.scheduled_at.desc()).limit(limit)

        result = await db.execute(query)
        appointments = result.scalars().all()
        return str([{
            "id": str(a.id),
            "scheduled_at": str(a.scheduled_at),
            "status": a.status,
            "reason": a.reason,
        } for a in appointments])

    elif tool_name == "search_lab_trends":
        patient_id = uuid.UUID(tool_input["patient_id"])
        if caller_role == "patient" and patient_id != caller_id:
            return '{"error": "Access denied"}'

        parameter_name = tool_input["parameter_name"].lower()
        query = (
            select(MedicalReport, ExtractedReportData)
            .join(ExtractedReportData, ExtractedReportData.report_id == MedicalReport.id)
            .where(MedicalReport.patient_id == patient_id, MedicalReport.ocr_status == "verified")
            .order_by(MedicalReport.report_date)
        )
        result = await db.execute(query)
        trends = []
        for report, ext_data in result.all():
            if ext_data and ext_data.data:
                for item in ext_data.data.get("results", []):
                    if parameter_name in item.get("parameter", "").lower():
                        trends.append({
                            "date": report.report_date,
                            "value": item.get("value"),
                            "unit": item.get("unit"),
                            "flag": item.get("flag"),
                        })
        return str({"parameter": tool_input["parameter_name"], "trend": trends})

    return '{"error": "Unknown tool"}'
