import json
import asyncio
from typing import AsyncGenerator, List
import uuid
import anthropic

from app.config import settings
from app.modules.ai.tools import TOOLS, execute_tool

SYSTEM_PROMPT_DOCTOR = """You are an AI medical assistant helping Dr. {user_name}.
You have access to tools to look up patient data, medical reports, and appointments.
Be professional, accurate, and concise. Present data clearly for clinical decision-making.
Do not make diagnoses — present data and let the doctor decide. Note when data is from unverified OCR."""

SYSTEM_PROMPT_PATIENT = """You are a friendly AI health assistant.
You can help the patient understand their medical reports, check appointments, and answer general health questions.
You have access only to the patient's own data. Always recommend consulting a doctor for medical decisions."""


async def stream_chat_response(
    session_id: uuid.UUID,
    user_message: str,
    message_history: List[dict],
    user_id: uuid.UUID,
    user_role: str,
    user_name: str,
    db,
) -> AsyncGenerator[str, None]:
    system = (
        SYSTEM_PROMPT_DOCTOR.format(user_name=user_name)
        if user_role == "doctor"
        else SYSTEM_PROMPT_PATIENT
    )

    messages = message_history + [{"role": "user", "content": user_message}]
    client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
    full_response = ""
    tool_calls_made = []

    while True:
        with client.messages.stream(
            model=settings.LLM_MODEL,
            max_tokens=1500,
            system=system,
            messages=messages,
            tools=TOOLS,
        ) as stream:
            response = stream.get_final_message()

        if response.stop_reason == "tool_use":
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    tool_calls_made.append({"name": block.name, "input": block.input})
                    yield f"data: {json.dumps({'type': 'tool_use', 'tool': block.name})}\n\n"

                    result = await execute_tool(
                        tool_name=block.name,
                        tool_input=block.input,
                        caller_id=user_id,
                        caller_role=user_role,
                        db=db,
                    )
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": result,
                    })

            messages.append({"role": "assistant", "content": response.content})
            messages.append({"role": "user", "content": tool_results})
        else:
            for block in response.content:
                if hasattr(block, "text"):
                    full_response = block.text
                    words = full_response.split()
                    for i, word in enumerate(words):
                        chunk = word + (" " if i < len(words) - 1 else "")
                        yield f"data: {json.dumps({'type': 'text', 'content': chunk})}\n\n"
                        await asyncio.sleep(0.01)
            break

    yield f"data: {json.dumps({'type': 'done', 'tool_calls': tool_calls_made})}\n\n"
    yield "data: [DONE]\n\n"
