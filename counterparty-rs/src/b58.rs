use pyo3::prelude::*;
use pyo3::types::PyBytes;

#[pyfunction]
fn b58_encode(decoded: &[u8]) -> String {
    bs58::encode(decoded).with_check().into_string()
}

#[pyfunction]
fn b58_encode_list(decoded_list: Vec<&[u8]>) -> Vec<String> {
    decoded_list.iter().map(|x| b58_encode(x)).collect()
}

#[pyfunction]
fn b58_decode<'p>(py: Python<'p>, encoded: &str) -> &'p PyBytes {
    let s = bs58::decode(encoded)
        .with_check(None)
        .into_vec()
        .expect("bad");
    PyBytes::new(py, &s)
}

#[pyfunction]
fn b58_decode_list<'p>(py: Python<'p>, encoded_list: Vec<&str>) -> Vec<&'p PyBytes> {
    encoded_list.iter().map(|x| b58_decode(py, x)).collect()
}

/// A Python module implemented in Rust.
pub fn create_b58_module(py: Python) -> PyResult<&'_ PyModule> {
    let m = PyModule::new(py, "b58")?;
    m.add_function(wrap_pyfunction!(b58_encode, m)?)?;
    m.add_function(wrap_pyfunction!(b58_encode_list, m)?)?;
    m.add_function(wrap_pyfunction!(b58_decode, m)?)?;
    m.add_function(wrap_pyfunction!(b58_decode_list, m)?)?;
    Ok(m)
}
