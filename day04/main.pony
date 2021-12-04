use "files"
use "collections"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(2)?)) as File
      do
        (let boards, let numbers) = read_input(file)?
        let score = match env.args(1)?
        | "1" => solve_part1(boards, numbers)?
        | "2" => solve_part2(boards, numbers)?
        end
        env.out.print(score.string())
      end

    end
  
  fun read_input(file: File): (Array[Board], Array[U64])? =>
    let lines = file.lines()

    let numbers = Array[U64]
    
    // parse numbers
    for num in lines.next()?.split_by(",").values() do
      numbers.push(num.u64()?)
    end

    // skip empty line
    lines.next()?

    let boards = Array[Board]

    var line_buf = Array[String]
    for line in lines do
      if line.size() > 0 then
        line_buf.push(consume line)
      else
        if line_buf.size() > 0 then
          boards.push(Parser.parse_board(line_buf)?)
          line_buf = Array[String]
        end
      end
    end
    boards.push(Parser.parse_board(line_buf)?)

    (boards, numbers)


  fun solve_part1(boards: Array[Board], numbers: Array[U64]): U64? =>
    for number in numbers.values() do
      for board in boards.values() do
        board.cross_number(number)
        if board.has_won() then
          let score = board.remaining_sum() * number
          return score
        end
      end
    end

    // no solution found
    error

  
  fun solve_part2(boards: Array[Board], numbers: Array[U64]): U64? =>
    var current_boards = boards
    for number in numbers.values() do
      let remaining_boards = Array[Board]
  
      for board in current_boards.values() do
        board.cross_number(number)
        if not board.has_won() then
          remaining_boards.push(board)
        elseif current_boards.size() == 1 then
          let score = board.remaining_sum() * number
          return score
        end
      end
      current_boards = remaining_boards
    end

    // no solution found
    error



primitive Parser
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
      Parser.parse_line(line, values)?
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
    var score: U64 = 0
    for value in values.values() do
      match value
      | let _: Crossed => None
      | let n: U64 => score = score + n
      end
    end
    score
  

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
  fun all_crossed(array: Array[(U64 | Crossed)]): Bool =>
    for value in array.values() do
      match value
      | let _: U64 => return false
      end
    end
    true