defmodule Mix.Hex do
  @moduledoc false
  @hex_requirement  ">= 0.5.0"
  @hex_mirror       "https://hexpmrepo.global.ssl.fastly.net"

  @doc """
  Returns `true` if `Hex` is loaded or installed. Otherwise returns `false`.
  """
  @spec ensure_installed?(atom) :: boolean
  def ensure_installed?(app) do
    if Code.ensure_loaded?(Hex) do
      true
    else
      shell = Mix.shell
      shell.info "Could not find Hex, which is needed to build dependency #{inspect app}"

      if shell.yes?("Shall I install Hex?") do
        Mix.Tasks.Local.Hex.run ["--force"]
      else
        false
      end
    end
  end

  @doc """
  Returns `true` if it has the required `Hex`. If an update is performed, it then exits.
  Otherwise returns `false` without updating anything.
  """
  @spec ensure_updated?() :: boolean
  def ensure_updated?() do
    cond do
      not Code.ensure_loaded?(Hex) ->
        false
      not Version.match?(Hex.version, @hex_requirement) ->
        Mix.shell.info "Mix requires Hex #{@hex_requirement} but you have #{Hex.version}"

        if Mix.shell.yes?("Shall I abort the current command and update Hex?") do
          Mix.Tasks.Local.Hex.run ["--force"]
          exit({:shutdown, 0})
        end

        false
      true ->
        true
    end
  end

  @doc """
  Ensures `Hex` is started.
  """
  def start do
    try do
      Hex.start
    catch
      kind, reason ->
        stacktrace = System.stacktrace
        Mix.shell.error "Could not start Hex. Try fetching a new version with " <>
                        "\"mix local.hex\" or uninstalling it with \"mix archive.uninstall hex.ez\""
        :erlang.raise(kind, reason, stacktrace)
    end
  end

  @doc """
  Returns the url to the Hex mirror.
  """
  def mirror do
    System.get_env("HEX_MIRROR") || cdn() || @hex_mirror
  end

  # TODO: Remove this once 1.3 is out
  defp cdn do
    if cdn = System.get_env("HEX_CDN") do
      Mix.shell.error "warning: the HEX_CDN environment variable has been deprecated " <>
                      "in favor of HEX_MIRROR"
      cdn
    end
  end
end
