use std::{fs::OpenOptions, io, sync::Once};

use colored::{Color, Colorize};
use tracing::{level_filters::LevelFilter, Event, Level, Subscriber};
use tracing_subscriber::{
    fmt::{
        format::Writer,
        layer,
        time::{ChronoLocal, FormatTime},
        writer::BoxMakeWriter,
        FmtContext, FormatEvent, FormatFields,
    },
    layer::SubscriberExt,
    registry::LookupSpan,
    Layer, Registry,
};

use super::config::Config;

static INIT: Once = Once::new();

#[allow(clippy::expect_used)]
pub fn setup_logging(config: &Config) {
    INIT.call_once(|| {
        let file = OpenOptions::new()
            .append(true)
            .create(true)
            .open(&config.log_file)
            .expect("Failed to open log file");

        let file_writer = BoxMakeWriter::new(file);
        let stderr_writer = BoxMakeWriter::new(io::stderr);

        let file_layer = layer()
            .json()
            .with_timer(custom_time_format())
            .with_writer(file_writer)
            .with_filter(LevelFilter::TRACE);

        let stderr_layer: Box<dyn Layer<_> + Send + Sync> = if config.json_format {
            Box::new(
                layer()
                    .json()
                    .with_timer(custom_time_format())
                    .with_writer(stderr_writer)
                    .with_filter(LevelFilter::from(config.log_level)),
            )
        } else {
            Box::new(
                layer()
                    .event_format(new_custom_formatter())
                    .with_writer(stderr_writer)
                    .with_filter(LevelFilter::from(config.log_level)),
            )
        };

        let subscriber = Registry::default().with(file_layer).with(stderr_layer);
        tracing::subscriber::set_global_default(subscriber)
            .expect("Failed to set global subscriber");
    });
}

fn custom_time_format() -> ChronoLocal {
    ChronoLocal::new("%Y-%m-%dT%H:%M:%S%.3f%:z".to_string())
}

struct CustomFormatter {
    pub timer: ChronoLocal,
}

impl CustomFormatter {
    fn get_color(&self, level: &Level) -> Color {
        match *level {
            Level::TRACE => Color::Cyan,
            Level::DEBUG => Color::BrightBlue,
            Level::WARN => Color::Yellow,
            Level::ERROR => Color::Red,
            Level::INFO => Color::BrightWhite,
        }
    }
}

impl<S, N> FormatEvent<S, N> for CustomFormatter
where
    S: Subscriber + for<'a> LookupSpan<'a>,
    N: for<'a> FormatFields<'a> + 'static,
{
    fn format_event(
        &self,
        ctx: &FmtContext<'_, S, N>,
        mut writer: Writer<'_>,
        event: &Event<'_>,
    ) -> std::fmt::Result {
        self.timer.format_time(&mut writer)?;
        let metadata = event.metadata();
        write!(
            writer,
            " - [{}] - RSFETCHER - ",
            format!("{:>8}", metadata.level().to_string()).color(self.get_color(metadata.level()))
        )?;
        ctx.field_format().format_fields(writer.by_ref(), event)?;
        writeln!(writer)
    }
}

fn new_custom_formatter() -> CustomFormatter {
    CustomFormatter {
        timer: custom_time_format(),
    }
}
