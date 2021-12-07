use "files"
use "collections"

actor Main
  new create(env: Env) =>
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(2)?)) as File
      do
        let positions = read_positions(file)?
        let answer = match env.args(1)?
        | "1" => solve_part_1(positions)?
        | "2" => solve_part_2(positions)
        end
        env.out.print(answer.string())
      end
    else
      env.err.print("hit an error")
    end
  
  fun read_positions(file: File): Array[U64]? =>
    let line = file.lines().next()?

    let positions = Array[U64]()
    for str in line.split_by(",").values() do
      positions.push(str.u64()?)
    end
    positions


  fun solve_part_1(positions: Array[U64]): U64? =>
    let sorted_positions = Sort[Array[U64], U64](positions)

    let middle = sorted_positions.size()/2
    let median = sorted_positions(middle)?

    var total_cost: U64 = 0
    for pos in sorted_positions.values() do
      total_cost = total_cost + absdist(pos, median)
    end
    total_cost
  
  fun solve_part_2(positions: Array[U64]): U64 =>
    var sum: U64 = 0
    for pos in positions.values() do
      sum = sum + pos
    end
    let mean = (sum.f64() / positions.size().f64())

    let cost_floor = move_cost_2(positions, mean.floor().u64())
    let cost_ceil = move_cost_2(positions, mean.ceil().u64())

    // return the smallest of found options
    cost_floor.min(cost_ceil)



  fun absdist(a: U64, b: U64): U64 =>
    // prevent overflow
    if a > b then
      a - b
    else
      b - a
    end
  
  fun move_cost_2(positions: Array[U64], pos: U64): U64 =>
    var total_cost: U64 = 0
    for pos' in positions.values() do
      let dist = absdist(pos, pos')
      let cost = (dist * (dist + 1)) / 2
      total_cost = total_cost + cost
    end
    total_cost