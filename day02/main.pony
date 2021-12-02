use "files"

actor Main
  new create(env: Env) =>
    try
      match env.args(1)?
      | "1" => Part1(env)
      | "2" => Part2(env)
      end
    end


actor Part1
  new create(env: Env) =>
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(2)?)) as File
      do
        var lines = file.lines()

        var depth: U64 = 0
        var pos: U64 = 0

        for line in file.lines() do
          let parts = line.split_by(" ")
  
          match parts(0)?
          | "forward" =>
              pos = pos + parts(1)?.u64()?
          | "up" =>
              depth = depth - parts(1)?.u64()?
          | "down" =>
              depth = depth + parts(1)?.u64()?
          end
        end

        env.out.print((depth * pos).string())
      end
    end


actor Part2
  new create(env: Env) =>
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(2)?)) as File
      do
        var lines = file.lines()

        var depth: U64 = 0
        var pos: U64 = 0
        var aim: U64 = 0

        for line in file.lines() do
          let parts = line.split_by(" ")
          var amount = parts(1)?.u64()?
  
          match parts(0)?
          | "forward" =>
              pos = pos + amount
              depth = depth + (aim * amount)
          | "up" =>
              aim = aim - amount
          | "down" =>
              aim = aim + amount
          end
        end

        env.out.print((depth * pos).string())
      end
    end
