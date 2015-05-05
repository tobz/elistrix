@moduledoc """
A command represents a named function that can be called.

We keep track of the previous requests for this command within a certain time period (window length), and use the result
of those requests to periodically evaluate the health of this command.  When a command hits certain thresholds, we "trip"
the command, like a circuit breaker, to prevent further requests from going through.  Once the thresholds have cleared,
the command is untripped and requests can flow again.
"""
defmodule Elistrix.Command do
  defstruct fun: nil, tripped: false, trip_reason: "", last_updated_ms: 0, thresholds: %Elistrix.Thresholds{}, requests: []
end
