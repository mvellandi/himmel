defmodule Himmel.CacheInfoHook do
  @moduledoc """
  A very small example hook which simply logs all actions to stdout and keeps
  track of the last executed action.
  """
  use Cachex.Hook

  @doc """
  The arguments provided to this function are those defined in the `args` key of
  your hook registration. This is the same as any old GenServer init phase. The
  value you return in the Tuple will be the state of your hook.
  """
  def init(_),
    do: {:ok, nil}

  @doc """
  This is the actual handler of your hook, receiving a message, results and the
  state. If the hook is a of type `:pre`, then the results will always be `nil`.

  Messages take the form `{ :action, [ args ] }`, so you can quite easily pattern
  match and take different action based on different events (or ignore certain
  events entirely).

  The return type of this function should be `{ :ok, new_state }`, anything else
  is not accepted.
  """

  # def handle_notify(msg, results, _last) do
  #   IO.inspect(msg, label: "Message")
  #   IO.inspect(results, label: "Results")
  #   {:ok, msg}
  # end

  @doc """
  Provides a way to retrieve the last action taken inside the cache.
  """
  def handle_call(:last_action, _ctx, last),
    do: {:reply, last, last}
end
