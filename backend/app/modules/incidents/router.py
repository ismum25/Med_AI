import uuid
from typing import List

from app.core.permissions import require_patient
from app.database.session import get_db
from app.dependencies import get_current_user
from app.modules.incidents import schemas, service
from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(dependencies=[Depends(require_patient)])


@router.post("/upload", response_model=schemas.IncidentResponse, status_code=201, include_in_schema=False)
@router.post("", response_model=schemas.IncidentResponse, status_code=201, include_in_schema=False)
@router.post("/", response_model=schemas.IncidentResponse, status_code=201)
async def upload_incident(
    file: UploadFile = File(...),
    notes: str | None = Form(None),
    title: str | None = Form(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    incident = await service.create_incident(
        patient_id=current_user.id,
        uploader_id=current_user.id,
        file=file,
        notes=notes,
        title=title,
        db=db,
    )
    return service.incident_to_response(incident)


@router.get("/", response_model=List[schemas.IncidentResponse])
async def list_my_incidents(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    incidents = await service.list_patient_incidents(current_user.id, current_user.id, current_user.role, db)
    return [service.incident_to_response(i).model_dump() for i in incidents]


@router.get("/{incident_id}", response_model=schemas.IncidentResponse)
async def get_incident(
    incident_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    incident = await service.get_incident_by_id(incident_id, current_user.id, current_user.role, db)
    return service.incident_to_response(incident)


@router.get("/{incident_id}/download")
async def download_incident_image(
    incident_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    incident, file_bytes = await service.get_incident_download_url(incident_id, current_user.id, current_user.role, db)
    media_type = "image/jpeg"
    if incident.file_type:
        media_type = f"image/{incident.file_type}"
    return StreamingResponse(iter([file_bytes]), media_type=media_type)
