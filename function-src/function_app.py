"""
Internal Message API - Azure Function (Python v2 programming model).

Accepts a POST request with a JSON body containing a "message" field and
returns that message alongside a server-generated timestamp and request ID.
Sits behind APIM, which is the only thing allowed to reach it on the private
network, and which enforces mTLS before any request gets here.
"""

import json
import logging
import uuid
from datetime import datetime, timezone

import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)


@app.route(route="messages", methods=["POST"])
def process_message(req: func.HttpRequest) -> func.HttpResponse:
    request_id = req.headers.get("x-request-id", str(uuid.uuid4()))
    logging.info("Processing request %s", request_id)

    try:
        body = req.get_json()
    except ValueError:
        logging.warning("Request %s: body is not valid JSON", request_id)
        return _error_response("Request body must be valid JSON.", request_id, 400)

    if not isinstance(body, dict):
        logging.warning("Request %s: body is not a JSON object", request_id)
        return _error_response("Request body must be a JSON object.", request_id, 400)

    message = body.get("message")

    if not message or not isinstance(message, str):
        logging.warning("Request %s: missing or invalid 'message' field", request_id)
        return _error_response(
            "Field 'message' is required and must be a non-empty string.",
            request_id,
            400,
        )

    response_payload = {
        "message": message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "requestId": request_id,
    }

    logging.info("Request %s processed successfully", request_id)

    return func.HttpResponse(
        json.dumps(response_payload),
        status_code=200,
        mimetype="application/json",
    )


def _error_response(detail: str, request_id: str, status_code: int) -> func.HttpResponse:
    payload = {"error": detail, "requestId": request_id}
    return func.HttpResponse(
        json.dumps(payload),
        status_code=status_code,
        mimetype="application/json",
    )
