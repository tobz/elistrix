defmodule Elistrix.DispatcherTest do
  use ExUnit.Case

  test "can create dispatcher" do
    dispatcher = Elistrix.Dispatcher.start_link(nil)
    assert dispatcher != nil
  end
end
