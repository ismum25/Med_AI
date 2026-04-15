import hashlib
from datetime import datetime, timedelta, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status

from app.modules.auth.models import User, RefreshToken
from app.modules.auth.schemas import RegisterRequest, LoginRequest
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token
from app.config import settings


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


async def register_user(data: RegisterRequest, db: AsyncSession) -> User:
    result = await db.execute(select(User).where(User.email == data.email))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    if data.role == "doctor" and not data.license_number:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="License number required for doctors")

    user = User(
        email=data.email,
        password_hash=hash_password(data.password),
        role=data.role,
        is_active=True,
        is_verified=True,
    )
    db.add(user)
    await db.flush()

    if data.role == "doctor":
        from app.modules.users.models import DoctorProfile
        profile = DoctorProfile(
            user_id=user.id,
            full_name=data.full_name,
            specialization=data.specialization or "",
            license_number=data.license_number,
            hospital=data.hospital,
        )
        db.add(profile)
    else:
        from app.modules.users.models import PatientProfile
        profile = PatientProfile(
            user_id=user.id,
            full_name=data.full_name,
            date_of_birth=data.date_of_birth,
            blood_type=data.blood_type,
        )
        db.add(profile)

    await db.commit()
    await db.refresh(user)
    return user


async def login_user(data: LoginRequest, db: AsyncSession) -> dict:
    result = await db.execute(select(User).where(User.email == data.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is deactivated")

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    refresh_token = create_refresh_token()

    token_record = RefreshToken(
        user_id=user.id,
        token_hash=_hash_token(refresh_token),
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    db.add(token_record)
    await db.commit()

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user_id": str(user.id),
        "role": user.role,
    }


async def refresh_access_token(refresh_token: str, db: AsyncSession) -> dict:
    token_hash = _hash_token(refresh_token)
    result = await db.execute(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.revoked.is_(False),
            RefreshToken.expires_at > datetime.now(timezone.utc),
        )
    )
    token_record = result.scalar_one_or_none()

    if not token_record:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token")

    user_result = await db.execute(select(User).where(User.id == token_record.user_id))
    user = user_result.scalar_one_or_none()

    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    token_record.revoked = True

    new_access = create_access_token({"sub": str(user.id), "role": user.role})
    new_refresh = create_refresh_token()

    new_record = RefreshToken(
        user_id=user.id,
        token_hash=_hash_token(new_refresh),
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    db.add(new_record)
    await db.commit()

    return {"access_token": new_access, "refresh_token": new_refresh, "token_type": "bearer"}


async def logout_user(refresh_token: str, db: AsyncSession) -> None:
    token_hash = _hash_token(refresh_token)
    result = await db.execute(select(RefreshToken).where(RefreshToken.token_hash == token_hash))
    token_record = result.scalar_one_or_none()
    if token_record:
        token_record.revoked = True
        await db.commit()
