#
# file: counterparty-core/hatch_build.py
#
# Carries the OpenAPI document into both distributions.
#
# ``openapi.json`` is generated at the repository root (see
# ``test/integrations/regtest/genapidoc.py``), one directory above this
# project, and the server reads it from ``counterpartycore/openapi.json``
# once installed. A plain ``force-include`` of ``../openapi.json`` works for
# a repository-to-wheel build but breaks the source-distribution channel: the
# sdist has no parent checkout, so building its wheel dies with
# ``FileNotFoundError: Forced include not found: .../openapi.json``.
#
# This hook resolves the document from whichever layout it is building in --
# the archive-local copy first, the repository parent second -- and includes
# it in the sdist as well, so the sdist carries the input its own wheel build
# needs.
#
import os

from hatchling.builders.hooks.plugin.interface import BuildHookInterface

PACKAGED_PATH = os.path.join("counterpartycore", "openapi.json")


def resolve_openapi_source(root):
    """Return the OpenAPI document to package, or None if there is none.

    ``root`` is the directory holding ``pyproject.toml``: the repository's
    ``counterparty-core/`` in a source checkout, the extracted archive root
    when building a wheel from an sdist.
    """
    candidates = (
        # sdist layout: the hook below already copied it in.
        os.path.join(root, PACKAGED_PATH),
        # repository layout: the single source of truth at the repo root.
        os.path.join(os.path.dirname(os.path.abspath(root)), "openapi.json"),
    )
    for candidate in candidates:
        if os.path.isfile(candidate):
            return candidate
    return None


class OpenAPIBuildHook(BuildHookInterface):
    PLUGIN_NAME = "openapi"

    def initialize(self, version, build_data):
        source = resolve_openapi_source(self.root)
        if source is None:
            # A checkout that has never generated the document should still be
            # installable; `/v2/openapi.json` then falls back to the source
            # tree exactly as it did before the document was packaged.
            self.app.display_warning(
                "openapi.json not found; building without the packaged API document"
            )
            return
        build_data["force_include"][source] = PACKAGED_PATH
