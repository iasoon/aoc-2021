use "files"

actor Main
  new create(env: Env) =>
    try
      let sub = match env.args(1)?
      | "1" => Driver(env, Submarine1)
      | "2" => Driver(env, Submarine2)
      end
    end


actor Driver
  new create(env: Env, sub: Submarine tag) =>
    try
      with file = OpenFile(
        FilePath(env.root as AmbientAuth, env.args(2)?)) as File
      do
        var lines = file.lines()

        for line in file.lines() do
          let parts = line.split_by(" ")
          sub.handle_command(parts(0)?, parts(1)?.u64()?)
        end

        sub.print_output(env)
      end
    end


interface Submarine
  be handle_command(command: String, amount: U64)
  be print_output(env: Env)


actor Submarine1
  var horizontal_position: U64 = 0
  var depth: U64 = 0

  be handle_command(command: String, amount: U64) =>
    match command
    | "forward" =>
        horizontal_position = horizontal_position + amount
    | "up" =>
        depth = depth - amount
    | "down" =>
        depth = depth + amount
    end
  
  be print_output(env: Env) =>
    let result = horizontal_position * depth
    env.out.print((result).string())


actor Submarine2
  var horizontal_position: U64 = 0
  var depth: U64 = 0
  var aim: U64 = 0

  be handle_command(command: String, amount: U64) =>
    match command
    | "forward" =>
        horizontal_position = horizontal_position + amount
        depth = depth + (aim * amount)
    | "up" =>
        aim = aim - amount
    | "down" =>
        aim = aim + amount
    end
  
  be print_output(env: Env) =>
    let result = horizontal_position * depth
    env.out.print((result).string())

