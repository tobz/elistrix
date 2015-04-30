# elistrix
A latency / fault tolerance library to help isolate your applications from an uncertain world of slow or failed services.

Modeled after [Hystrix](https://github.com/Netflix/Hystrix) but written in Elixir.

# High level goals
- A simple interface to protect any call in either latency or failure threshold mode
- Support for protecting ad-hoc calls or defining a call template for global protection
- Metrics collection to easily identify and inspect circuit breakers in real-time
