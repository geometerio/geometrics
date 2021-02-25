import { Context, Span } from '@opentelemetry/api';
import { WebTracerProvider } from '@opentelemetry/web';
declare type InitOptions = {
    serviceName: string;
    logToConsole: boolean;
};
declare function initTracer({ serviceName, logToConsole }: InitOptions): {
    tracerProvider: WebTracerProvider;
    rootCtx: Context;
};
declare function withSpan(name: string, fn: (span: Span) => any): any;
export { withSpan, initTracer };
//# sourceMappingURL=geometrics.d.ts.map