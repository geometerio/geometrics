import opentelemetry, { Context, context, propagation, ROOT_CONTEXT, Span } from '@opentelemetry/api';
import { Resource } from '@opentelemetry/resources';
import { ResourceAttributes } from '@opentelemetry/semantic-conventions';
import { ZoneContextManager } from '@opentelemetry/context-zone';
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { ConsoleSpanExporter, BatchSpanProcessor, SimpleSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { HttpTraceContextPropagator, TRACE_PARENT_HEADER } from '@opentelemetry/core';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { getWebAutoInstrumentations } from '@opentelemetry/auto-instrumentations-web';

/*
  DocumentLoad does not work correctly with context propagation, so traces produced by that library
  are not attached to other traces.

  This library may actually work correctly, but has not been released, and cannot be targeted by
  npm (which does not support installing git subdirectories). Check in to see when this is released,
  and when it does, test replacing the DocumentLoad plugin.

  https://github.com/open-telemetry/opentelemetry-js-contrib/tree/main/plugins/web/opentelemetry-instrumentation-document-load

*/

let tracerProvider: WebTracerProvider;
let rootCtx: Context;

type InitOptions = {
  serviceName: string;
  logToConsole: boolean;
};

/**
 * Initializes OpenTelemetry and registers a provider and a context manager
 * that will work in a browser. This function must be called before other functions
 * such as `withSpan` or `newTrace`, or an error will be thrown.
 */
function initTracer({ serviceName, logToConsole }: InitOptions) {
  propagation.setGlobalPropagator(new HttpTraceContextPropagator());

  tracerProvider = new WebTracerProvider({
    resource: new Resource({
      [ResourceAttributes.SERVICE_NAME]: serviceName,
    }),
  });

  registerInstrumentations({
    // @ts-ignore
    tracerProvider: tracerProvider,
  });

  if (logToConsole) {
    tracerProvider.addSpanProcessor(new SimpleSpanProcessor(new ConsoleSpanExporter()));
  }

  tracerProvider.addSpanProcessor(
    new BatchSpanProcessor(
      new OTLPTraceExporter({
        url: getMetaTagValue('collector_endpoint'),
      }),
    ),
  );

  tracerProvider.register({
    contextManager: new ZoneContextManager(),
    propagator: new HttpTraceContextPropagator(),
  });

  // This needs to execute after the provider is registered.
  rootCtx = createRootCtx();

  return { tracerProvider, rootCtx };
}

/**
 * Starts a span in a new trace, not related to any currently open span
 * context. Useful for reporting traces that don't easily fit into a long-
 * running open trace in a browser.
 */
function newTrace(name: string, fn: (span: Span) => any) {
  if (!tracerProvider || !rootCtx) {
    throw new Error('you must initialize the tracer with initTracer() before using newTrace()');
  }

  const tracer = tracerProvider.getTracer('default');
  const span = tracer.startSpan(name, { root: true, startTime: new Date() });
  return opentelemetry.context.with(opentelemetry.trace.setSpan(opentelemetry.context.active(), span), () => {
    const response = fn(span);

    span.end();

    return response;
  });
}

/**
 * Opens a new span as a child of whatever span context is currently open.
 */
function withSpan(name: string, fn: (span: Span) => any) {
  if (!tracerProvider || !rootCtx) {
    throw new Error('you must initialize the tracer with initTracer() before using withSpan()');
  }

  const tracer = tracerProvider.getTracer('default');
  const span = opentelemetry.trace.getSpan(opentelemetry.context.active())
    ? tracer.startSpan(name, {}, opentelemetry.context.active())
    : tracer.startSpan(name, {}, rootCtx);

  return opentelemetry.context.with(opentelemetry.trace.setSpan(opentelemetry.context.active(), span), () => {
    const response = fn(span);

    span.end();

    return response;
  });
}

function getMetaTagValue(metaTagName: string) {
  const metaElement = [...document.getElementsByTagName('meta')].find((e) => e.getAttribute('name') === metaTagName);
  return (metaElement && metaElement.content) || '';
}

function createRootCtx(): Context {
  const traceparent = getMetaTagValue(TRACE_PARENT_HEADER);
  const baseContext = opentelemetry.propagation.extract(ROOT_CONTEXT, { traceparent });

  const span = opentelemetry.trace.getTracer('default').startSpan('JS ROOT', {}, baseContext);
  opentelemetry.trace.setSpan(context.active(), span);
  opentelemetry.trace.setSpanContext(baseContext, span.spanContext());
  span.end();
  return baseContext;
}

export { newTrace, withSpan, initTracer };
