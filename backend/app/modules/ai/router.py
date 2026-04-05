from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
import json
import uuid

from app.database.session import get_db
from app.dependencies import get_current_user
from app.modules.ai.models import ChatSession, ChatMessage
from app.modules.ai.schemas import (
    CreateSessionRequest, SessionResponse, MessageResponse,
    SendMessageRequest, SessionWithMessagesResponse,
)
from app.modules.ai.chatbot import stream_chat_response

router = APIRouter()


@router.post("/sessions", response_model=SessionResponse, status_code=201)
async def create_session(
    data: CreateSessionRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    session = ChatSession(
        user_id=current_user.id,
        title=data.title or "New Conversation",
        context_patient_id=data.context_patient_id,
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


@router.get("/sessions", response_model=List[SessionResponse])
async def list_sessions(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(
        select(ChatSession)
        .where(ChatSession.user_id == current_user.id)
        .order_by(ChatSession.updated_at.desc())
    )
    return result.scalars().all()


@router.get("/sessions/{session_id}", response_model=SessionWithMessagesResponse)
async def get_session(
    session_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(
        select(ChatSession).where(ChatSession.id == session_id, ChatSession.user_id == current_user.id)
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    msg_result = await db.execute(
        select(ChatMessage).where(ChatMessage.session_id == session_id).order_by(ChatMessage.created_at)
    )
    messages = msg_result.scalars().all()

    return SessionWithMessagesResponse(
        id=session.id,
        user_id=session.user_id,
        title=session.title,
        context_patient_id=session.context_patient_id,
        created_at=session.created_at,
        messages=[MessageResponse.model_validate(m) for m in messages],
    )


@router.post("/sessions/{session_id}/messages")
async def send_message(
    session_id: uuid.UUID,
    data: SendMessageRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(
        select(ChatSession).where(ChatSession.id == session_id, ChatSession.user_id == current_user.id)
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    msg_result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.session_id == session_id)
        .order_by(ChatMessage.created_at.desc())
        .limit(20)
    )
    history_msgs = list(reversed(msg_result.scalars().all()))
    message_history = [
        {"role": m.role, "content": m.content}
        for m in history_msgs
        if m.role in ("user", "assistant")
    ]

    user_msg = ChatMessage(session_id=session_id, role="user", content=data.content)
    db.add(user_msg)
    await db.commit()

    user_name = "Doctor" if current_user.role == "doctor" else "Patient"
    try:
        if current_user.role == "doctor":
            from app.modules.users.models import DoctorProfile
            p = await db.execute(select(DoctorProfile).where(DoctorProfile.user_id == current_user.id))
            profile = p.scalar_one_or_none()
            if profile:
                user_name = profile.full_name
        else:
            from app.modules.users.models import PatientProfile
            p = await db.execute(select(PatientProfile).where(PatientProfile.user_id == current_user.id))
            profile = p.scalar_one_or_none()
            if profile:
                user_name = profile.full_name
    except Exception:
        pass

    async def generate():
        full_response = ""
        async for chunk in stream_chat_response(
            session_id=session_id,
            user_message=data.content,
            message_history=message_history,
            user_id=current_user.id,
            user_role=current_user.role,
            user_name=user_name,
            db=db,
        ):
            try:
                parsed = json.loads(chunk.replace("data: ", "").strip())
                if parsed.get("type") == "text":
                    full_response += parsed.get("content", "")
            except Exception:
                pass
            yield chunk

        if full_response:
            assistant_msg = ChatMessage(session_id=session_id, role="assistant", content=full_response)
            db.add(assistant_msg)
            await db.commit()

    return StreamingResponse(generate(), media_type="text/event-stream")


@router.delete("/sessions/{session_id}")
async def delete_session(
    session_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(
        select(ChatSession).where(ChatSession.id == session_id, ChatSession.user_id == current_user.id)
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    await db.delete(session)
    await db.commit()
    return {"message": "Session deleted"}
