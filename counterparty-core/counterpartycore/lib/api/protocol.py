"""HTTP adapters for the parser's cached compatibility decision."""

from flask import g, request

from counterpartycore.lib.utils import protocolstatus

EXPOSE_HEADERS = "X-COUNTERPARTY-PROTOCOL-STATUS, X-COUNTERPARTY-REQUIRED-VERSION"


def is_diagnostic(rule):
    return rule in ("/v2/", "/v2/routes", "/v2/openapi.json")


def install(app, error_response, set_cors_headers):
    @app.after_request
    def finish_response(response):
        # Normal v2 responses choose their final snapshot before serialization.
        # Legacy/proxy/auth responses reach this hook directly and sample here.
        status = getattr(g, "protocol_response_status", None) or protocolstatus.summary()
        blocked = protocolstatus.error(status)
        rule = request.url_rule.rule if request.url_rule else request.path
        if blocked:
            if response.status_code == 200 and not is_diagnostic(rule):
                response = error_response(status)
            response.headers["Cache-Control"] = "no-store"
            response.headers["X-COUNTERPARTY-READY"] = "False"
        response.headers["X-COUNTERPARTY-PROTOCOL-STATUS"] = status["status"]
        if status["required_version"]:
            response.headers["X-COUNTERPARTY-REQUIRED-VERSION"] = status["required_version"]
        set_cors_headers(response)
        if "Access-Control-Allow-Origin" in response.headers:
            exposed = response.headers.get("Access-Control-Expose-Headers")
            response.headers["Access-Control-Expose-Headers"] = ", ".join(
                value for value in (exposed, EXPOSE_HEADERS) if value
            )
        return response
