use anyhow::Result;
use indicatif::{ProgressBar, ProgressStyle};
use serde_json::Value;
use std::io::{IsTerminal, Write};
use std::sync::atomic::{AtomicBool, Ordering};
use syntect::easy::HighlightLines;
use syntect::highlighting::ThemeSet;
use syntect::parsing::SyntaxSet;
use termcolor::{Color, ColorChoice, ColorSpec, StandardStream, WriteColor};

/// When true, structured output is emitted as plain JSON (no colour, no YAML)
/// and human status lines go to stderr, so stdout is machine-parseable.
static JSON_OUTPUT: AtomicBool = AtomicBool::new(false);

/// Enable or disable raw-JSON output mode. Set once at start-up from the global
/// `--json` flag.
pub fn set_json_output(enabled: bool) {
    JSON_OUTPUT.store(enabled, Ordering::Relaxed);
}

/// Whether raw-JSON output mode is active.
pub fn json_output() -> bool {
    JSON_OUTPUT.load(Ordering::Relaxed)
}

/// Colour choice for stdout: never colour in JSON mode or when stdout is not a
/// terminal (piped/redirected), so captured output is free of ANSI escapes.
fn stdout_color_choice() -> ColorChoice {
    if json_output() || !std::io::stdout().is_terminal() {
        ColorChoice::Never
    } else {
        ColorChoice::Auto
    }
}

/// A wrapper around ProgressBar that provides a stop() method
pub struct Spinner {
    progress_bar: ProgressBar,
}

impl Spinner {
    /// Creates a new Spinner
    fn new(message: &str) -> Self {
        let progress_bar = ProgressBar::new_spinner();
        let style = ProgressStyle::default_spinner();
        progress_bar.set_style(style);
        progress_bar.set_message(message.to_string());
        progress_bar.enable_steady_tick(std::time::Duration::from_millis(100));

        Spinner { progress_bar }
    }

    /// Stops the spinner
    pub fn stop(self) {
        self.progress_bar.finish_and_clear();
    }
}

/// Prints a loading message with a spinner and returns the spinner
///
/// # Arguments
///
/// * `message` - The message to display with the spinner
///
/// # Returns
///
/// * `Spinner` - A handle to the spinner that can be used to stop it with `.stop()`
///
/// # Examples
///
/// ```no_run
/// use counterparty_client::helpers::print_loading;
/// let spinner = print_loading("Loading data...");
/// // Do some work
/// spinner.stop();
/// ```
pub fn print_loading(message: &str) -> Spinner {
    Spinner::new(message)
}

/// Converts and prints a JSON value as colored YAML
///
/// # Arguments
///
/// * `json_value` - A reference to a serde_json::Value to print
///
/// # Examples
///
/// ```no_run
/// use counterparty_client::helpers::print_colored_json;
/// let json = serde_json::json!({"name": "John", "age": 30});
/// print_colored_json(&json).unwrap();
/// ```
pub fn print_colored_json(json_value: &Value) -> Result<()> {
    // Machine-readable mode: emit plain, pretty JSON that pipes cleanly.
    if json_output() {
        println!("{}", serde_json::to_string_pretty(json_value)?);
        return Ok(());
    }

    // Load default syntax and theme sets
    let syntax_set = SyntaxSet::load_defaults_newlines();
    let theme_set = ThemeSet::load_defaults();

    // Convert JSON to YAML
    let yaml_str = serde_yaml_ng::to_string(json_value)?;

    // Choose YAML syntax (or fallback to plain text)
    let syntax = syntax_set
        .find_syntax_by_extension("yaml")
        .unwrap_or_else(|| syntax_set.find_syntax_plain_text());

    // Use the first available theme, falling back to whatever else is bundled.
    let theme = theme_set
        .themes
        .get("InspiredGitHub")
        .or_else(|| theme_set.themes.get("Solarized (dark)"))
        .or_else(|| theme_set.themes.values().next());

    let Some(theme) = theme else {
        // No bundled theme at all (unreachable with syntect's default theme
        // set today, but a future syntect bump could change that) — degrade to
        // uncoloured output rather than panicking.
        let mut stdout = StandardStream::stdout(stdout_color_choice());
        for line in yaml_str.lines() {
            let _ = writeln!(stdout, "{}", line);
        }
        return Ok(());
    };

    let mut highlighter = HighlightLines::new(syntax, theme);

    // Prepare colored output stream (no colour when piped/redirected).
    let mut stdout = StandardStream::stdout(stdout_color_choice());

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
/// ```no_run
/// use counterparty_client::helpers::print_colored_json_list;
/// let json_vec = vec![
///     serde_json::json!({"name": "John", "age": 30}),
///     serde_json::json!({"name": "Jane", "age": 25})
/// ];
/// print_colored_json_list(&json_vec).unwrap();
/// ```
pub fn print_colored_json_list(json_values: &[Value]) -> Result<()> {
    // Create a single Value::Array containing all the elements
    let array_value = Value::Array(json_values.to_vec());

    // Call print_colored_json once with that value
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
    // In JSON mode, human status lines must not pollute the parseable stdout, so
    // route them to stderr instead.
    let mut stream = if json_output() {
        StandardStream::stderr(ColorChoice::Never)
    } else {
        StandardStream::stdout(stdout_color_choice())
    };

    // Configure and print the colored text
    let mut color_spec = ColorSpec::new();
    color_spec.set_fg(Some(color));
    let _ = stream.set_color(&color_spec);
    let _ = write!(stream, "{}", text);

    // Reset color and print additional text if provided
    let _ = stream.reset();
    if let Some(additional) = more_text {
        let _ = write!(stream, " {}", additional);
    }

    // Add a newline at the end
    let _ = writeln!(stream);
}

/// Prints a success message in green, with optional additional text in default color
pub fn print_success(text: &str, more_text: Option<&str>) {
    print_colored(text, Color::Green, more_text)
}

/// Prints an error message in red, with optional additional text in default color
pub fn print_error(text: &str, more_text: Option<&str>) {
    print_colored(text, Color::Red, more_text)
}

/// Prints a warning message in yellow, with optional additional text in default color
pub fn print_warning(text: &str, more_text: Option<&str>) {
    print_colored(text, Color::Yellow, more_text)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn colored_json_renders_nested_object() {
        print_colored_json(&json!({
            "name": "John",
            "age": 30,
            "nested": {"a": [1, 2, 3], "b": true}
        }))
        .unwrap();
    }

    #[test]
    fn colored_json_list_renders_as_array() {
        let items = vec![json!({"a": 1}), json!({"b": 2})];
        print_colored_json_list(&items).unwrap();
    }

    #[test]
    fn colored_json_handles_scalars_and_null() {
        print_colored_json(&json!("hello")).unwrap();
        print_colored_json(&json!(42)).unwrap();
        print_colored_json(&json!(null)).unwrap();
        // An empty list still round-trips through the YAML highlighter.
        print_colored_json_list(&[]).unwrap();
    }

    #[test]
    fn colored_status_helpers_do_not_panic() {
        print_success("Success:", Some("all good"));
        print_success("Success:", None);
        print_error("Error:", Some("something broke"));
        print_error("Error:", None);
        print_warning("Warning:", Some("careful"));
        print_warning("Warning:", None);
    }

    #[test]
    fn spinner_starts_and_stops() {
        let spinner = print_loading("working...");
        spinner.stop();
    }
}
