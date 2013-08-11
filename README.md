# DeadlySerious

Flow Based Programming Maestro!

This relies on [*named pipes*](http://linux.die.net/man/7/fifo) and *Linux processes* to create a program. Each component runs as a separate linux process and they exchange information through pipes.

**REQUIRES** Ruby 2.0 and a \*nix based OS (Operating System, tested on *Ubuntu* and *Arch Linux*)

Unlike [NoFlo](http://noflojs.org), this is not a real engine. It just "orchestrates" linux processes and pipes to create a flow based system.

Overall, it's slower than a normal ruby program (the pipes add some overhead). However, there are 3 points where this approach is pretty interesting:

1. Unbelievably modifiable:
  * The interfaces between each component is tiny and very clear: they are just streams of characteres. I usually use csv format or json when I need more structure than that.
  * You can connect ruby process to anything else that deals with STDIN, STDOUT or files (which includes shell commands, of course).
2. Cheap parallelism and distributed computation:
  * Each component runs as a separated process. The OS is in charge here (and it does a amazing work running things in parallel).
  * As any shell command can be use as a component, you can use a simple [ncat](http://nmap.org/ncat) (or something similar) to disttribute jobs between different boxes.
  * It's really easy to avoid deadlocks and race conditions with the FBP paradigm.
3. Very easy to reason about:
  * Of course, this is not a merit of this gem, but of Flow Based Programming in general. I dare do say (oh, blasphemy!) that Object Oriented and Functional programming paradigms are good ONLY for tiny systems. They make a huge mess on big ones (#prontofalei).

## Installation

Add this line to your application's Gemfile:

    gem 'deadly_serious'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deadly_serious

## Usage

### Basic pipeline

Create a class that will orchestrate the pipeline:

```ruby
#!/usr/bin/env ruby
# &uarr; Assuming your are using RVM

class Pipeline < DeadlySerious::Engine::Spawner
  def run_pipeline
    # Here comes the code
  end
end

# This line will alow you to run
# it directly from the shell
Pipeline.new.run if __FILE__ == $0
```

You can spawn process the following way:

```ruby
class Pipeline < DeadlySerious::Engine::Spawner
  def run_pipeline

    spawn_process(YourComponentClass,
      readers: ['>an_awesome_text_file.txt'], # reads from a file
      writers: ['your_first_output_pipe'])    # outputs to a pipe

    spawn_process(YourOtherComponentClass,
      readers: ['your_first_output_pipe'],
      writers: ['more_pipe1', 'more_pipe2'])

  end
end
```

A component is any class with a "run" method and two named parameters "readers" and "writers":

```ruby
class EchoComponent
  # "readers" and "writers" are both Array of IO objects.
  def run(readers: [], writers: [])
    reader = readers.first
    writer = writers.first

    reader.each_line do |line|
      writer << line
    end
  end
end
```

### Pipes and files

The parameters you receive in the "def run(readers: [], writers: [])" method are [**IO**](http://www.ruby-doc.org/core-2.0/IO.html) objects.

They are already opened when they are passed to your component, and they are properly closed when your component is done.

In the Pipeline class, readers and writers are just pipe names *or* file names. If you want to read or write to a file instead of a pipe, prepend its name with ">", like that:

```ruby
spawn_process(YourComponentClass,
  readers: ['>an_awesome_text_file.txt'], # reads from a file
  writers: ['your_first_output_pipe'])    # outputs to a pipe

spawn_process(YourComponentClass,
  readers: ['an_awesome_pipe'],            # reads from a pipe
  writers: ['>your_first_output_file'])    # outputs to a file
```

Files are read and created in the "./data" directory, "." being the directory where you fired the program.

Pipes are created in the '/tmp/deadly_serious/&lt;pid&gt;/' directory and they live just during the program execution. Once it's done, the directory is deleted.

### Shell commands

Spawning shell commands are simples as that:

```ruby
spawn_command('cat ((>a_file_in_data_dir.csv)) | grep wabba > ((some_pipe))')
spawn_command('cat ((some_pipe)) > ((>my_own_output_file.txt))')
```

The "((" and "))" are replaced by the actual pipe (or file) path before execution.

### Preserve pipe directory and change data directory

In the Pipeline class (the one you extended from Engine::Spawner), you can override the "initialize" method to pass some parameters:

```ruby
class Pipeline < DeadlySerious::Engine::Spawner
  def initialize
    super(
      data_dir: './data',                             # Files directory
      pipe_dir: "/tmp/deadly_serious/#{Process.pid}", # Pipes directory
      preserve_pipe_dir: false)                       # Keeps the pipes directory after finish execution?
  end
end
```

You can overwrite any of them. The ones presented above are default.

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

Check the "examples" directory for other examples of use. There's even a version of this Telegram Problem program that's done without pipes and such, but using the same logic. I made it to have a "feeling" of the overhead of using pipes.

In my findings, the overhead is roughly 50% in this very simple problem (same time, 2x cpu). Considering that each of the components above are *really* simple (just split, join words and an "if"), I found the overhead is incredible low. However, I need to more tests.

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
