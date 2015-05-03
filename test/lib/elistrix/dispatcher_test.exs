defmodule Elistrix.DispatcherTest do
  use ExUnit.Case, async: true

  setup_all do
    dispatcher = Elistrix.Dispatcher.start_link
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

  test "cannot call nonexistent command" do
    result = Elistrix.Dispatcher.run("fake_command", [1,2,3])
    assert result == :does_not_exist
  end

  test "command gets tripped when error threshold is exceeded" do
    fun = fn -> :error end

    # 10% of errors within window.  this will be triggered on the 2nd call if the 1st call fails.
    result = Elistrix.Dispatcher.register("error_threshold", fun, %Elistrix.Thresholds{error_threshold: 0.1})
    assert result == :ok

    result = Elistrix.Dispatcher.run("error_threshold")
    assert result == :error

    result = Elistrix.Dispatcher.run("error_threshold")
    assert result == {:error, {:tripped, "exceeded error threshold"}}
  end

test "command gets tripped when latency threshold is exceeded" do
    fun = fn ->
      :timer.sleep(125)
      :ok
    end

    # 500ms latency threshold within window.  this will be triggered on the 2nd call if the 1st call takes over 100ms.
    result = Elistrix.Dispatcher.register("latency_threshold", fun, %Elistrix.Thresholds{latency_threshold: 100})
    assert result == :ok

    result = Elistrix.Dispatcher.run("latency_threshold")
    assert result == :ok

    result = Elistrix.Dispatcher.run("latency_threshold")
    assert result == {:error, {:tripped, "exceeded latency threshold"}}
  end

  test "command gets untripped after the window length expires" do
    fun = fn -> :error end

    result = Elistrix.Dispatcher.register("expire", fun, %Elistrix.Thresholds{window_length: 1})
    assert result == :ok

    result = Elistrix.Dispatcher.run("expire")
    assert result == :error

    result = Elistrix.Dispatcher.run("expire")
    assert result == {:error, {:tripped, "exceeded error threshold"}}

    :timer.sleep(1000)

    result = Elistrix.Dispatcher.run("expire")
    assert result == :error
  end
end
