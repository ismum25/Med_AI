from fastapi import APIRouter, Depends, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.dependencies import get_current_user
from app.modules.auth import schemas, service

router = APIRouter()


@router.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
async def register(data: schemas.RegisterRequest, db: AsyncSession = Depends(get_db)):
    return await service.register_user(data, db)


@router.post("/login", response_model=schemas.TokenResponse)
async def login(data: schemas.LoginRequest, db: AsyncSession = Depends(get_db)):
    return await service.login_user(data, db)


@router.post("/token", response_model=schemas.TokenResponse)
async def token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    login_data = schemas.LoginRequest(
        email=form_data.username,
        password=form_data.password,
    )
    return await service.login_user(login_data, db)


@router.post("/refresh", response_model=schemas.AccessTokenResponse)
async def refresh(data: schemas.RefreshRequest, db: AsyncSession = Depends(get_db)):
    return await service.refresh_access_token(data.refresh_token, db)


@router.post("/logout", response_model=schemas.MessageResponse)
async def logout(data: schemas.RefreshRequest, db: AsyncSession = Depends(get_db)):
    await service.logout_user(data.refresh_token, db)
    return {"message": "Logged out successfully"}


@router.get("/me", response_model=schemas.UserResponse)
async def get_me(current_user=Depends(get_current_user)):
    return current_user
