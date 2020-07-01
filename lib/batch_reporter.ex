defmodule BatchReporter do
  use GenServer

  @default_state %{report_scheduled: false, unreported_events: []}

  def start_link(opts) do
    {report_fn, opts} = Keyword.pop(opts, :report_fn, &do_report_events/1)
    state = Map.put(@default_state, :report_fn, report_fn)

    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(state) do
    {:ok, state}
  end

  def enqueue_event(pid \\ __MODULE__, event) do
    GenServer.cast(pid, {:enqueue_event, event})
  end

  def handle_cast({:enqueue_event, event}, state) do
    updated_state =
      state
      |> do_enqueue_event(event)
      |> maybe_report_events()

    {:noreply, updated_state}
  end

  def handle_info(:report_events, state) do
    state.report_fn.(state.unreported_events)

    updated_state =
      state
      |> reset_report_scheduled()
      |> clear_unreported_events()

    {:noreply, updated_state}
  end

  defp do_enqueue_event(state, event) do
    %{state | unreported_events: state.unreported_events ++ [event]}
  end

  defp clear_unreported_events(state) do
    %{state | unreported_events: []}
  end

  defp set_report_scheduled(state) do
    %{state | report_scheduled: true}
  end

  defp reset_report_scheduled(state) do
    %{state | report_scheduled: false}
  end

  defp maybe_report_events(%{unreported_events: []} = state), do: state

  defp maybe_report_events(%{report_scheduled: true} = state), do: state

  defp maybe_report_events(state) do
    send(self(), :report_events)
    set_report_scheduled(state)
  end

  defp do_report_events([]), do: {:ok, []}

  defp do_report_events(events) do
    {:ok, events}
  end
end