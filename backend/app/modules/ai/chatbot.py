import json
import asyncio
from typing import AsyncGenerator, List
import uuid
import anthropic
import httpx

from app.config import settings
from app.modules.ai.tools import TOOLS, execute_tool

SYSTEM_PROMPT_DOCTOR = """You are an AI medical assistant helping Dr. {user_name}.
You have access to tools to look up patient data, medical reports, and appointments.
Be professional, accurate, and concise. Present data clearly for clinical decision-making.
Do not make diagnoses — present data and let the doctor decide. Note when data is from unverified OCR."""

SYSTEM_PROMPT_PATIENT = """You are a friendly AI health assistant.
You can help the patient understand their medical reports, check appointments, and answer general health questions.
You have access only to the patient's own data. Always recommend consulting a doctor for medical decisions.
When calling tools that accept patient_id, omit patient_id (the system will use the current patient)."""


async def _create_message(
    *,
    client: anthropic.Anthropic,
    model: str,
    system: str,
    messages: List[dict],
    tools: list,
    max_tokens: int = 1500,
):
    return client.messages.create(
        model=model,
        max_tokens=max_tokens,
        system=system,
        messages=messages,
        tools=tools,
    )


def _openrouter_tools() -> list:
    return [
        {
            "type": "function",
            "function": {
                "name": tool["name"],
                "description": tool["description"],
                "parameters": tool["input_schema"],
            },
        }
        for tool in TOOLS
    ]


async def _openrouter_create(system: str, messages: List[dict]) -> dict:
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

    payload = {
        "model": settings.OPENROUTER_MODEL,
        "messages": [{"role": "system", "content": system}] + messages,
        "tools": _openrouter_tools(),
        "tool_choice": "auto",
        "max_tokens": 1500,
    }

    timeout = httpx.Timeout(60.0, connect=15.0)
    async with httpx.AsyncClient(timeout=timeout) as http_client:
        response = await http_client.post(url, headers=headers, json=payload)
    response.raise_for_status()
    return response.json()


async def _openrouter_chat_loop(
    *,
    system: str,
    messages: List[dict],
    user_id: uuid.UUID,
    user_role: str,
    db,
) -> tuple[str, list]:
    tool_calls_made = []

    while True:
        response = await _openrouter_create(system, messages)
        choice = (response.get("choices") or [{}])[0]
        message = choice.get("message") or {}
        tool_calls = message.get("tool_calls") or []

        if tool_calls:
            messages.append({
                "role": "assistant",
                "content": message.get("content", ""),
                "tool_calls": tool_calls,
            })

            for call in tool_calls:
                call_id = call.get("id")
                fn = call.get("function") or {}
                name = fn.get("name")
                args_raw = fn.get("arguments", "{}")
                try:
                    args = json.loads(args_raw) if isinstance(args_raw, str) else args_raw
                except json.JSONDecodeError:
                    args = {}

                tool_calls_made.append({"name": name, "input": args})
                result = await execute_tool(
                    tool_name=name,
                    tool_input=args,
                    caller_id=user_id,
                    caller_role=user_role,
                    db=db,
                )
                messages.append({
                    "role": "tool",
                    "tool_call_id": call_id,
                    "content": result,
                })
            continue

        return message.get("content", ""), tool_calls_made


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

    if user_role == "patient":
        messages = (
            [{"role": "system", "content": "For patient tools, you can omit patient_id."}]
            + message_history
            + [{"role": "user", "content": user_message}]
        )
    else:
        messages = message_history + [{"role": "user", "content": user_message}]
    use_openrouter = bool(settings.OPENROUTER_API_KEY)
    if use_openrouter:
        client = None
        model = settings.OPENROUTER_MODEL
    else:
        client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
        model = settings.LLM_MODEL
    full_response = ""
    tool_calls_made = []

    if use_openrouter:
        or_messages = [{"role": "system", "content": system}] + messages
        full_response, tool_calls_made = await _openrouter_chat_loop(
            system=system,
            messages=or_messages,
            user_id=user_id,
            user_role=user_role,
            db=db,
        )
        words = full_response.split()
        for i, word in enumerate(words):
            chunk = word + (" " if i < len(words) - 1 else "")
            yield f"data: {json.dumps({'type': 'text', 'content': chunk})}\n\n"
            await asyncio.sleep(0.01)

        yield f"data: {json.dumps({'type': 'done', 'tool_calls': tool_calls_made})}\n\n"
        yield "data: [DONE]\n\n"
        return

    while True:
        response = await _create_message(
            client=client,
            model=model,
            system=system,
            messages=messages,
            tools=TOOLS,
            max_tokens=1500,
        )

        stop_reason = response.stop_reason if hasattr(response, "stop_reason") else (
            response.get("stop_reason") if isinstance(response, dict) else None
        )
        content = response.content if hasattr(response, "content") else (
            response.get("content", []) if isinstance(response, dict) else response
        )

        if stop_reason == "tool_use":
            tool_results = []
            for block in content:
                block_type = block.type if hasattr(block, "type") else (
                    block.get("type") if isinstance(block, dict) else None
                )
                if block_type == "tool_use":
                    block_name = block.name if hasattr(block, "name") else block.get("name")
                    block_input = block.input if hasattr(block, "input") else block.get("input")
                    block_id = block.id if hasattr(block, "id") else block.get("id")

                    tool_calls_made.append({"name": block_name, "input": block_input})
                    yield f"data: {json.dumps({'type': 'tool_use', 'tool': block_name})}\n\n"

                    result = await execute_tool(
                        tool_name=block_name,
                        tool_input=block_input,
                        caller_id=user_id,
                        caller_role=user_role,
                        db=db,
                    )
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block_id,
                        "content": result,
                    })

            messages.append({"role": "assistant", "content": content})
            messages.append({"role": "user", "content": tool_results})
        else:
            if isinstance(content, str):
                full_response = content
                words = full_response.split()
                for i, word in enumerate(words):
                    chunk = word + (" " if i < len(words) - 1 else "")
                    yield f"data: {json.dumps({'type': 'text', 'content': chunk})}\n\n"
                    await asyncio.sleep(0.01)
            else:
                for block in content:
                    block_text = block.text if hasattr(block, "text") else (
                        block.get("text") if isinstance(block, dict) else None
                    )
                    if block_text:
                        full_response = block_text
                        words = full_response.split()
                        for i, word in enumerate(words):
                            chunk = word + (" " if i < len(words) - 1 else "")
                            yield f"data: {json.dumps({'type': 'text', 'content': chunk})}\n\n"
                            await asyncio.sleep(0.01)
            break

    yield f"data: {json.dumps({'type': 'done', 'tool_calls': tool_calls_made})}\n\n"
    yield "data: [DONE]\n\n"


async def get_chat_response(
    session_id: uuid.UUID,
    user_message: str,
    message_history: List[dict],
    user_id: uuid.UUID,
    user_role: str,
    user_name: str,
    db,
) -> dict:
    system = (
        SYSTEM_PROMPT_DOCTOR.format(user_name=user_name)
        if user_role == "doctor"
        else SYSTEM_PROMPT_PATIENT
    )

    if user_role == "patient":
        messages = (
            [{"role": "system", "content": "For patient tools, you can omit patient_id."}]
            + message_history
            + [{"role": "user", "content": user_message}]
        )
    else:
        messages = message_history + [{"role": "user", "content": user_message}]
    use_openrouter = bool(settings.OPENROUTER_API_KEY)
    if use_openrouter:
        client = None
        model = settings.OPENROUTER_MODEL
    else:
        client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
        model = settings.LLM_MODEL

    tool_calls_made = []
    full_response = ""

    if use_openrouter:
        or_messages = [{"role": "system", "content": system}] + messages
        full_response, tool_calls_made = await _openrouter_chat_loop(
            system=system,
            messages=or_messages,
            user_id=user_id,
            user_role=user_role,
            db=db,
        )
        return {"response": full_response, "tool_calls": tool_calls_made}

    while True:
        response = await _create_message(
            client=client,
            model=model,
            system=system,
            messages=messages,
            tools=TOOLS,
            max_tokens=1500,
        )

        stop_reason = response.stop_reason if hasattr(response, "stop_reason") else (
            response.get("stop_reason") if isinstance(response, dict) else None
        )
        content = response.content if hasattr(response, "content") else (
            response.get("content", []) if isinstance(response, dict) else response
        )

        if stop_reason == "tool_use":
            tool_results = []
            for block in content:
                block_type = block.type if hasattr(block, "type") else (
                    block.get("type") if isinstance(block, dict) else None
                )
                if block_type == "tool_use":
                    block_name = block.name if hasattr(block, "name") else block.get("name")
                    block_input = block.input if hasattr(block, "input") else block.get("input")
                    block_id = block.id if hasattr(block, "id") else block.get("id")

                    tool_calls_made.append({"name": block_name, "input": block_input})
                    result = await execute_tool(
                        tool_name=block_name,
                        tool_input=block_input,
                        caller_id=user_id,
                        caller_role=user_role,
                        db=db,
                    )
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block_id,
                        "content": result,
                    })

            messages.append({"role": "assistant", "content": content})
            messages.append({"role": "user", "content": tool_results})
        else:
            if isinstance(content, str):
                full_response = content
            else:
                for block in content:
                    block_text = block.text if hasattr(block, "text") else (
                        block.get("text") if isinstance(block, dict) else None
                    )
                    if block_text:
                        full_response = block_text
            break

    return {"response": full_response, "tool_calls": tool_calls_made}
