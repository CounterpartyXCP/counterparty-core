use std::{fs::OpenOptions, io, sync::Once};

use colored::{Color, Colorize};
use tracing::{level_filters::LevelFilter, span, Event, Level, Subscriber};
use tracing_subscriber::{
    fmt::{
        format::Writer,
        layer,
        time::{ChronoLocal, FormatTime},
        writer::BoxMakeWriter,
        FmtContext, FormatEvent, FormatFields,
    },
    layer::{Context, SubscriberExt},
    registry::LookupSpan,
    Layer, Registry,
};

use super::config::Config;

static INIT: Once = Once::new();

struct ConnectionPoolFilter<L> {
    inner: L,
}

impl<L> ConnectionPoolFilter<L> {
    fn new(inner: L) -> Self {
        Self { inner }
    }

    fn is_connection_pool_message(event: &Event) -> bool {
        let target = event.metadata().target();
        if target.starts_with("hyper_util") {
            return true;
        }

        let mut message = String::new();
        let mut visitor = MessageVisitor(&mut message);
        event.record(&mut visitor);

        message.contains("take?")
            || message.contains("connection")
            || message.contains("hyper_util")
    }
}

struct MessageVisitor<'a>(&'a mut String);

impl<'a> tracing::field::Visit for MessageVisitor<'a> {
    fn record_debug(&mut self, _field: &tracing::field::Field, value: &dyn std::fmt::Debug) {
        use std::fmt::Write;
        let _ = write!(self.0, "{:?}", value);
    }
}

impl<S, L> Layer<S> for ConnectionPoolFilter<L>
where
    S: Subscriber + for<'a> LookupSpan<'a>,
    L: Layer<S>,
{
    fn on_event(&self, event: &Event<'_>, ctx: Context<'_, S>) {
        if !Self::is_connection_pool_message(event) {
            self.inner.on_event(event, ctx);
        }
    }

    fn on_new_span(&self, attrs: &span::Attributes<'_>, id: &span::Id, ctx: Context<'_, S>) {
        self.inner.on_new_span(attrs, id, ctx)
    }

    fn on_record(&self, span: &span::Id, values: &span::Record<'_>, ctx: Context<'_, S>) {
        self.inner.on_record(span, values, ctx)
    }

    fn on_follows_from(&self, span: &span::Id, follows: &span::Id, ctx: Context<'_, S>) {
        self.inner.on_follows_from(span, follows, ctx)
    }

    fn on_close(&self, span: span::Id, ctx: Context<'_, S>) {
        self.inner.on_close(span, ctx)
    }

    fn on_enter(&self, span: &span::Id, ctx: Context<'_, S>) {
        self.inner.on_enter(span, ctx)
    }

    fn on_exit(&self, span: &span::Id, ctx: Context<'_, S>) {
        self.inner.on_exit(span, ctx)
    }
}

#[allow(clippy::expect_used)]
pub fn setup_logging(config: &Config) {
    INIT.call_once(|| {
        let file = OpenOptions::new()
            .append(true)
            .create(true)
            .open(&config.log_file)
            .expect("Failed to open log file");

        // Changer l'ordre: d'abord ConnectionPoolFilter, puis le filtre de niveau
        let file_layer = layer()
            .json()
            .with_timer(custom_time_format())
            .with_writer(BoxMakeWriter::new(file))
            .boxed();

        let file_layer =
            ConnectionPoolFilter::new(file_layer).with_filter(LevelFilter::from(config.log_level));

        let stderr_layer = if config.json_format {
            let layer = layer()
                .json()
                .with_timer(custom_time_format())
                .with_writer(BoxMakeWriter::new(io::stderr))
                .boxed();

            ConnectionPoolFilter::new(layer).with_filter(LevelFilter::from(config.log_level))
        } else {
            let layer = layer()
                .event_format(new_custom_formatter())
                .with_writer(BoxMakeWriter::new(io::stderr))
                .boxed();

            ConnectionPoolFilter::new(layer).with_filter(LevelFilter::from(config.log_level))
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
            " - [{}] - RSFetcher - ",
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
