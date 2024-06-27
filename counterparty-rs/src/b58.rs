use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;

#[pyfunction]
pub fn b58_encode(decoded: &[u8]) -> String {
    bs58::encode(decoded).with_check().into_string()
}

#[pyfunction]
fn b58_encode_list(decoded_list: Vec<Vec<u8>>) -> Vec<String> {
    decoded_list.iter().map(|x| b58_encode(x)).collect()
}

#[pyfunction]
fn b58_decode(encoded: &str) -> PyResult<Vec<u8>> {
    let decoded = bs58::decode(encoded).with_check(None).into_vec();

    match decoded {
        Ok(s) => Ok(s),
        Err(_) => Err(PyValueError::new_err("Bad input")),
    }
}

#[pyfunction]
fn b58_decode_list(encoded_list: Vec<String>) -> PyResult<Vec<Vec<u8>>> {
    let mut decoded_list = Vec::new();
    for encoded in encoded_list {
        let decoded = b58_decode(&encoded)?;
        decoded_list.push(decoded);
    }
    Ok(decoded_list)
}

pub fn register_b58_module(parent_module: &Bound<'_, PyModule>) -> PyResult<()> {
    let m = PyModule::new_bound(parent_module.py(), "b58")?;
    m.add_function(wrap_pyfunction!(b58_encode, &m)?)?;
    m.add_function(wrap_pyfunction!(b58_encode_list, &m)?)?;
    m.add_function(wrap_pyfunction!(b58_decode, &m)?)?;
    m.add_function(wrap_pyfunction!(b58_decode_list, &m)?)?;
    parent_module.add_submodule(&m)?;
    Ok(())
}
