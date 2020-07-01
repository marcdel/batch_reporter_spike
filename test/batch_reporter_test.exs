defmodule BatchReporterTest do
  use ExUnit.Case, async: true

  @tag timeout: :infinity
  test "spiiiiike" do
    test_pid = self()

    report_fn = fn events ->
      Enum.each(events, fn event ->
        send(test_pid, {:reported, event})
      end)

      IO.inspect({:reported, events})
      Process.sleep(100 * length(events))
    end

    {:ok, pid} = BatchReporter.start_link(report_fn: report_fn, name: :yolo)

    Enum.each(1..100, fn event_id ->
      event = %{id: event_id}
      BatchReporter.enqueue_event(pid, event)
      Process.sleep(100 - event_id)
    end)

    assert_receive {:reported, %{id: 100}}, 1000
  end
end