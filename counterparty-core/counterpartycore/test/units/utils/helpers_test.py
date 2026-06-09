import decimal
import os
from unittest.mock import Mock, patch

import pygit2
import pytest
from counterpartycore.lib.utils import helpers
from counterpartycore.test.mocks.counterpartydbs import ProtocolChangesDisabled


def test_chunkify():
    """Test chunkify function."""
    assert helpers.chunkify([1, 2, 3, 4, 5], 2) == [[1, 2], [3, 4], [5]]
    assert helpers.chunkify([1, 2, 3, 4], 2) == [[1, 2], [3, 4]]
    assert helpers.chunkify([1, 2, 3], 1) == [[1], [2], [3]]
    assert helpers.chunkify([], 5) == []
    # Test with n=0 (should use n=1)
    assert helpers.chunkify([1, 2, 3], 0) == [[1], [2], [3]]


def test_flat():
    """Test flat function."""
    assert helpers.flat([1, 2, 3]) == [1, 2, 3]
    assert helpers.flat((1, 2, 3)) == [1, 2, 3]
    assert helpers.flat(range(3)) == [0, 1, 2]


def test_accumulate():
    """Test accumulate function."""
    data = [("a", 1), ("a", 2), ("b", 3), ("b", 4), ("a", 5)]
    result = list(helpers.accumulate(data))
    assert result == [("a", 8), ("b", 7)]


def test_active_options():
    """Test active_options function."""
    assert helpers.active_options(0b1111, 0b0101) is True
    assert helpers.active_options(0b1010, 0b0101) is False
    assert helpers.active_options(0b0101, 0b0101) is True


def test_make_id():
    """Test make_id function."""
    assert helpers.make_id("hash1", "hash2") == "hash1_hash2"


def test_satoshirate_to_fiat():
    """Test satoshirate_to_fiat function."""
    assert helpers.satoshirate_to_fiat(10000) == 100.0
    assert helpers.satoshirate_to_fiat(12345) == 123.45
    assert helpers.satoshirate_to_fiat(0) == 0.0


def test_format_duration():
    """Test format_duration function."""
    assert helpers.format_duration(3661) == "1h 1m 1s"
    assert helpers.format_duration(0) == "0h 0m 0s"
    assert helpers.format_duration(7200) == "2h 0m 0s"


def test_is_url():
    """Test is_url function."""
    assert helpers.is_url("https://example.com") is True
    assert helpers.is_url("http://example.com/path") is True
    assert helpers.is_url("ftp://files.example.com") is True
    assert helpers.is_url("not-a-url") is False
    assert helpers.is_url("") is False
    assert helpers.is_url("example.com") is False


def test_divide():
    """Test divide function."""
    assert helpers.divide(10, 2) == 5
    assert helpers.divide(10, 0) == 0
    assert helpers.divide(0, 10) == 0
    assert helpers.divide(1, 3) == helpers.D("0.3333333333333333")


def test_bytes_to_string():
    """Test bytes_to_string function."""
    # Valid UTF-8
    assert helpers.bytes_to_string(b"hello") == "hello"
    # Invalid UTF-8 should return hex
    assert helpers.bytes_to_string(b"\xff\xfe") == "fffe"


def test_is_process_alive():
    """Test is_process_alive function."""
    # Current process should be alive
    assert helpers.is_process_alive(os.getpid()) is True
    # Non-existent PID (very high number)
    assert helpers.is_process_alive(999999999) is False


def test_api_json_encoder():
    """Test ApiJsonEncoder with various types."""
    encoder = helpers.ApiJsonEncoder()

    # Test decimal
    assert encoder.default(decimal.Decimal("1.23456789")) == "1.23456789"

    # Test bytes
    assert encoder.default(b"\x01\x02\x03") == "010203"

    # Test callable
    def my_func():
        pass

    assert encoder.default(my_func) == "my_func"

    # Test object with __class__ (custom object)
    class CustomObj:
        def __str__(self):
            return "custom_string"

    assert encoder.default(CustomObj()) == "custom_string"


def test_is_valid_tx_hash():
    assert not helpers.is_valid_tx_hash("foobar")
    assert helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1"
    )
    assert not helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda11"
    )
    assert not helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda"
    )
    assert not helpers.is_valid_tx_hash(
        "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42ddaG"
    )


def test_dhash():
    assert (
        helpers.dhash_string("foobar")
        == "3f2c7ccae98af81e44c0ec419659f50d8b7d48c681e5d57fc747d0461e42dda1"
    )


@pytest.fixture
def mock_repo():
    """Fixture to create a simulated git repository"""
    mock_repo = Mock()
    mock_head = Mock()
    mock_repo.head = mock_head
    mock_repo.head_is_detached = False
    return mock_repo


def test_get_commit_hash_normal_case(mock_repo):
    """Tests getting the commit hash in a normal case (on a branch)"""
    # Mock configuration
    mock_repo.head.target = "abcdef1234567890"
    mock_repo.head.shorthand = "main"

    with patch("pygit2.discover_repository", return_value="."):
        with patch("pygit2.Repository", return_value=mock_repo):
            # Function call
            result = helpers.get_current_commit_hash()

            # Result verification
            assert result == "main - abcdef1234567890"


def test_get_commit_hash_detached_head(mock_repo):
    """Tests getting the commit hash when HEAD is detached"""
    # Mock configuration
    mock_repo.head.target = "abcdef1234567890"
    mock_repo.head.shorthand = "some-branch"  # This name will be ignored
    mock_repo.head_is_detached = True

    with patch("pygit2.discover_repository", return_value="."):
        with patch("pygit2.Repository", return_value=mock_repo):
            # Function call
            result = helpers.get_current_commit_hash()

            # Result verification
            assert result == "abcdef1234567890"


def test_get_commit_hash_no_repo():
    """Tests getting the commit hash when not in a git repository"""
    # Simulate pygit2.discover_repository raising a GitError
    with patch("pygit2.discover_repository", side_effect=pygit2.GitError):
        # Function call
        result = helpers.get_current_commit_hash()

        # Result verification
        assert result is None


def test_get_commit_hash_git_error():
    """Tests getting the commit hash when a GitError occurs"""
    # Simulate pygit2.Repository raising a GitError
    with patch("pygit2.discover_repository", return_value="."):
        with patch("pygit2.Repository", side_effect=pygit2.GitError):
            # Function call
            result = helpers.get_current_commit_hash()

            # Result verification
            assert result is None


def test_get_commit_hash_from_env():
    os.environ["CURRENT_COMMIT"] = "abcdef1234567890"
    result = helpers.get_current_commit_hash()
    assert result == "abcdef1234567890"


def test_classify_mime_type():
    assert helpers.classify_mime_type("text/plain") == "text"
    assert helpers.classify_mime_type("message/rfc822") == "text"
    assert helpers.classify_mime_type("application/atom+xml") == "text"
    assert helpers.classify_mime_type("application/json") == "text"
    assert helpers.classify_mime_type("application/javascript") == "text"
    assert helpers.classify_mime_type("image/jpeg") == "binary"


def test_classify_mime_type_extended_support_enabled():
    # The protocol-gated branch tolerates parameters and recognises the
    # `+json` structured suffix (alongside `+xml`).
    assert helpers.classify_mime_type("audio/ogg;codecs=opus") == "binary"
    assert helpers.classify_mime_type("text/plain;charset=utf-8") == "text"
    assert helpers.classify_mime_type("application/ld+json") == "text"
    assert helpers.classify_mime_type("application/yaml") == "text"
    # Random binary types stay binary
    assert helpers.classify_mime_type("video/mp4") == "binary"
    assert helpers.classify_mime_type("image/webp") == "binary"


def test_classify_mime_type_extended_support_disabled():
    # Before the `extended_mime_types_support` gate activates we keep
    # the legacy classifier semantics:
    # - `+json` is NOT recognised as textual (only `+xml` is)
    # - `application/yaml` is NOT in the legacy textual allow-list
    # - parameters bypass the legacy `application/*` allow-list.
    with ProtocolChangesDisabled(["extended_mime_types_support"]):
        assert helpers.classify_mime_type("audio/ogg;codecs=opus") == "binary"
        assert helpers.classify_mime_type("application/ld+json") == "binary"
        assert helpers.classify_mime_type("application/yaml") == "binary"
        # `application/json;charset=utf-8` doesn't match the bare-string check,
        # so it falls through to "binary" pre-gate.
        assert helpers.classify_mime_type("application/json;charset=utf-8") == "binary"
        # Legacy types still classified correctly
        assert helpers.classify_mime_type("text/plain") == "text"
        assert helpers.classify_mime_type("application/json") == "text"
        assert helpers.classify_mime_type("application/atom+xml") == "text"


def test_classify_mime_type_non_string_inputs():
    # Halt-vector guard, gated with `extended_mime_types_support`:
    #
    # Post-gate: a CBOR-decoded `mime_type` may be any scalar (post-
    # taproot_support; see `fuzz_cbor_test.py::test_cbor_issuance_no_halt`).
    # The classifier must NOT raise -- it returns "binary" and downstream
    # validation flags the tx invalid.
    #
    # Pre-gate: behaviour is preserved exactly as it was before this
    # protocol change -- the legacy classifier raises on non-string, and
    # we keep that raise as-is. Any node still on legacy code raises too;
    # the broad-except in each parse-path's `unpack` catches it and falls
    # back to the legacy struct decoder. Changing pre-gate behaviour here
    # would diverge from those nodes (consensus break since taproot_support
    # activated).
    #
    # The exact exception type depends on the input: types that don't
    # have `.startswith` at all (int, float, bool, None, list, dict)
    # raise `AttributeError`; `bytes` has `.startswith` but rejects a
    # `str` argument with `TypeError`. Both are consensus-equivalent --
    # they are caught by the same broad-except downstream.
    for bogus in (1, 0, None, b"text/plain", 1.5, True, [], {}):
        assert helpers.classify_mime_type(bogus) == "binary"
    with ProtocolChangesDisabled(["extended_mime_types_support"]):
        # `int`, `float`, `bool` have no `.startswith` -> `AttributeError`.
        for bogus in (1, 1.5, True):
            with pytest.raises(AttributeError):
                helpers.classify_mime_type(bogus)
        # `bytes` has `.startswith` but `bytes.startswith("text/")` with a
        # `str` argument raises `TypeError`. This is the actual pre-gate
        # behaviour -- preserving it exactly is what keeps us in consensus
        # with legacy nodes on the network.
        with pytest.raises(TypeError):
            helpers.classify_mime_type(b"text/plain")
        # `0` and `None` are falsy so `mime_type or "text/plain"` upstream
        # would coerce them to "text/plain" -- but the classifier itself
        # is called with the raw value here, so they still hit `.startswith`
        # on a non-string.
        for falsy in (0, None):
            with pytest.raises(AttributeError):
                helpers.classify_mime_type(falsy)
        # `[]` and `{}` are also non-string and hit `.startswith` on a
        # non-string -- raises `AttributeError` too.
        for container in ([], {}):
            with pytest.raises(AttributeError):
                helpers.classify_mime_type(container)


def test_content_to_bytes():
    assert helpers.content_to_bytes("texte", "text/plain") == b"texte"
    assert helpers.content_to_bytes("48656c6c6f", "image/jpeg") == b"Hello"


def test_bytes_to_content():
    assert helpers.bytes_to_content(b"texte", "text/plain") == "texte"
    assert helpers.bytes_to_content(b"Hello", "image/jpeg") == "48656c6c6f"


@pytest.mark.parametrize(
    "mime_type,content,expected",
    [
        ("text/plain", "valid content", []),  # Valid MIME type
        (None, "valid content", []),  # None defaults to text/plain
        # MIME parameters are accepted once `extended_mime_types_support` is on.
        ("audio/ogg;codecs=opus", "deadbeef", []),
        # Invalid MIME with both errors
        (
            "fake/nonexistent-type",
            "valid content",
            [
                "Invalid mime type: fake/nonexistent-type",
                "Error converting description to bytes: Odd-length string",
            ],
        ),
        # Exception from content_to_bytes only
        ("text/plain", "valid content", ["Error converting description to bytes: Test error"]),
    ],
)
def test_check_content(mime_type, content, expected):
    if "Test error" in str(expected):
        with patch(
            "counterpartycore.lib.utils.helpers.content_to_bytes",
            side_effect=Exception("Test error"),
        ):
            assert helpers.check_content(mime_type, content) == expected
    else:
        assert helpers.check_content(mime_type, content) == expected


def test_check_content_extended_support_disabled():
    # When the gate is off, MIME parameters are not stripped and the
    # raw type fails the `mimetypes.types_map` membership check.
    with ProtocolChangesDisabled(["extended_mime_types_support"]):
        problems = helpers.check_content("audio/ogg;codecs=opus", "deadbeef")
        assert "Invalid mime type: audio/ogg;codecs=opus" in problems


def test_check_content_non_string_mime_type():
    # Same halt-vector guard as `test_classify_mime_type_non_string_inputs`:
    # CBOR-decoded `mime_type` may be any scalar. `check_content` must
    # return a `problems` list (not raise) so the tx is marked invalid,
    # both pre-gate and post-gate. Pre-gate, `classify_mime_type` raises
    # `AttributeError` (for int/float/bool/None/list/dict) or `TypeError`
    # (for bytes) -- but either is called inside `check_content`'s own
    # try/except, so the function returns problems instead of propagating.
    for bogus in (1, b"text/plain", 1.5, True):
        problems = helpers.check_content(bogus, "deadbeef")
        assert any(p.startswith("Invalid mime type") for p in problems), problems
    with ProtocolChangesDisabled(["extended_mime_types_support"]):
        for bogus in (1, b"text/plain", 1.5, True):
            problems = helpers.check_content(bogus, "deadbeef")
            assert any(p.startswith("Invalid mime type") for p in problems), problems
            # Pre-gate, the inner `content_to_bytes` call raises
            # `AttributeError` and is caught into a second problem.
            assert any(p.startswith("Error converting") for p in problems), problems


def test_check_content_extended_support_common_types():
    # Post-gate, the deterministic hard-coded allow-list
    # (`EXTENDED_MIME_TYPES_VALID`) MUST recognise the common
    # ordinal-inscription / web MIME types as valid -- otherwise
    # legitimate inscriptions get marked "Invalid mime type" and
    # consensus diverges from any node that previously accepted them
    # via `mimetypes.init()`.
    common_types = [
        # Image (ord-style inscriptions are mostly images)
        "image/png",
        "image/jpeg",
        "image/gif",
        "image/svg+xml",
        "image/webp",
        "image/apng",
        "image/avif",
        # Audio
        "audio/mpeg",
        "audio/ogg",
        "audio/wav",
        "audio/flac",
        # Video
        "video/mp4",
        "video/webm",
        # Text
        "text/plain",
        "text/html",
        "text/css",
        "text/javascript",
        "text/markdown",
        # Application
        "application/json",
        "application/pdf",
        "application/wasm",
        "application/yaml",
        # Font
        "font/woff",
        "font/woff2",
        "font/otf",
        "font/ttf",
        # Model (3D ord inscriptions)
        "model/stl",
        "model/gltf-binary",
    ]
    for mime in common_types:
        problems = helpers.check_content(mime, "deadbeef")
        assert all(not p.startswith("Invalid mime type") for p in problems), (
            f"{mime} should be a recognised MIME type post-gate, got: {problems}"
        )
    # Sanity-check: parameters are stripped, so `<type>;codecs=...`
    # variants are accepted too.
    for mime in (
        "image/png;charset=utf-8",
        "audio/ogg;codecs=opus",
        "video/webm;codecs=vp9",
        "application/json;charset=utf-8",
    ):
        problems = helpers.check_content(mime, "deadbeef")
        assert all(not p.startswith("Invalid mime type") for p in problems), (
            f"{mime} should be valid after stripping parameters, got: {problems}"
        )


def test_check_content_extended_support_rejects_unknown():
    # Cross-platform consensus: a type that ISN'T in our hard-coded
    # allow-list MUST be rejected, regardless of what
    # /etc/mime.types says on the validating node. This is the
    # whole reason we stopped calling `mimetypes.init()`.
    bogus_types = [
        "application/x-vnd-mozilla.xml-encoded",
        "image/x-totally-made-up",
        "foo/bar",
    ]
    for mime in bogus_types:
        problems = helpers.check_content(mime, "deadbeef")
        assert any(p.startswith("Invalid mime type") for p in problems), (
            f"{mime} should be rejected post-gate, got: {problems}"
        )


def test_extended_mime_types_valid_is_superset_of_textual_application():
    # `EXTENDED_MIME_TYPES_VALID` must contain every textual
    # `application/*` type, otherwise `classify_mime_type` would
    # accept (as "text") a type that `check_content` then flags as
    # "Invalid mime type" -- a self-inconsistent validation result.
    assert helpers.TEXTUAL_APPLICATION_MIME_TYPES.issubset(helpers.EXTENDED_MIME_TYPES_VALID)
