import { Context, Span } from '@opentelemetry/api';
import { WebTracerProvider } from '@opentelemetry/web';
declare type InitOptions = {
    serviceName: string;
    logToConsole: boolean;
};
/**
 * Initializes OpenTelemetry and registers a provider and a context manager
 * that will work in a browser. This function must be called before other functions
 * such as `withSpan` or `newTrace`, or an error will be thrown.
 */
declare function initTracer({ serviceName, logToConsole }: InitOptions): {
    tracerProvider: WebTracerProvider;
    rootCtx: Context;
};
/**
 * Starts a span in a new trace, not related to any currently open span
 * context. Useful for reporting traces that don't easily fit into a long-
 * running open trace in a browser.
 */
declare function newTrace(name: string, fn: (span: Span) => any): any;
/**
 * Opens a new span as a child of whatever span context is currently open.
 */
declare function withSpan(name: string, fn: (span: Span) => any): any;
export { newTrace, withSpan, initTracer };
//# sourceMappingURL=geometrics.d.ts.map