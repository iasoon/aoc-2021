use "files"


actor Main
  new create(env: Env) =>
    Part2(env)


actor Part1
  new create(env: Env) =>
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, "input.txt")) as File
      do
        var lines = file.lines()

        var counter: U64 = 0
        var prev = lines.next()?.u64()?

        for line in file.lines() do
          var cur = line.u64()?
          if cur > prev then
            counter = counter + 1
          end
          prev = cur
        end

        env.out.print(counter.string())
      end
    end


actor Part2
  new create(env: Env) =>
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, "input.txt")) as File
      do
        var lines = file.lines()
        var counter: U64 = 0
        var measurements = Array[U64](4)


        for line in file.lines() do
          var next_value = line.u64()?
          measurements.push(next_value)
          if measurements.size() > 3 then
            let shifted_value = measurements.shift()?
            if next_value > shifted_value then
              counter = counter + 1
            end
          end
        end

        env.out.print(counter.string())
      end
    end
