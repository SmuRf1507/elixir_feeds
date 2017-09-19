defmodule RssGrabber.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    RssGrabber.Supervisor.start_link()
    RssGrabber.FeedServerSupervisor.start_link()
  end
end
