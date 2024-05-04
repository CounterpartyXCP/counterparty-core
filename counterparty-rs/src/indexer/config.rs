use pyo3::{exceptions::PyValueError, types::PyDict, FromPyObject, PyAny, PyErr, PyResult};

#[derive(Debug, Clone)]
pub enum LogFormat {
    Structured,
    Unstructured,
}

impl<'source> FromPyObject<'source> for LogFormat {
    fn extract(obj: &'source PyAny) -> PyResult<Self> {
        let log_format_str: &str = obj.extract()?;
        match log_format_str {
            "structured" => Ok(LogFormat::Structured),
            "unstructured" => Ok(LogFormat::Unstructured),
            _ => Err(PyErr::new::<PyValueError, _>(
                "'log_format' must be either 'structured' or 'unstructured'",
            )),
        }
    }
}

#[derive(Debug, Clone)]
pub enum LogOutput {
    Stdout,
    Stderr,
    File(String),
    None,
}

impl<'source> FromPyObject<'source> for LogOutput {
    fn extract(obj: &'source PyAny) -> PyResult<Self> {
        if let Ok(output_str) = obj.extract::<&str>() {
            return match output_str {
                "stdout" => Ok(LogOutput::Stdout),
                "stderr" => Ok(LogOutput::Stderr),
                "none" => Ok(LogOutput::None),
                _ => Ok(LogOutput::File(output_str.into())),
            };
        }

        Err(PyErr::new::<PyValueError, _>(
            "'log_output' must be a string for 'stdout', 'stderr', 'none', or a file path",
        ))
    }
}

#[derive(Debug, Clone)]
pub struct Config {
    pub rpc_address: String,
    pub rpc_user: String,
    pub rpc_password: String,
    pub log_format: LogFormat,
    pub log_output: LogOutput,
    pub db_dir: String,
    pub consume_blocks: bool,
}

impl<'source> FromPyObject<'source> for Config {
    fn extract(obj: &'source PyAny) -> PyResult<Self> {
        let dict = obj.downcast::<PyDict>()?;
        let rpc_address: String = dict
            .get_item("rpc_address")?
            .ok_or(PyErr::new::<PyValueError, _>("'rpc_address' is required"))?
            .extract()?;
        let rpc_user: String = dict
            .get_item("rpc_user")?
            .ok_or(PyErr::new::<PyValueError, _>("'rpc_user' is required"))?
            .extract()?;
        let rpc_password: String = dict
            .get_item("rpc_password")?
            .ok_or(PyErr::new::<PyValueError, _>("'rpc_password' is required"))?
            .extract()?;
        let db_dir: String = dict
            .get_item("db_dir")?
            .ok_or(PyErr::new::<PyValueError, _>("'db_dir' is required"))?
            .extract()?;

        let log_format = match dict.get_item("log_format")? {
            Some(item) => item.extract()?,
            None => LogFormat::Unstructured,
        };

        let log_output = match dict.get_item("log_output")? {
            Some(item) => item.extract()?,
            None => LogOutput::Stdout,
        };

        let consume_blocks = match dict.get_item("consume_blocks")? {
            Some(item) => item.extract()?,
            None => false,
        };

        Ok(Config {
            rpc_address,
            rpc_user,
            rpc_password,
            log_format,
            log_output,
            db_dir,
            consume_blocks,
        })
    }
}
