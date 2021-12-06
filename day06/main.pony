use "files"
use "collections"

actor Main
  new create(env: Env) =>
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(2)?)) as File
      do
        let answer = match env.args(1)?
        | "1" => solve(file, 80)?
        | "2" => solve(file, 256)?
        end
        env.out.print(answer.string())
      end
    else
      env.err.print("hit an error")
    end

  fun solve(file: File, num_days: U64): U64? =>
    // how many periods it takes to reproduce
    let cycle_length: USize = 7
    // how many periods before a fish is an adult
    let growth_duration: USize = 2


    let line: String = file.lines().next()?

    // start with an empty state vector
    let adults = Array[U64].init(0, cycle_length)

    for str in line.split_by(",").values() do
      let num: USize = str.usize()?
      adults(num)? = adults(num)? + 1
    end

    let children = Array[U64].init(0, growth_duration)

    for day_num in Range(0, num_days.usize()) do
      let adult_pos = day_num % cycle_length
      let child_pos = day_num % growth_duration

      let new_adults = children(child_pos)?

      let adults_reproducing = adults(adult_pos)?
      adults(adult_pos)? = adults_reproducing + new_adults
      children(child_pos)? = adults_reproducing
    end

    // count fishes
    var num_fishes: U64 = 0

    for count in adults.values() do
      num_fishes = num_fishes + count
    end
  
    for count in children.values() do
      num_fishes = num_fishes + count
    end

    num_fishes