defmodule ThxCore.SensorProcess do
  use GenServer

  @reading_interval 5_000


  def init([name, description]) do
    Process.send_after(self(), :get_temperature_scheduled, @reading_interval)
    {:ok, %{name: name, description: description}}

  end

  @spec start_link(any(), any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(name, description) do
    GenServer.start_link(__MODULE__, [name, description], name: via_tuple(name))
  end

  defp via_tuple(name) do
    {:via, Registry, {ThxCore.SensorRegistry, name}}
  end

  def get_temperature(name) do
    GenServer.call(via_tuple(name), :get_temperature)
  end

  def handle_call(:get_temperature, _from, state) do
    # TODO use behaviours for testing
    temp = ThxCore.SensorReader.read_temp(state.name)
    {:reply, {:ok, temp}, state}
  end

  def handle_info(:get_temperature_scheduled, state) do
    # temp = ThxCore.SensorReader.read_temp(state.name)
    IO.inspect state, label: "Reading"
    Process.send_after(self(), :get_temperature_scheduled, @reading_interval)
    {:noreply, state}
  end
end