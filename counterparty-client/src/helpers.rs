use anyhow::Result;
use serde_json::Value;
use std::io::Write;
use syntect::easy::HighlightLines;
use syntect::highlighting::ThemeSet;
use syntect::parsing::SyntaxSet;
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
    let theme = theme_set
        .themes
        .get("InspiredGitHub")
        .unwrap_or_else(|| theme_set.themes.get("Solarized (dark)").unwrap());

    let mut highlighter = HighlightLines::new(syntax, theme);

    // Prepare colored output stream
    let mut stdout = StandardStream::stdout(ColorChoice::Always);

    // Highlight and print each line
    for line in yaml_str.lines() {
        let highlights = highlighter.highlight_line(line, &syntax_set)?;

        for &(style, text) in &highlights {
            // Convert syntect style to termcolor
            let mut color_spec = ColorSpec::new();
            color_spec.set_fg(Some(Color::Rgb(
                style.foreground.r,
                style.foreground.g,
                style.foreground.b,
            )));

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

/// Converts and prints a list of JSON values as a single JSON array
///
/// # Arguments
///
/// * `json_values` - A reference to a Vec<serde_json::Value> to print
///
/// # Examples
///
/// ```
/// let json_vec = vec![
///     serde_json::json!({"name": "John", "age": 30}),
///     serde_json::json!({"name": "Jane", "age": 25})
/// ];
/// print_colored_json_list(&json_vec).unwrap();
/// ```
pub fn print_colored_json_list(json_values: &Vec<Value>) -> Result<()> {
    // Créer un nouveau Value::Array contenant tous les éléments
    let array_value = Value::Array(json_values.clone());
    
    // Appeler print_colored_json une seule fois avec cette valeur
    print_colored_json(&array_value)
}

/// Prints a colored message with optional additional text in default color
///
/// # Arguments
///
/// * `text` - The text to print in color
/// * `color` - The color to use for the text
/// * `more_text` - Optional text to print in default color after the colored text
///
/// # Returns
///
/// * `Result<()>` - Ok if successful, Err otherwise
fn print_colored(text: &str, color: Color, more_text: Option<&str>) {
    let mut stdout = StandardStream::stdout(ColorChoice::Always);
    
    // Configure and print the colored text
    let mut color_spec = ColorSpec::new();
    color_spec.set_fg(Some(color));
    let _ = stdout.set_color(&color_spec);
    let _ = write!(stdout, "{}", text);
    
    // Reset color and print additional text if provided
    let _ = stdout.reset();
    if let Some(additional) = more_text {
        let _ = write!(stdout, " {}", additional);
    }
    
    // Add a newline at the end
    let _ = writeln!(stdout);
}

/// Prints a success message in green, with optional additional text in default color

pub fn print_success(text: &str, more_text: Option<&str>) {
    print_colored(text, Color::Green, more_text)
}

/// Prints an error message in red, with optional additional text in default color`
pub fn print_error(text: &str, more_text: Option<&str>) {
    print_colored(text, Color::Red, more_text)
}

/// Prints a warning message in yellow, with optional additional text in default color
pub fn print_warning(text: &str, more_text: Option<&str>) {
    print_colored(text, Color::Yellow, more_text)
}