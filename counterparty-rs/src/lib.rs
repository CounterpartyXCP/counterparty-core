mod b58;
mod utils;

use b58::create_b58_module;
use utils::create_utils_module;

use pyo3::prelude::*;
use pyo3::types::PyString;


/// A Python module implemented in Rust.
#[pymodule]
fn counterparty_rs(py: Python, m: &PyModule) -> PyResult<()> {
    m.add_submodule(create_b58_module(py)?)?;
    m.add_submodule(create_utils_module(py)?)?;

    m.add(
        "__version__",
        PyString::new(py, env!("VERGEN_GIT_DESCRIBE")),
    )?;
    m.add("__sha__", PyString::new(py, env!("VERGEN_GIT_SHA")))?;
    m.add(
        "__target__",
        PyString::new(py, env!("VERGEN_CARGO_TARGET_TRIPLE")),
    )?;
    m.add(
        "__build_date__",
        PyString::new(py, env!("VERGEN_BUILD_DATE")),
    )?;
    Ok(())
}
