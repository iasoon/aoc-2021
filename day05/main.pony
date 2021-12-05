use "files"
use "collections"

actor Main
  new create(env: Env) =>
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(2)?)) as File
      do
        match env.args(1)?
        | "1" => solve_part1(env, file)?
        | "2" => solve_part2(env, file)?
        end
      end
    else
      env.err.print("hit an error")
    end
  
  fun solve_part1(env: Env, file: File)? =>
    let lines = InputParser.parse_file(file)?
    let points = HashMap[Point, U64, HashIs[Point]]
    
    for line in lines.values() do
      if not Util.is_diagonal(line) then
        for pt in LinePoints(line) do
          let count: U64 = points.get_or_else(pt, 0)
          points.insert(pt, count + 1)
        end
      end
    end

    env.out.print(Util.count_overlaps(points).string())
  
  fun solve_part2(env: Env, file: File)? =>
    let lines = InputParser.parse_file(file)?
    let points = HashMap[Point, U64, HashIs[Point]]
    
    for line in lines.values() do
      for pt in LinePoints(line) do
        let count: U64 = points.get_or_else(pt, 0)
        points.insert(pt, count + 1)
      end
    end

    env.out.print(Util.count_overlaps(points).string())




type Point is (I64, I64)
type Line is (Point, Point)

primitive InputParser
  fun parse_file(file: File): Array[Line]? =>
    let lines = Array[Line]
    for line_str in file.lines() do
      lines.push(parse_line(consume line_str)?)
    end
    lines

  fun parse_line(str: String box): Line? =>
    let point_strs = str.split_by(" -> ")
    (parse_point(point_strs(0)?)?, parse_point(point_strs(1)?)?)

  fun parse_point(str: String box): Point? =>
    let coord_strings = str.split_by(",")
    (coord_strings(0)?.i64()?, coord_strings(1)?.i64()?)

primitive Util
  fun order_pair(a: I64, b: I64): (I64, I64) =>
    if a > b then (b, a) else (a, b) end
  
  fun is_diagonal(line: Line): Bool =>
    ((let x_1, let y_1), (let x_2, let y_2)) = line
    (x_1 != x_2) and (y_1 != y_2)

  fun direction(a: I64, b: I64): I64 =>
    if a < b then
      1
    elseif a > b then
      -1
    else
      0
    end
  
  fun count_overlaps(point_counts: HashMap[Point, U64, HashIs[Point]]): U64 =>
    var count: U64 = 0
    for value in point_counts.values() do
      if value > 1 then
        count = count + 1
      end
    end
    count



class ref LinePoints is Iterator[Point]
  var _pos: Point
  var _done: Bool

  let _dx: I64
  let _dy: I64
  let _end: Point
  
   new ref create(line: Line) =>
    ((let x_1, let y_1), (let x_2, let y_2)) = line
    _pos = (x_1, y_1)
    _end = (x_2, y_2)
    _dx = Util.direction(x_1, x_2)
    _dy = Util.direction(y_1, y_2)
    _done = false
  
  fun ref has_next(): Bool =>
    not _done
  
  fun ref next(): Point =>
    (let x, let y) = _pos
    (let x_end, let y_end) = _end
    if (x == x_end) and (y == y_end) then
      _done = true
    else
      _pos = (x + _dx, y + _dy)
    end
    (x, y)