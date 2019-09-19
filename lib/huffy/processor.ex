defmodule Huffy.Processor do
  use Bitwise
  require Logger

  def encode(filepath) do
    radix = 1
    # Calculate the Huffman codes for each symbol in the input file
    codes = File.stream!(filepath, [], 1 * radix)
    |> make_freq_dist
    |> Huffy.Huffman.dist_to_tree
    |> Huffy.Huffman.tree_to_codes
    outfile = Path.rootname(filepath) <> ".huff" |> open_file(:write)
    # Read input file symbol by symbol and write bytes to output file
    infile = filepath |> open_file(:read)
    write_header(outfile, codes)
    Logger.info("Writing bytes to outfile")
    write_bytes_rec(infile, outfile, codes, "")
    File.close(outfile)
  end

  def decode(filepath) do
    # header is a map with bitstrings for keys and 1 bytes characters for values
    { header, data } = File.read!(filepath) |> parse_file_data
    message = parse_data(data, header)
    IO.puts(message)
  end

  @doc """
  Construct a character frequency distribution from a file stream
  """
  def make_freq_dist(stream) do
    Logger.info("Creating frequency distribution")
    Enum.reduce(stream, %{}, fn(char, freqs) ->
      Map.update(freqs, char, 1, &(&1+1))
    end)
  end

  def parse_data(data, header) do
    parse_data_rec(data, header, 1, "")
  end

  defp open_file(path, mode) do
    Logger.info("Openning file #{path} with mode #{inspect(mode)}")
    case File.open(path, [:binary, mode]) do
      {:ok, outfile} -> outfile
      {:error, reason} ->
        IO.puts("Error openning #{path}")
        IO.puts(reason)
        System.halt(1)
    end
  end

  defp write_bytes_rec(infile, outfile, codes, acc) do
    # 1 is the number of bytes being read... it should be 1 * radix
    case IO.binread(infile, 1) do
      :eof ->
        # Round acc to the nearest multiple of 8 ensuring one extra byte
        n = bit_size(acc)
        padding_size = 8 - rem(n, 8)
        # Pad the bitstring with zeroes til it forms a multile of 8
        # This makes the bitstring into a binary, and it can be written to outfile
        to_write = << acc::bitstring, <<0::size(padding_size)>> >>
        IO.binwrite(outfile, to_write)
      {:error, reason} ->
        # Super rare error according to Elixir docs
        IO.puts(reason)
        System.halt(1)
      sym ->
        code = Map.get(codes, sym)
        acc = << acc::bitstring, code::bitstring >>
        case bit_size(acc) >= 512 do
          true ->
            # Strip first 512 bits and write them to the file
            tail_size = bit_size(acc) - 512
            << val::size(512), acc::size(tail_size) >> = acc
            IO.binwrite(outfile, <<val::size(512)>>)
            write_bytes_rec(infile, outfile, codes, <<acc::size(tail_size)>>)
          false ->
            write_bytes_rec(infile, outfile, codes, acc)
        end
    end
  end

  defp write_header(file, codes) do
    Logger.info("Writing header")
    # code_bytes = :erlang.term_to_binary(codes)
    code_bytes = map_to_binary(codes)
    IO.binwrite(file, "HUFF")
    # Radix 1 hardcoded for now
    IO.binwrite(file, << 1 >>)
    IO.binwrite(file, << byte_size(code_bytes) :: size(32) >>)
    IO.binwrite(file, code_bytes)
  end

  defp map_to_binary(map) do
    Enum.reduce(map, "", fn({key, val}, acc) ->
      n = bit_size(val)
      padding_size = 8 - rem(n, 8)
      value = << val::bitstring, <<0::size(padding_size)>> >>
      acc <> key <> << n::size(8) >> <> value
    end)
  end

  defp parse_file_data(contents) do
    << "HUFF", 1, header_size::size(32), tail::binary >> = contents
    << header_data:: binary - size(header_size), data::binary >> = tail
    { parse_header_data(header_data, %{}), data }
  end

  # Base case of header parsing recursion, just return the header
  defp parse_header_data(<<>>, header) do
    header
  end

  # Recursive method for parsing header data
  defp parse_header_data(header_data, header) do
    # Radix = 1, so source symbols are one byte
    # Parse the value and bitstring length for the soon-to-be-parsed codeword
    << val::size(8), len::size(8), tail::bitstring >> = header_data
    # Trim the extra (but necessary) 0's off the end of the parsed codeword
    padding_size = 8 - rem(len, 8)
    << key::size(len), _::size(padding_size), tail::bitstring >> = tail
    # Add bitstring codeword as decoding header key, and the 1 byte souce symbol as the key
    IO.puts("Key: #{key}, Len: #{len}, Char: #{val}")
    new_header = Map.put_new(header, << key::size(len) >>, val)
    parse_header_data(tail, new_header)
  end

  defp parse_data_rec(data, header, n, acc) when n <= bit_size(data) do
    << key::size(n), tail::bits >> = data
    case Map.get(header, << key::size(n) >>) do
      nil ->
        parse_data_rec(data, header, n + 1, acc)
      val ->
        parse_data_rec(tail, header, 1, << val >> <> acc)
    end
  end

  defp parse_data_rec(_, _, _, acc) do
    String.reverse(acc)
  end


end
