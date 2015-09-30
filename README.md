# DeadlySerious

[![Gem Version](https://badge.fury.io/rb/deadly_serious.png)](http://badge.fury.io/rb/deadly_serious)

Flow Based Programming Maestro!

This library is an implementation of the "Pipe and Filters" architecture style. It's intended for massive data processing.

It has some of the [Flow Based Programming](https://en.wikipedia.org/wiki/Flow-based_programming) features and benefits. Our intention is to add more and more FBP traits as time goes.

This relies on [*named pipes*](http://linux.die.net/man/7/fifo) and *Linux processes* to create a program. Each component runs as a separate linux process and they exchange information through pipes.

That means it uses 'mechanical sympathy' with the Operating System, i.e., the O.S. is *part* of the program, it's not something *under* it.

Unlike [NoFlo](http://noflojs.org), this is not a real engine. It "orchestrates" linux processes and pipes to create flow based systems.

**REQUIRES** Ruby 2.1 and a \*nix based Operating System. Tested on *Ubuntu* and *Arch Linux*.

## Why should I care?

This is a gem intended to process TONS of data in parallel, ocasionally distributed and with low memory footprint.

It's also being used in a real system: [Mapa VAGAS de Carreiras (portuguese only)](http://www.vagas.com.br/mapa-de-carreiras/)

## How it works

DeadlySerious spawns several processes connected through pipes. Each process should do a minor task, transforming or filtering data received from pipe and sending it to the next component.

A "component", in this context, can be:

- A class with a "#run(readers:, writers:)" method signature;
- A lambda (several options here)
- A shell command, like "sed", "awk", "sort", "join", etc...
- **Anything** that reads and writes to a file sequentially (and runs on a \*nix).

## Pros and Cons

Overall, it's slower than a normal ruby program (the serialization and deserialization pipes add some overhead). However, there are 4 points where this approach is pretty interesting:

1. High modifiabilty:
  * The interface between each component is tiny and very clear: it's just a stream of characteres. I usually use json format when I need more structure than that.
  * You can connect ruby process to anything that deals with STDIN, STDOUT or files (which includes shell commands, of course).
2. Cheap parallelism and distributed computation:
  * Each component runs as a separated process. The OS is in charge here (and it does an amazing work running things in parallel).
  * As any shell command can be used as a component, you can use a simple [ncat](http://nmap.org/ncat) (or something similar) to distribute jobs between different boxes.
  * It's really easy to avoid deadlocks and race conditions. Actually, they are only possible if you use it in a very unusual manner.
3. Low memory footprint
  * As each component usually process things as they appear in the pipe, it's easy to crush tons of data with very low memory. Notable exceptions as components that needs to accumulate things to process, like "sort".
4. Very easy to reason about (personal opinion):
  * Of course, this is not a merit of this gem, but of Flow Based Programming in general. I dare do say (oh, blasphemy!) that Object Oriented and Functional programming paradigms are good ONLY for tiny systems (a single component). They make a huge mess on big ones (#prontofalei).

## Installation

Add this line to your application's Gemfile:

    gem 'deadly_serious'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deadly_serious

## Usage

### Simple Usage

Create a simple script that defines and runs a pipeline:

```ruby
#!/usr/bin/env ruby
require 'deadly_serious'
include DeadlySerious::Engine

pipeline = Pipeline.new do |p|
  p.from_file('my_data_source.json')
  # The command "spawn_lambda" assumes a JSON format
  p.spawn_lambda { |a, b, writer:| writer << [b, a]}
  p.spawn_lambda { |b, a, writer:| writer << [b.upcase, a.downcase]}
  p.to_file('my_data_sink.json')
end

# This line will alow you to run
# it directly from the shell.
pipeline.run if __FILE__ == $0
```

You can spawn shell commands:

```ruby
#!/usr/bin/env ruby
require 'deadly_serious'
include DeadlySerious::Engine

pipeline = Pipeline.new do |p|
  p.from_file('my_data_source.txt')
  p.spawn_command('grep something')
  p.to_file('my_data_sink.txt')
end

pipeline.run if __FILE__ == $0
```

You can spawn your own components (classes):

```ruby
#!/usr/bin/env ruby
require 'deadly_serious'
include DeadlySerious::Engine

pipeline = Pipeline.new do |p|
  p.from_file('my_data_source.txt')
  p.spawn(MyComponent.new(some_option: 123))
  p.to_file('my_data_sink.txt')
end

pipeline.run if __FILE__ == $0
```

### Explained

The block in the pipeline creation **just define** the pipeline, it does no execute it.

When we call "pipeline.run", the block is executed creating _and_ starting each component.

Each component is connected to the next one (we can do define the connections by ourselves, explained later). Those connections are called "channels", they're usually pipes, but can be sockets or real files, depending on the use.

When a "spawn_something" command is called, the follow steps happens:

1. If the component needs a channel to write data, create or prepare the channel. If there is more than one channel, create or prepare them all.
2. Spawns a new process with the component passing handlers to the readers and writers channels (names usually).
3. In the subprocess, open all the channels.
4. Call the "run" method in the component passing the open channels
5. If the component terminates or raises error, close the channels 

The components are created and started in rapid succession. When the block ends, the pipeline pauses the main process untill all the children process finalize.

### Components

### Shell commands

Spawning shell commands are simples as that:

```ruby
pipeline = Pipeline.new do |p|
  p.from_file('x1.txt')
  p.spawn_command('cat ((<)) | grep wabba > ((>))')
  p.spawn_command('cat ((<)) > ((>))')
  p.to_file('x2.txt')
end
```

The "((<))" is replaced by the name of the input pipe (automatically generated), the "((>))" is replaced by the name of the output pipe.

You can omit both, if so, the commands use STDIN and STDOUT. The example above can be wrote as:

```ruby
pipeline = Pipeline.new do |p|
  p.from_file('x1.txt')
  p.spawn_command('cat | grep wabba')
  p.spawn_command('cat')
  p.to_file('x2.txt')
end
```

Warning: shell commands works only with pipes! They cannot be used directly with sockets, however, it's easy to bypass that using a simple component to convert sockets to pipes and vice-versa.

### Ruby components

Anything class with the method "runs(readers:, writers:)" can be used as a component.

### Lambda components

Yet to be explained.

### JSON integration

Yet to be explained.

### Pre-made components

  * Source components
  * Splitter
  * Joiner

Yet to be explained.

### Examples

Here a simple program to deal with the "Telegram Problem" as first described by Peter Naur.

> Write a program that takes a number **w**, then accepts lines of text and outputs lines of text, where the output lines have as many words as possible but are never longer than **w** characters. Words may not be split, but you may assume that no single word is too long for a line.

```ruby
require 'deadly_serious'

module TelegramProblem
  LINE_SIZE = 80
  PARAGRAPH_PACKET = 'CONTROL PACKET: paragraph'
  EOL_PACKET = 'CONTROL PACKET: end of line'

  # Break text in words and "END OF LINE" packets (EOL)
  class WordSplitter
    def run(readers: [], writers: [])
      reader = readers.first
      writer = writers.first

      reader.each do |line|
        line.chomp!
        line.scan(/$|\S+/) do |word|
          packet = (word == '' ? EOL_PACKET : word)
          writer << packet << "\n"
        end
      end
    end
  end

  # Transform double "end of line" in "paragraph"
  class EolToParagraph
    def run(readers: [], writers: [])
      reader = readers.first
      writer = writers.first

      last2 = ''
      last1 = ''
      reader.each do |packet|
        packet.chomp!

        if packet == EOL_PACKET
          last2 = last1
          last1 = packet
          next
        end

        if last1 == EOL_PACKET && last2 == EOL_PACKET
          writer << PARAGRAPH_PACKET << "\n"
        end

        writer << packet << "\n"
        last2 = last1
        last1 = packet
      end
    end
  end

  # Join words
  class SentenceJoiner
    def run(readers: [], writers: [])
      reader = readers.first
      writer = writers.first

      line_size = 0

      reader.each do |packet|
        packet.chomp!

        if packet == PARAGRAPH_PACKET
          writer << "\n\n"
          line_size = 0
          next
        end

        if line_size + packet.size + 1 <= LINE_SIZE
          writer << ' ' if line_size > 0
          writer << packet
          line_size += packet.size + 1
        else
          writer << "\n"
          writer << packet
          line_size = packet.size
        end
      end
      writer << "\n" unless line_size == 0
    end
  end

  class Pipeline < DeadlySerious::Engine::Spawner
    include DeadlySerious
    def run_pipeline
      spawn_process(WordSplitter, readers: ['>war_and_peace.txt'], writers: ['words_and_eol'])
      spawn_process(EolToParagraph, readers: ['words_and_eol'], writers: ['just_words'])
      spawn_process(SentenceJoiner, readers: ['just_words'], writers: ['>output.data'])
    end
  end
end

if __FILE__ == $0
  TelegramProblem::Pipeline.new.run
end
```

Check the "examples" directory for other examples of use. There's even a version of this Telegram Problem program made without pipes and such, but using the same logic. I made it to have a "feeling" of the overhead of using pipes.

In my findings, the overhead is roughly 100% in this very simple problem (same time, 2x cpu). Considering that each of the components above are *really* simple (just split, join words and an "if" and 2 pipes), I found the overhead not a great deal. However, I need more tests.

## Future features (a.k.a. "The Wishlist")

 * Socket connectors (pipe things through net)
 * Remote coordination (create and running remote components from a master box)
 * More pre-made components (using C?)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
