defmodule RssGrabber do
  require Logger
  @feedend  [RssGrabber.Rssgrabber]

  defmodule Feeds do
    defstruct id: nil, items: nil, url: nil, title: nil
  end

  def start_link(backend, query, query_ref, owner, limit) do
    backend.start_link(query, query_ref, owner, limit)
  end

  # recieves feed url and returns parsed items
  def getXML(query, opts \\ []) do
    limit = opts[:limit] || 10

    @feedend |> Enum.map(&spawn_query(&1, query, limit))
             |> await_results(opts)

  end

  # recieves list of feed urls returns list of all items
  def getXMLbatch(links, opts \\ []) do
    limit = opts[:limit] || 3
    backends = opts[:backends] || @feedend

    links
    |> Enum.map(&spawn_query(RssGrabber.Rssgrabber, &1, limit))
    |> await_results(opts)
  end

  # Starts the feed_server to check for new entrys
  # state expects {feed_url, link, id, {}}
  def start_feed_monitor(state, opts) do
    case Supervisor.start_child(RssGrabber.FeedServerSupervisor, [state]) do
      {:ok, pid} ->
        # todo notify channel of update
        IO.puts "Supervised child process started in: #{pid}"
      {:error, reason} ->
        Logger.debug "Server item.link: #{inspect(reason)}"
    end
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    opts = [backend, query, query_ref, self(), limit]
    {:ok, pid} = Supervisor.start_child(RssGrabber.Supervisor, opts)
    monitor_ref = Process.monitor(pid)
    {pid, monitor_ref, query_ref}
  end

  # Starts the recursion to wait for all processes to finish
  defp await_results(children, _opts) do
    await_result(children, [], :infinity)
  end

  # waits for all processes to finish by calling in recursion
  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head

    receive do
      # Recieved successfull answer, add result to accumulator
      {:results, ^query_ref, results} ->
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, [results] ++ acc, timeout)

      # Recieved Error answer, add error to accumulator
      {:error, ^query_ref, error} ->
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, [{:error, error}] ++ acc , timeout)

      # Proccess Died
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        await_result(tail, acc, timeout)
    end
  end

  # Ends the recursion, and returns the result / error
  defp await_result([], acc, _) do
    case acc do
      [{:error, reason}] ->
        {:error, reason}
      [] ->
        # Empty list is considered valid, since the feed just has no items
        {:ok, acc}
      list ->
        if(length(list) > 1) do
          # if more than 1 result is returned, keep as list
          {:ok, acc}
        else
          # if only one resultset to return, remove list and only return first item directly
          {:ok, List.first(acc)}
        end
    end
  end


end
