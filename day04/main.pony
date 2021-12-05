use "files"
use "collections"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'
    try
      let collector = match env.args(1)?
      | "1" => Collector(this, FirstWin)
      | "2" => Collector(this, LastWin)
      else
        error
      end

      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(2)?)) as File
      do
        dispatch_inputs(file, collector)?
      end
    else
      env.err.print("hit an error")
    end
  
  fun dispatch_inputs(file: File, collector: Collector)? =>
    let lines = file.lines()

    let numbers: Array[U64] val = read_bingo_numbers(lines)?

    var line_buf: Array[String] iso = recover Array[String] end
    for line in lines do
      if line.size() > 0 then
        line_buf.push(consume line)
      else
        if line_buf.size() > 0 then
          let prev_buf = line_buf = recover Array[String] end
          collector.signal_board_creation()
          BoardSolver(consume prev_buf, numbers, collector)
        end
      end
    end

    // for the last buffer
    if line_buf.size() > 0 then
      collector.signal_board_creation()
      BoardSolver(consume line_buf, numbers, collector)
    end


    collector.signal_all_started()
      
  
  fun read_bingo_numbers(lines: FileLines ref): Array[U64] val? =>
    recover
      let nums = Array[U64]
    
      // parse numbers
      for num in lines.next()?.split_by(",").values() do
        nums.push(num.u64()?)
      end

      nums
    end

  be receive_answer(answer: U64) =>
    env.out.print(answer.string())


interface Reducer[A: Any val]
  fun reduce(a: A, b: A): A

  fun reduce_opt(opt: (A | None), item: A): A =>
    match opt
    | let _: None => item
    | let a: A => reduce(a, item)
  end

  fun reduce_array(arr: Array[A] box): (A | None) =>
    var acc: (A | None) = None
    for item in arr.values() do
      acc = reduce_opt(acc, item)
    end
    acc


primitive FirstWin is Reducer[(USize, U64)]
  fun reduce(a: (USize, U64), b: (USize, U64)): (USize, U64) =>
    (let t1, _) = a
    (let t2, _) = b
    if t1 > t2 then b else a end


primitive LastWin is Reducer[(USize, U64)]
  fun reduce(a: (USize, U64), b: (USize, U64)): (USize, U64) =>
    (let t1, _) = a
    (let t2, _) = b
    if t1 < t2 then b else a end


actor Collector
  // whether all tasks have started
  var all_started: Bool = false
  var started: USize = 0

  let collected: Array[(USize, U64)]= Array[(USize, U64)]
  let callback_to: Main

  let reducer: Reducer[(USize, U64)] val

  new create(main: Main, reducer': Reducer[(USize, U64)] val) =>
    callback_to = main
    reducer = reducer'

  fun check_done() =>
    if all_started and (started == collected.size()) then
      let res = reducer.reduce_array(collected)
      match res
      | (_, let score: U64) => callback_to.receive_answer(score)
      end
    end

  be collect(turns: USize, score: U64) =>
    collected.push((turns, score))
    check_done()
  
  be signal_board_creation() =>
    started = started + 1
  
  be signal_all_started() =>
    all_started = true
    check_done()


actor BoardSolver
  new create(line_buf: Array[String] iso, numbers: Array[U64] val, collector: Collector) =>
    try
      let board = BoardParser.parse_board(consume line_buf)?
      (let i, let score) = Util.solve_board(board, numbers)?
      collector.collect(i, score)
    end


primitive BoardParser
  fun parse_line(line': String val, values: Array[BoardValue] ref)? =>
    var line = line'
    while line.size() > 0 do
      // drop leading spaces
      if line.at(" ", 0) then
        line = line.trim(1, line.size())
        continue
      end

      (let value, let bytes_read) = line.read_int[U64]()?
      values.push(value)
      line = line.trim(bytes_read, line.size())
    end
  
  fun parse_board(lines: Array[String]): Board? =>
    let values = Array[(U64 | Crossed)]
    for line in lines.values() do
      parse_line(line, values)?
    end

    let height = lines.size()
    let width = values.size() / height

    Board(values, (height, width))


// value that has been crossed off the bingo board
primitive Crossed

type BoardValue is (U64 | Crossed)
  
class Board
  var values: Array[(U64 | Crossed)]
  var width: USize
  var height: USize


  new create(values': Array[(U64 | Crossed)], shape: (USize, USize)) =>
    (let h, let w) = shape
    width = w
    height = h
    values = values'


  fun ref cross_number(number: U64) =>
    for (ix, value) in values.pairs() do
      try
        match value
        | let n: U64 => if n == number then values(ix)? = Crossed end
        end
      end
    end


  fun has_won(): Bool =>
    // check rows
    for i in Range(0, height) do
      let slice = values.slice(i*width, (i+1)*width)
      if Util.all_crossed(slice) then return true end
    end

    // check columns
    for i in Range(0, width) do
      let slice = values.slice(i, values.size(), width)
      if Util.all_crossed(slice) then return true end
    end

    false

  
  fun remaining_sum(): U64 =>
    var sum: U64 = 0
    for value in values.values() do
      match value
      | let _: Crossed => None
      | let n: U64 => sum = sum + n
      end
    end
    sum

  fun print(out: OutStream) =>
    for row in Range(0, height) do
      let row_values = values.slice(row*width, (row+1)*width)
      for value in row_values.values() do
        var repr = match value
        | let _: Crossed => "X"
        | let n: U64 => n.string()
        end
        if repr.size() == 1 then repr = " " + repr end
        out.write(repr + " ")
      end
      out.write("\n")
    end


primitive Util
  fun solve_board(board: Board ref, numbers: Array[U64] box): (USize, U64)? =>
    for (i, number) in numbers.pairs() do
      board.cross_number(number)
      if board.has_won() then
        let score = number * board.remaining_sum()
        return (i, score)
      end
    end

    error


  fun all_crossed(array: Array[(U64 | Crossed)]): Bool =>
    for value in array.values() do
      match value
      | let _: U64 => return false
      end
    end
    true