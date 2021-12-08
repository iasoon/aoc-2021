use "files"
use "collections"

actor Main
  new create(env: Env) =>
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(2)?)) as File
      do
        let answer = match env.args(1)?
        | "1" => solve_part_1(file, env)?
        | "2" => solve_part_2(file, env)
        end
      end
    else
      env.err.print("hit an error")
    end

  fun solve_part_1(file: File, env: Env)? =>
    var count: U64 = 0

    let unique_sizes: Array[USize] = [
      2 // 1
      4 // 4
      3 // 7
      7 // 8
    ]
  
    for line in file.lines() do
      let output_part = (consume line).split_by(" | ")(1)?
      let output_displays = output_part.split_by(" ")
      for display in (consume output_displays).values() do
        if unique_sizes.contains(display.size()) then
          count = count + 1
        end
      end
    end

    env.out.print(count.string())
  
  fun solve_part_2(file: File, env: Env) =>
    let collector = Collector(env.out)

    for line in file.lines() do
      let line' = recover val consume line end
      collector.signal_task_spawned()
      Decoder(line', collector)
    end
    collector.signal_producer_stopped()


actor Decoder
  new create(line: String val, collector: Collector) =>
    try
      let parts = line.split_by(" | ")
      let inputs = parts(0)?.split_by(" ")

      var one_cell: (U8 | None) = None
      var four_cell: (U8 | None) = None
    
      for input in (consume inputs).values() do
        let input' = recover val consume input end
        match input'.size()
        | 2 => one_cell = Display.parse(input')
        | 4 => four_cell = Display.parse(input')
        end
      end

      let one = Display.unwrap(one_cell)?
      let four = Display.unwrap(four_cell)?

      let outputs = parts(1)?.split_by(" ")
    
      var acc: U64 = 0
      for output in (consume outputs).values() do
        let value: U64 = match output.size()
        | 2 => 1
        | 3 => 7
        | 7 => 8
        | 4 => 4
        | 5 =>
          let display = Display.parse(output)
          if Display.is_subset(one, display) then
            3
          elseif Display.overlap(four, display) == 2 then
            2
          else
            5
          end
        | 6 =>
          let display = Display.parse(output)
          if Display.is_subset(four, display) then
            9
          elseif Display.overlap(one, display) == 1 then
            6
          else
            0
          end
        else
          error
        end
        acc = (10 * acc) + value
      end
    
      collector.collect(acc)
    end

actor Collector
  var expected: USize = 0
  var collected: USize = 0
  var producer_stopped: Bool = false
  var accumulator: U64 = 0
  let out: OutStream
  
  new create(out': OutStream) =>
    out = out'

  be signal_task_spawned() =>
    expected = expected + 1
  
  be collect(result: U64) =>
    collected = collected + 1
    accumulator = accumulator + result
    check_ready()
  
  be signal_producer_stopped() =>
    producer_stopped = true
  
  fun check_ready() =>
    if producer_stopped and (expected == collected) then
      out.print(accumulator.string())
    end



primitive Display
  fun parse(string: String box): U8 =>
    var x: U8 = 0
    for char in string.values() do
      x = x or (1 << (char - 'a'))
    end
    x
  
  fun show(display: U8): String =>
    let chars = recover val
      var acc = Array[U8](7)
      for i in Range[U8](0, 8) do
        if ((display >> i) and 1) > 0 then
          acc.push('a' + i)
        end
      end

      acc
    end
    String.from_array(chars)
  
  fun is_subset(a: U8, b: U8): Bool =>
    (a and b) == a
  
  fun overlap(a: U8, b: U8): U8 =>
    (a and b).popcount()
  
  fun unwrap(a: (U8 | None)): U8? =>
    match a
    | let a': U8 => a'
    | let _: None => error
    end