# Huffy
> Plaintext compression using Huffman encoding.

This was a fun weekend project created while studying Roman's Coding and Information Theory.

## Build the binary
```
mix escript.build
```


## Usage
Default behavior is to convert the specified file

```
.huff -> .txt
.txt -> .huff
```

A .huff file is nothing more than a dictionary header (with
codes as keys and source symbols as values) followed by the data bytes.

Usage:

```
huffy <file> --<option1> --<option2>
```

Options:

```
--help # prints this message
--info # turns on info logging (verbose execution)
--ext <n> # specifies degree of information source extension
```

## File Format `.huff`
Check it out in a hex viewer :)

### Structure
Pattern matching makes decoding ez pz

```
<< "HUFF", 1, header_size::size(32), tail::binary >> = contents
<< header_data:: binary - size(header_size), data::binary >> = tail
```

### Tail

#### Header

A key is a source symbol of size r (radix), and a value is a series
of bits representing the code word.

```
Huffman Tree

1| A
0|--
  0| B
  1| C
  
%{
  << a :: size(r) >> => <<  1 :: size(1) >>,
  << b :: size(r) >> => << 00 :: size(2) >>,
  << c :: size(r) >> => << 01 :: size(2) >>
}
```

#### Body
Everything else is the compressed bytes of the source file
