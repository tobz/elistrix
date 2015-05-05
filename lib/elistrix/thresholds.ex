@moduledoc """
Thresholds define the amount of time to keep requests around for, and the average latency, or error percentage
among the requests in the current time window, to set as the threshold to trip a command on.
"""
defmodule Elistrix.Thresholds do
  defstruct window_length: 10, error_threshold: 0.1, latency_threshold: 500
end
