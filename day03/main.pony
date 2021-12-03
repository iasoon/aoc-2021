use "files"
use "collections"

actor Main
  new create(env: Env) =>
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(2)?)) as File
      do
        (let numbers, let num_bits) = Util.parse_number_file(file)?

        let sub = match env.args(1)?
        | "1" => Part1(env, numbers, num_bits)
        | "2" => Part2(env, numbers, num_bits)?
        end
      end
    else
      env.err.print("invalid file")
    end


primitive Part1
  fun apply(env: Env, numbers: Array[U64], num_bits: USize) =>  
    var mask = ((1 << num_bits) - 1).u64()

    let gamma = Util.most_common_bits(numbers, num_bits)
    let epsilon = gamma xor mask

    env.out.print((gamma * epsilon).string())


primitive Part2
  fun apply(env: Env, numbers: Array[U64], num_bits: USize)? =>
    let oxygen_rating = Util.determine_rating(numbers, num_bits, false)?
    let scrubber_rating = Util.determine_rating(numbers, num_bits, true)?
    env.out.print((oxygen_rating * scrubber_rating).string())


primitive Util
  fun parse_number_file(file: File): (Array[U64], USize)? =>
    let lines = file.lines()
    let numbers = Array[U64]

    let first_line = lines.next()?
    (let first_number, let num_bits) = first_line.read_int[U64](where base=2)?
    numbers.push(first_number)

    for line in lines do
      (let number, let bits_read) = line.read_int[U64](where base=2)?
      if num_bits != bits_read then error end
      numbers.push(number)
    end

    (numbers, num_bits)


  fun most_common_bits(numbers: Array[U64], num_bits: USize): U64 =>
    // counters: LSB -> MSB
    let counters = Array[U64].init(0, num_bits)

    try
      for number in numbers.values() do
        for (ix, count) in counters.pairs() do
          counters(ix)? = count + ((number >> ix.u64()) and 1)
        end
      end
    end
  
    var value: U64 = 0
    for (ix, count) in counters.pairs() do
      let bit: U64 = if count >= (numbers.size().u64() - count) then 1 else 0 end
      value = value + (bit << ix.u64())
    end
    value


  fun most_common_bit(numbers: Array[U64], pos: U64): U64 =>
    var count: U64 = 0
    for number in numbers.values() do
      count = count + ((number >> pos) and 1)
    end
    
    if count >= (numbers.size().u64() - count) then 1 else 0 end


  fun apply_filter(numbers: Array[U64], pos: U64, negate: Bool): Array[U64] =>
    var value = most_common_bit(numbers, pos)
    if negate then value = 1 - value end

    let matches = Array[U64]
    for number in numbers.values() do
      if ((number >> pos) and 1) == value then
        matches.push(number)
      end
    end

    matches
  
  fun determine_rating(numbers: Array[U64], num_bits: USize, negate: Bool): U64? =>
    var pos = num_bits.u64()
    var candidates = numbers

    while (pos > 0) and (candidates.size() > 1) do
      pos = pos - 1
      candidates = apply_filter(candidates, pos, negate)
    end

    candidates(0)?
