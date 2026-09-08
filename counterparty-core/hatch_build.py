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

# Hatchling is a build-time dependency declared in `[build-system]`; it is not
# present in the lint environment, which installs the package rather than
# building it.
from hatchling.builders.hooks.plugin.interface import (  # pylint: disable=import-error
    BuildHookInterface,
)

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

    # `version` is part of the build-hook interface ("standard" / "editable");
    # the document is packaged the same way either way.
    def initialize(self, version, build_data):  # pylint: disable=unused-argument
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
