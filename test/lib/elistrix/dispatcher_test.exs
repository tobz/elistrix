defmodule Elistrix.DispatcherTest do
  use ExUnit.Case

  setup_all do
    dispatcher = Elistrix.Dispatcher.start_link(nil)
    {:ok, dispatcher: dispatcher}
  end

  test "can create dispatcher", context do
    assert context[:dispatcher] != nil
  end

  test "can register new command" do
    fun = fn a -> a * 2 end

    result = Elistrix.Dispatcher.register("doubler", fun)
    assert result == :ok
  end

  test "cannot register existing command" do
    fun = fn a -> a * 3 end

    result = Elistrix.Dispatcher.register("tripler", fun)
    assert result == :ok

    result = Elistrix.Dispatcher.register("tripler", fun)
    assert result == :already_exists
  end

  test "can call command" do
    fun = fn a -> a * a end

    result = Elistrix.Dispatcher.register("square", fun)
    assert result == :ok

    result = Elistrix.Dispatcher.run("square", [2])
    assert result == 4
  end
end
