mod b58;
mod indexer;
mod utils;

use b58::register_b58_module;

use indexer::register_indexer_module;
use pyo3::prelude::*;
use pyo3::types::PyString;
use utils::register_utils_module;

#[pymodule]
fn counterparty_rs(m: &Bound<'_, PyModule>) -> PyResult<()> {
    register_b58_module(m)?;
    register_utils_module(m)?;
    register_indexer_module(m)?;

    m.add(
        "__version__",
        PyString::new_bound(m.py(), env!("VERGEN_GIT_DESCRIBE")),
    )?;
    m.add(
        "__sha__",
        PyString::new_bound(m.py(), env!("VERGEN_GIT_SHA")),
    )?;
    m.add(
        "__target__",
        PyString::new_bound(m.py(), env!("VERGEN_CARGO_TARGET_TRIPLE")),
    )?;
    m.add(
        "__build_date__",
        PyString::new_bound(m.py(), env!("VERGEN_BUILD_DATE")),
    )?;
    Ok(())
}
