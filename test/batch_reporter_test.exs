defmodule BatchReporterTest do
  use ExUnit.Case, async: true

  @tag timeout: :infinity
  test "spiiiiike" do
    test_pid = self()

    report_fn = fn events ->
      IO.inspect({:reported, events, length(events)})

      Enum.each(events, fn event ->
        send(test_pid, {:reported, event})
      end)

      # Wait longer the more events queued up.
      # In reality this should be more like O(1) than O(n), but it makes for a nice demonstration.
      Process.sleep(100 * length(events))
    end

    {:ok, pid} = BatchReporter.start_link(report_fn: report_fn, max_events: 100, name: :yolo)

    Enum.each(1..100, fn event_id ->
      event = %{id: event_id}
      BatchReporter.enqueue_event(pid, event)

      # Send events faster and faster
      Process.sleep(100 - event_id)
    end)

    assert_receive {:reported, %{id: 100}}, 10_000
  end
end