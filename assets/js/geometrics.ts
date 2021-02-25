// this will be needed to get a tracer
import opentelemetry, { ROOT_CONTEXT, context, propagation, SpanContext, setSpan } from '@opentelemetry/api'
import { ZoneContextManager } from '@opentelemetry/context-zone'
// tracer provider for web
import { WebTracerProvider } from '@opentelemetry/web'
// and an exporter with span processor
import { ConsoleSpanExporter, BatchSpanProcessor, SimpleSpanProcessor } from '@opentelemetry/tracing'
import { HttpTraceContext, TRACE_PARENT_HEADER } from '@opentelemetry/core'
import { DocumentLoad } from '@opentelemetry/plugin-document-load'
import { registerInstrumentations } from '@opentelemetry/instrumentation'
import { CollectorTraceExporter } from '@opentelemetry/exporter-collector'
import * as otelAPI from "@opentelemetry/api";

// import { HoneycombExporter } from 'opentelemetry-exporter-honeycomb'

function init(opts: { rootCtx?: SpanContext }) {
  propagation.setGlobalPropagator(new HttpTraceContext())

  const tracerProvider = new WebTracerProvider()

  tracerProvider.register({
    contextManager: new ZoneContextManager(),
  })

  registerInstrumentations({
    instrumentations: [new DocumentLoad()],
    // @ts-ignore
    tracerProvider: tracerProvider,
  })

  const collectorOptions = {
    serviceName: 'js',
  }

  // @ts-ignore
  // tracerProvider.addSpanProcessor(new SimpleSpanProcessor(new ConsoleSpanExporter()))
  tracerProvider.addSpanProcessor(new BatchSpanProcessor(new CollectorTraceExporter(collectorOptions)))

  return tracerProvider
}

function createRootCtx() {
  const metaElement = [...document.getElementsByTagName('meta')].find(
    (e) => e.getAttribute('name') === TRACE_PARENT_HEADER,
  )
  const traceparent = (metaElement && metaElement.content) || ''
  const baseContext = opentelemetry.propagation.extract(ROOT_CONTEXT, { traceparent })

  const span = opentelemetry.trace.getTracer('default').startSpan('JS ROOT', {}, baseContext)
  setSpan(context.active(), span)
  span.end()
  return baseContext
}

const tracerProvider = init({})
const rootCtx = createRootCtx()

export { tracerProvider, rootCtx, otelAPI }
