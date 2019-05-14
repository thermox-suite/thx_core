defmodule ThxCore.ScheduleProcess do
  use GenServer
  import Ecto.Query, only: [from: 2]

  @thermostat_writer Application.get_env(:thx_core, :thermostat_writer)

  def init([id, name]) do
    schedule = ThxCore.Repo.all(from s in ThxCore.Schema.Schedule, where: s.sensor_id == ^id, select: {s.weekday, s.temperature})

    {:ok, %{id: id, name: name, schedule: schedule}}
  end

  def start_link(id, name) do
    GenServer.start_link(__MODULE__, [id, name], name: via_tuple(name))
  end

  defp via_tuple(name) do
    {:via, Registry, {ThxCore.TemperatureScheduleRegistry, "scheduler_#{name}"}}
  end

  def update_thermostat(name, temperature) do
    GenServer.call(via_tuple(name), {:update_thermostat, temperature})
  end

  def handle_call({:update_thermostat, temp}, _from, state) do

    {_, {h, _, _}} = :calendar.local_time()
    [{_, sch}] = state.schedule

    case temp > Enum.at(sch, h) do
      true ->
        {:reply, :nop, state}
      false ->
        @thermostat_writer.switch_on(state.name)
        {:reply, :on, state}
    end




  end
end
