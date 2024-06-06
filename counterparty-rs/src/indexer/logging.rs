use std::{fs::OpenOptions, io, sync::Once};

use tracing::error;
use tracing_subscriber::{
    fmt::{self, writer::BoxMakeWriter},
    EnvFilter,
};

use super::config::{Config, LogFormat, LogOutput};

static INIT: Once = Once::new();

pub fn setup_logging(config: &Config) {
    INIT.call_once(|| {
        let env_filter =
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));

        let writer = match &config.log_output {
            LogOutput::Stdout => BoxMakeWriter::new(io::stdout),
            LogOutput::Stderr => BoxMakeWriter::new(io::stderr),
            LogOutput::File(path) => {
                match OpenOptions::new().append(true).create(true).open(path) {
                    Ok(file) => BoxMakeWriter::new(file),
                    Err(_) => {
                        error!("Failed to open log file: {}", path);
                        BoxMakeWriter::new(io::sink)
                    }
                }
            }
            LogOutput::None => BoxMakeWriter::new(io::sink),
        };

        let builder = fmt::Subscriber::builder().with_env_filter(env_filter);

        match config.log_format {
            LogFormat::Structured => {
                builder.json().with_writer(writer).init();
            }
            LogFormat::Unstructured => {
                builder.with_writer(writer).init();
            }
        }
    })
}
