import opentelemetry, {Context, context, propagation, ROOT_CONTEXT, setSpan, Span} from '@opentelemetry/api'
import {ZoneContextManager} from '@opentelemetry/context-zone'
import {WebTracerProvider} from '@opentelemetry/web'
import {BatchSpanProcessor, ConsoleSpanExporter, SimpleSpanProcessor} from '@opentelemetry/tracing'
import {HttpTraceContext, TRACE_PARENT_HEADER} from '@opentelemetry/core'
import {DocumentLoad} from '@opentelemetry/plugin-document-load'
import {registerInstrumentations} from '@opentelemetry/instrumentation'
import {CollectorTraceExporter} from '@opentelemetry/exporter-collector'

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
  })

  registerInstrumentations({
    instrumentations: [new DocumentLoad()],
    // @ts-ignore
    tracerProvider: tracerProvider,
  })

  if(logToConsole) {
    tracerProvider.addSpanProcessor(new SimpleSpanProcessor(new ConsoleSpanExporter()))
  }

  tracerProvider.addSpanProcessor(new BatchSpanProcessor(new CollectorTraceExporter({serviceName})))

  rootCtx = createRootCtx()

  return {tracerProvider, rootCtx}
}

function createRootCtx(): Context {
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
