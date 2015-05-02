defmodule Elistrix.DispatcherTest do
  use ExUnit.Case

  setup do
    Elistrix.Dispatcher.stop
    dispatcher = Elistrix.Dispatcher.start_link(nil)
    {:ok, dispatcher: dispatcher}
  end

  test "can create dispatcher", context do
    assert context[:dispatcher] != nil
  end

  test "can register new function" do
    fun = fn a -> a * 2 end

    result = Elistrix.Dispatcher.register("doubler", fun)
    assert result == :ok
  end

  test "cannot register existing function" do
    fun = fn a -> a * 2 end

    result = Elistrix.Dispatcher.register("doubler", fun)
    assert result == :ok

    result = Elistrix.Dispatcher.register("doubler", fun)
    assert result == :already_exists
  end
end
