from fastapi import HTTPException, status, Depends
from app.dependencies import get_current_user


def require_roles(*roles: str):
    async def dependency(current_user=Depends(get_current_user)):
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {', '.join(roles)}",
            )
        return current_user
    return dependency


require_doctor = require_roles("doctor")
require_patient = require_roles("patient")
require_any = require_roles("doctor", "patient")
