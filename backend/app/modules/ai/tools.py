import json
import uuid
from typing import Any, Dict

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

TOOLS = [
    {
        "name": "get_patient_profile",
        "description": "Retrieve a patient's profile information including name, blood type, and allergies. For patients, patient_id is optional.",
        "input_schema": {
            "type": "object",
            "properties": {
                "patient_id": {"type": "string", "description": "UUID of the patient (optional for patients)"}
            },
        },
    },
    {
        "name": "get_medical_reports",
        "description": "Get a list of verified medical reports for a patient with extracted data. For patients, patient_id is optional.",
        "input_schema": {
            "type": "object",
            "properties": {
                "patient_id": {"type": "string", "description": "UUID of the patient (optional for patients)"},
                "report_type": {"type": "string", "description": "Filter by: blood_test, xray, mri, urine, other"},
                "limit": {"type": "integer", "default": 5},
            },
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
        "description": "Get historical values for a specific lab parameter to show trends over time. For patients, patient_id is optional.",
        "input_schema": {
            "type": "object",
            "properties": {
                "patient_id": {"type": "string", "description": "UUID of the patient (optional for patients)"},
                "parameter_name": {"type": "string", "description": "Lab parameter name e.g. Hemoglobin, Glucose"},
            },
            "required": ["parameter_name"],
        },
    },
    {
        "name": "get_incidents",
        "description": "Get recent injury incident records for the current patient or a specific patient the caller is allowed to access.",
        "input_schema": {
            "type": "object",
            "properties": {
                "patient_id": {"type": "string", "description": "UUID of the patient (optional for patients)"},
                "limit": {"type": "integer", "default": 5},
            },
        },
    },
    {
        "name": "get_incident_analysis",
        "description": "Get the stored AI analysis for a specific injury incident photo.",
        "input_schema": {
            "type": "object",
            "properties": {
                "incident_id": {"type": "string", "description": "UUID of the incident"},
            },
            "required": ["incident_id"],
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
    from app.modules.appointments.models import Appointment
    from app.modules.incidents.models import Incident
    from app.modules.reports.models import ExtractedReportData, MedicalReport
    from app.modules.users.models import PatientProfile

    if tool_name == "get_patient_profile":
        patient_id_raw = tool_input.get("patient_id")
        if not patient_id_raw and caller_role == "patient":
            patient_id = caller_id
        elif patient_id_raw:
            patient_id = uuid.UUID(patient_id_raw)
        else:
            return '{"error": "patient_id is required"}'

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
        patient_id_raw = tool_input.get("patient_id")
        if not patient_id_raw and caller_role == "patient":
            patient_id = caller_id
        elif patient_id_raw:
            patient_id = uuid.UUID(patient_id_raw)
        else:
            return '{"error": "patient_id is required"}'

        if caller_role == "patient" and patient_id != caller_id:
            return '{"error": "Access denied"}'

        limit = tool_input.get("limit", 5)
        report_type = tool_input.get("report_type")

        if caller_role == "patient":
            status_filter = ("extracted", "verified")
        else:
            status_filter = ("verified",)

        query = select(MedicalReport).where(
            MedicalReport.patient_id == patient_id,
            MedicalReport.ocr_status.in_(status_filter),
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
            raw_excerpt = None
            if not ext and r.ocr_raw_text:
                raw_excerpt = r.ocr_raw_text[:800]
            summaries.append({
                "report_id": str(r.id),
                "title": r.title,
                "type": r.report_type,
                "date": r.report_date,
                "file_name": r.file_name,
                "file_type": r.file_type,
                "ocr_status": r.ocr_status,
                "data": ext.data if ext else None,
                "raw_text_excerpt": raw_excerpt,
            })
        return json.dumps(summaries, default=str)

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
        patient_id_raw = tool_input.get("patient_id")
        if not patient_id_raw and caller_role == "patient":
            patient_id = caller_id
        elif patient_id_raw:
            patient_id = uuid.UUID(patient_id_raw)
        else:
            return '{"error": "patient_id is required"}'

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

    elif tool_name == "get_incidents":
        patient_id_raw = tool_input.get("patient_id")
        if not patient_id_raw and caller_role == "patient":
            patient_id = caller_id
        elif patient_id_raw:
            patient_id = uuid.UUID(patient_id_raw)
        else:
            return '{"error": "patient_id is required"}'

        if caller_role == "patient" and patient_id != caller_id:
            return '{"error": "Access denied"}'

        limit = tool_input.get("limit", 5)
        query = select(Incident).where(Incident.patient_id == patient_id).order_by(Incident.created_at.desc()).limit(limit)
        result = await db.execute(query)
        incidents = result.scalars().all()
        return json.dumps([
            {
                "incident_id": str(incident.id),
                "title": incident.title,
                "notes": incident.notes,
                "analysis_status": incident.analysis_status,
                "injury_type": incident.injury_type,
                "severity": incident.severity,
                "body_area": incident.body_area,
                "summary": incident.summary,
                "confidence": incident.confidence,
                "created_at": incident.created_at,
            }
            for incident in incidents
        ], default=str)

    elif tool_name == "get_incident_analysis":
        incident_id_raw = tool_input.get("incident_id")
        if not incident_id_raw:
            return '{"error": "incident_id is required"}'

        incident_result = await db.execute(select(Incident).where(Incident.id == uuid.UUID(incident_id_raw)))
        row = incident_result.scalar_one_or_none()
        if not row:
            return '{"error": "Incident not found"}'
        if caller_role == "patient" and row.patient_id != caller_id:
            return '{"error": "Access denied"}'

        return json.dumps(
            {
                "incident_id": str(row.id),
                "analysis_status": row.analysis_status,
                "injury_type": row.injury_type,
                "severity": row.severity,
                "body_area": row.body_area,
                "summary": row.summary,
                "confidence": row.confidence,
                "analysis_payload": row.analysis_payload,
                "created_at": row.created_at,
            },
            default=str,
        )

    return '{"error": "Unknown tool"}'
