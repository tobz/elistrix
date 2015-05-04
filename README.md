# elistrix
A latency / fault tolerance library to help isolate your applications from an uncertain world of slow or failed services.

Modeled after [Hystrix](https://github.com/Netflix/Hystrix) but written in Elixir.

# high level goals
- simple interface to protect any function call in latency and error rate threshold mode
- metrics collection to easily identify and inspect circuit breakers in real-time

# general overflow

Everything starts with registering a command with `Elistrix.Dispatcher`.  You must pass a function pointer i.e. `&Some.Module.function/2`.  You can optionally specify custom thresholds to change the following:
- window length (the amount of time we'll keep a history of previous requests for the command)
- latency threshold (the average latency, in milliseconds, of all the requests in the current window)
- error threshold (percentage of requests that have failed of all the requests in the current window)

Once you register your command, you can call it via the dispatcher.  You can pass a list of arguments to be applied to the function.  Commands are executed in the caller process, to avoid complexity in Elistrix -- needing to maintain worker process pooling, needing to do weird calling convention tricks.

We track the latency of the call, and we track the return value.  If your function returns something similar to `:ok` or `:error` or `{:error, ....}` then we can track the successes and failures, otherwise we can only track the latency of these calls.

When a command is tripped -- when either the latency or error percentage threshold is crossed -- calls to the command result in `{:error, {:tripped, "reason here"}}` to let the caller know the command is in a tripped state.  Otherwise, the original return value of the function called is returned back.

The state of a command -- whether it's tripped or not -- is updated once every 500ms.  Thus, failure conditions are realized quickly but scenarios that require faster realization aren't currently possible.
