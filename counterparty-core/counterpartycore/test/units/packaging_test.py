#
# file: counterpartycore/test/units/packaging_test.py
#
# The OpenAPI document is generated at the repository root and shipped inside
# the package. `hatch_build.py` resolves it from whichever layout the build
# runs in; a plain `force-include` of `../openapi.json` could not, and made
# `pip wheel` on a fresh sdist fail with `Forced include not found`.
#
import importlib.util
import os

import pytest

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
PROJECT_ROOT = os.path.join(REPO_ROOT, "counterparty-core")


def load_hatch_build():
    # Imported by path: the build hook lives beside `pyproject.toml`, outside
    # the importable package.
    pytest.importorskip("hatchling", reason="build backend not installed in this environment")
    path = os.path.join(PROJECT_ROOT, "hatch_build.py")
    spec = importlib.util.spec_from_file_location("counterparty_hatch_build", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_pyproject_does_not_force_include_a_parent_path():
    with open(os.path.join(PROJECT_ROOT, "pyproject.toml"), "r", encoding="utf-8") as f:
        pyproject = f.read()
    # A wheel force-include reaching outside the project root is unresolvable
    # from an extracted sdist, where no parent checkout exists.
    assert '"../openapi.json"' not in pyproject
    assert "[tool.hatch.build.hooks.custom]" in pyproject


def test_openapi_resolves_from_the_repository_layout():
    hatch_build = load_hatch_build()
    assert hatch_build.resolve_openapi_source(PROJECT_ROOT) == os.path.join(
        REPO_ROOT, "openapi.json"
    )


def test_openapi_resolves_from_an_extracted_sdist(tmp_path):
    hatch_build = load_hatch_build()
    root = tmp_path / "counterparty_core-0.0.0"
    (root / "counterpartycore").mkdir(parents=True)
    packaged = root / "counterpartycore" / "openapi.json"
    packaged.write_text("{}", encoding="utf-8")

    # No neighbouring repository file: the archive-local copy is the only input.
    assert hatch_build.resolve_openapi_source(str(root)) == str(packaged)


def test_openapi_absent_is_not_fatal(tmp_path):
    hatch_build = load_hatch_build()
    root = tmp_path / "project"
    root.mkdir()
    assert hatch_build.resolve_openapi_source(str(root)) is None
