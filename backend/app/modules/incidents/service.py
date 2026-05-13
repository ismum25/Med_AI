import base64
import json
import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import httpx
from app.config import settings
from app.modules.incidents import storage
from app.modules.incidents.models import Incident
from app.modules.incidents.schemas import IncidentResponse
from fastapi import HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/jpg", "image/webp"}
MAX_FILE_SIZE_MB = 20
INCIDENT_VISION_MODEL = "openai/gpt-4o-mini"


def _extract_text(content: Any) -> str:
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts: List[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
                continue
            if isinstance(item, dict):
                text = item.get("text")
                if isinstance(text, str):
                    parts.append(text)
                    continue
            text = getattr(item, "text", None)
            if isinstance(text, str):
                parts.append(text)
        return "\n".join(part.strip() for part in parts if part).strip()
    text = getattr(content, "text", None)
    return text.strip() if isinstance(text, str) else ""


def _parse_json_payload(text: str) -> Dict[str, Any]:
    candidate = text.strip()
    if candidate.startswith("```"):
        candidate = candidate.replace("```json", "").replace("```", "").strip()
    payload = json.loads(candidate)
    return payload if isinstance(payload, dict) else {}


async def _analyze_with_openrouter(file_bytes: bytes, mime_type: str, notes: Optional[str]) -> Dict[str, Any]:
    if not settings.OPENROUTER_API_KEY:
        raise HTTPException(status_code=503, detail="OpenRouter is not configured")

    base_url = settings.OPENROUTER_BASE_URL.rstrip("/")
    url = f"{base_url}/chat/completions"
    headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
    }
    if settings.OPENROUTER_SITE_URL:
        headers["HTTP-Referer"] = settings.OPENROUTER_SITE_URL
    if settings.OPENROUTER_APP_NAME:
        headers["X-Title"] = settings.OPENROUTER_APP_NAME

    prompt = (
        "Analyze the injury photo and return strict JSON with these keys: "
        "injury_type, severity, body_area, description, summary, confidence, urgency, recommended_action, red_flags. "
        "Use clear clinical language. The description must be a short but specific observation of what is visible in the photo. "
        "Severity should be one of: low, moderate, high, critical, unknown. "
        "If the image is unclear, say so in description and set injury_type to unknown."
    )
    if notes:
        prompt += f" User notes: {notes.strip()}"

    image_data_uri = f"data:{mime_type};base64,{base64.b64encode(file_bytes).decode('ascii')}"
    payload = {
        "model": INCIDENT_VISION_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": image_data_uri}},
                ],
            }
        ],
        "temperature": 0,
        "max_tokens": 1200,
    }

    timeout = httpx.Timeout(60.0, connect=15.0)
    async with httpx.AsyncClient(timeout=timeout) as client:
        response = await client.post(url, headers=headers, json=payload)
        if response.status_code >= 400:
            logger.error("OpenRouter incident analysis failed: %s", response.text)
        response.raise_for_status()
        body = response.json()

    choices = body.get("choices") if isinstance(body, dict) else None
    if not isinstance(choices, list) or not choices:
        raise HTTPException(status_code=502, detail="OpenRouter returned no analysis")

    first = choices[0]
    if not isinstance(first, dict):
        raise HTTPException(status_code=502, detail="OpenRouter returned an invalid response")

    message = first.get("message") or {}
    response_text = _extract_text(message.get("content"))
    if not response_text:
        raise HTTPException(status_code=502, detail="OpenRouter returned an empty analysis")

    return _parse_json_payload(response_text)


def _incident_to_response(incident: Incident) -> IncidentResponse:
    return IncidentResponse.model_validate({
        "id": incident.id,
        "patient_id": incident.patient_id,
        "uploaded_by": incident.uploaded_by,
        "title": incident.title,
        "notes": incident.notes,
        "file_name": incident.file_name,
        "file_type": incident.file_type,
        "analysis_status": incident.analysis_status,
        "injury_type": incident.injury_type,
        "severity": incident.severity,
        "body_area": incident.body_area,
        "description": incident.description,
        "summary": incident.summary,
        "confidence": incident.confidence,
        "analysis_payload": incident.analysis_payload,
        "created_at": incident.created_at,
        "updated_at": incident.updated_at,
    })


async def create_incident(
    *,
    patient_id: uuid.UUID,
    uploader_id: uuid.UUID,
    file: UploadFile,
    notes: Optional[str],
    title: Optional[str],
    db: AsyncSession,
) -> Incident:
    if file.content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(status_code=400, detail=f"File type {file.content_type} not allowed")

    file_bytes = await file.read()
    if len(file_bytes) > MAX_FILE_SIZE_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"File too large. Max {MAX_FILE_SIZE_MB}MB")

    object_key = await storage.upload_file(
        file_bytes=file_bytes,
        file_name=file.filename or "incident-image.jpg",
        content_type=file.content_type,
        folder="incidents",
    )

    incident = Incident(
        patient_id=patient_id,
        uploaded_by=uploader_id,
        title=(title or file.filename or "Incident photo").strip() or "Incident photo",
        notes=notes,
        file_url=object_key,
        file_name=file.filename,
        file_type=file.content_type.split("/")[-1],
        analysis_status="processing",
    )
    db.add(incident)
    await db.commit()
    await db.refresh(incident)

    try:
        result = await _analyze_with_openrouter(file_bytes=file_bytes, mime_type=file.content_type, notes=notes)
        # save raw payload first (so we don't lose it if casting fails)
        incident.analysis_payload = result

        # Safely extract fields
        incident.injury_type = str(result.get("injury_type") or "unknown")
        incident.severity = str(result.get("severity") or "unknown")
        incident.body_area = str(result.get("body_area") or "unknown")
        incident.description = (str(result.get("description") or "") or None)
        incident.summary = (str(result.get("summary") or "") or None)

        # confidence may be a string or number; coerce safely
        confidence = result.get("confidence")
        try:
            incident.confidence = float(confidence) if confidence is not None else None
        except Exception:
            incident.confidence = None

        # If title was the default (filename or not provided), set a dynamic title
        if (not title) or (title and title.strip() == (file.filename or "").strip()):
            gen_injury = incident.injury_type or "Injury"
            gen_area = incident.body_area or "Unknown"
            incident.title = f"{gen_injury.title()} - {gen_area.title()}"

        incident.analysis_status = "analyzed"
    except Exception as exc:
        # preserve any payload if present, augment with error
        prev = incident.analysis_payload or {}
        prev.update({"error": str(exc), "analyzed_at": datetime.now(timezone.utc).isoformat()})
        incident.analysis_payload = prev
        incident.analysis_status = "failed"

    await db.commit()
    await db.refresh(incident)
    return incident


async def list_patient_incidents(
    patient_id: uuid.UUID,
    requester_id: uuid.UUID,
    requester_role: str,
    db: AsyncSession,
) -> List[Incident]:
    if requester_role == "patient" and patient_id != requester_id:
        raise HTTPException(status_code=403, detail="Access denied")
    result = await db.execute(
        select(Incident).where(Incident.patient_id == patient_id).order_by(Incident.created_at.desc())
    )
    return result.scalars().all()


async def get_incident_by_id(
    incident_id: uuid.UUID,
    requester_id: uuid.UUID,
    requester_role: str,
    db: AsyncSession,
) -> Incident:
    result = await db.execute(select(Incident).where(Incident.id == incident_id))
    incident = result.scalar_one_or_none()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    if requester_role == "patient" and incident.patient_id != requester_id:
        raise HTTPException(status_code=403, detail="Access denied")
    return incident


async def get_incident_download_url(
    incident_id: uuid.UUID,
    requester_id: uuid.UUID,
    requester_role: str,
    db: AsyncSession,
) -> tuple[Incident, bytes]:
    incident = await get_incident_by_id(incident_id, requester_id, requester_role, db)
    file_bytes = await storage.download_file(incident.file_url)
    return incident, file_bytes


async def delete_incident(
    incident_id: uuid.UUID,
    requester_id: uuid.UUID,
    requester_role: str,
    db: AsyncSession,
) -> None:
    incident = await get_incident_by_id(incident_id, requester_id, requester_role, db)
    # attempt to delete the stored file (best-effort)
    try:
        storage.delete_file(incident.file_url)
    except Exception:
        logger.exception("Failed to delete incident file from storage")
    # remove DB row
    await db.delete(incident)
    await db.commit()


def incident_to_response(incident: Incident) -> IncidentResponse:
    return _incident_to_response(incident)
