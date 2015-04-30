defmodule Elistrix.RunnerTest do
  use ExUnit.Case, async: true

  test "starting the runner" do
    runner = Elistrix.Runner.start_link(nil, nil)
    assert runner != nil 
  end
end
