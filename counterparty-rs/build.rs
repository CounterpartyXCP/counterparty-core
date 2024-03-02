// build.rs
use std::error::Error;
use vergen::EmitBuilder;

fn main() -> Result<(), Box<dyn Error>> {
    // Emit the instructions
    EmitBuilder::builder()
        .all_build()
        .all_git()
        .all_cargo()
        .emit()?;
    Ok(())
}

