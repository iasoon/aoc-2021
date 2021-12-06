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
    let line: String = file.lines().next()?

    // start with an empty state vector
    let state = Array[U64].init(0, 9)

    for str in line.split_by(",").values() do
      let num: USize = str.usize()?
      state(num)? = state(num)? + 1
    end

    for day_num in Range[U64](0, num_days) do
      let reproducing = state(0)?
      for i in Range(0, 8) do
        state(i)? = state(i+1)?
      end
      state(8)? = reproducing
      state(6)? = state(6)? + reproducing
    end

    var num_fishes: U64 = 0
    for count in state.values() do
      num_fishes = num_fishes + count
    end

    num_fishes