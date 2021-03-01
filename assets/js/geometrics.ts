import opentelemetry, {Context, context, propagation, ROOT_CONTEXT, setSpan, setSpanContext, Span} from '@opentelemetry/api'
import {ZoneContextManager} from '@opentelemetry/context-zone'
import {WebTracerProvider} from '@opentelemetry/web'
import {BatchSpanProcessor, ConsoleSpanExporter, SimpleSpanProcessor} from '@opentelemetry/tracing'
import {HttpTraceContext, TRACE_PARENT_HEADER} from '@opentelemetry/core'
import {DocumentLoad} from '@opentelemetry/plugin-document-load'
import {registerInstrumentations} from '@opentelemetry/instrumentation'
import {CollectorTraceExporter} from '@opentelemetry/exporter-collector'

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
}

function initTracer({serviceName, logToConsole}: InitOptions) {
  propagation.setGlobalPropagator(new HttpTraceContext())

  tracerProvider = new WebTracerProvider()

  tracerProvider.register({
    contextManager: new ZoneContextManager(),
    propagator: new HttpTraceContext(),
  })

  rootCtx = createRootCtx()

  registerInstrumentations({
    instrumentations: [new DocumentLoad()],
    // @ts-ignore
    tracerProvider: tracerProvider,
  })

  if(logToConsole) {
    tracerProvider.addSpanProcessor(new SimpleSpanProcessor(new ConsoleSpanExporter()))
  }

  tracerProvider.addSpanProcessor(new BatchSpanProcessor(new CollectorTraceExporter({
    serviceName,
    url: getMetaTagValue("collector_endpoint")
  })))

  return {tracerProvider, rootCtx}
}

function getMetaTagValue(metaTagName: string) {
  const metaElement = [...document.getElementsByTagName('meta')].find(
      (e) => e.getAttribute('name') === metaTagName,
  )
  return (metaElement && metaElement.content) || ''
}

function createRootCtx(): Context {
  const traceparent = getMetaTagValue(TRACE_PARENT_HEADER);
  const baseContext = opentelemetry.propagation.extract(ROOT_CONTEXT, { traceparent })

  const span = opentelemetry.trace.getTracer('default').startSpan('JS ROOT', {}, baseContext)
  setSpan(context.active(), span)
  setSpanContext(baseContext, span.context())
  span.end()
  return baseContext
}

function withSpan(name: string, fn: (span: Span) => any) {
  if(!tracerProvider || !rootCtx) { throw new Error("must initialize tracer by calling initTracer()")}

  const tracer = tracerProvider.getTracer("default")
  const span = tracer.startSpan(name, {}, rootCtx)

  return opentelemetry.context.with(setSpan(opentelemetry.context.active(), span), () => {
    const response = fn(span)
    span.end()

    return response
  })
}

export { withSpan, initTracer }
