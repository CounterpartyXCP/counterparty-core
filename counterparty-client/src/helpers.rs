use anyhow::Result;
use serde_json::Value;
use syntect::easy::HighlightLines;
use syntect::highlighting::ThemeSet;
use syntect::parsing::SyntaxSet;
use std::io::Write;
use termcolor::{Color, ColorChoice, ColorSpec, StandardStream, WriteColor};

/// Converts and prints a JSON value as colored YAML
///
/// # Arguments
///
/// * `json_value` - A reference to a serde_json::Value to print
///
/// # Examples
///
/// ```
/// let json = serde_json::json!({"name": "John", "age": 30});
/// print_colored_json(&json).unwrap();
/// ```
pub fn print_colored_json(json_value: &Value) -> Result<()> {
    // Load default syntax and theme sets
    let syntax_set = SyntaxSet::load_defaults_newlines();
    let theme_set = ThemeSet::load_defaults();

    // Convert JSON to YAML
    let yaml_str = serde_yaml::to_string(json_value)?;

    // Choose YAML syntax (or fallback to plain text)
    let syntax = syntax_set
        .find_syntax_by_extension("yaml")
        .unwrap_or_else(|| syntax_set.find_syntax_plain_text());

    // Use the first available theme or fallback to a default
    let theme = theme_set.themes.get("InspiredGitHub").unwrap_or_else(|| {
        theme_set.themes.get("Solarized (dark)").unwrap()
    });

    let mut highlighter = HighlightLines::new(syntax, theme);

    // Prepare colored output stream
    let mut stdout = StandardStream::stdout(ColorChoice::Always);

    // Highlight and print each line
    for line in yaml_str.lines() {
        let highlights = highlighter.highlight_line(line, &syntax_set)?;
        
        for &(style, text) in &highlights {
            // Convert syntect style to termcolor
            let mut color_spec = ColorSpec::new();
            color_spec.set_fg(Some(Color::Rgb(style.foreground.r, style.foreground.g, style.foreground.b)));
            
            // Apply color and write
            stdout.set_color(&color_spec)?;
            write!(stdout, "{}", text)?;
        }
        
        // Reset color and add newline
        stdout.reset()?;
        writeln!(stdout)?;
    }

    Ok(())
}