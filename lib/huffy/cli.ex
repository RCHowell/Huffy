defmodule Huffy.CLI do
  require Logger

  @moduledoc """
  CLI Module for the Huffy Executable

  This module is responsible for parsing arguments
  and delegating function execution
  """

  @doc """
  Entry point of the executable
  """
  def main(args \\ []) do
    args
    |> parse_args
    |> respond_to_args
  end

  defp parse_args(args) do
    { switches, [filepath | _], _ } = args |> OptionParser.parse([
      switches: [
        help: :boolean,
        info: :boolean,
        radix: :integer,
        # out: :string,
      ]
    ])
    {switches, filepath}
  end

  defp respond_to_args({switches, filepath}) do
    # Disable logging by default
    unless switches[:info] do
      Logger.disable(self())
    end
    # Print help message and exit if user specifies help
    if switches[:help] do
      IO.puts(help_message())
      System.halt(0)
    end
    # Decide whether to encode or decode based upon extension
    case {File.stat(filepath), Path.extname(filepath)} do
      {{:ok, info}, ".huff"} ->
        Logger.info("Decoding #{filepath}")
        log_file_size(info)
        Huffy.Processor.decode(filepath)
        :decode
      {{:ok, info}, ".txt"} ->
        Logger.info("Encoding #{filepath}")
        log_file_size(info)
        Huffy.Processor.encode(filepath)
        :encode
      {{:error, reason}, _} -> reason
      _ -> :error
    end |> IO.puts
  end

  defp help_message() do
    """

    Huffy - Plaintext compression using Huffman encoding.

    Default behavior is to convert the specified file
    .huff -> .txt
    .txt -> .huff

    A .huff file is nothing more than a dictionary header (with
    codes as keys and source symbols as values) followed by the data bytes.

    Usage:
    huffy <file> --<option1> --<option2>

    Options:
    --help - prints this message
    --info - turns on info logging (verbose execution)
    --ext <n> - specifies degree of information source extension
    """
  end

  defp log_file_size(info) do
    Logger.info("Initial Size: #{info.size} bytes")
  end

end
