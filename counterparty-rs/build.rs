// build.rs
use std::error::Error;
use vergen::EmitBuilder;


fn main() -> Result<(), Box<dyn Error>> {

    pyo3_build_config::add_extension_module_link_args();

    // Emit the instructions
    EmitBuilder::builder()
        .all_build()
        .all_git()
        .all_cargo()
        .emit()?;
    Ok(())
}

