defmodule Elistrix.Command do
  defstruct fun: nil, tripped: false, trip_reason: "", last_updated_ms: 0, thresholds: %Elistrix.Thresholds{}, requests: []
end
