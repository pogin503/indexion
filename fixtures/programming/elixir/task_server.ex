defmodule TaskApp.TaskServer do
  @moduledoc """
  GenServer for managing tasks — holds state in memory.
  """
  use GenServer

  @doc "Starts the task server."
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc "Adds a new task with the given title."
  def add_task(server, title) do
    GenServer.call(server, {:add, title})
  end

  @doc "Lists all tasks."
  def list_tasks(server) do
    GenServer.call(server, :list)
  end

  @impl true
  def init(_opts) do
    {:ok, %{tasks: [], next_id: 1}}
  end

  @impl true
  def handle_call({:add, title}, _from, state) do
    task = %{id: state.next_id, title: title, done: false}
    new_state = %{state | tasks: [task | state.tasks], next_id: state.next_id + 1}
    {:reply, task, new_state}
  end

  def handle_call(:list, _from, state) do
    {:reply, Enum.reverse(state.tasks), state}
  end
end
