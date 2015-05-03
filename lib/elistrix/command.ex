defmodule Elistrix.Command do
  defstruct fun: nil, tripped: false, thresholds: %Elistrix.Thresholds{}, requests: []
end
