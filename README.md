iSwift lets you use Swift, and Swift for TensorFlow, in Jupyter notebooks.

## Quick Start

The easiest way of using this is via the [docker image](https://hub.docker.com/r/algalgal/swift-notebook/).

```bash
$ docker run -t -i -p 8888:8888 --privileged algalgal/swift-tensorflow-notebook
```

Open the URL you see in the console to reach Jupyter. From there you
can select `New` -> `Swift` or `New` -> `Swift for TensorFlow`.



## Capabilities

iSwift can:

  + Execute swift code on the Jupyter Notebook web editor, Jupyter console as well as Jupyter qtconsole.
  + Import Foundatation/Dispatch and other built-in libraries.
  + Autocomplete swift code by pressing tab ↹.
  + Support encryption.
  + Support Linux/macOS
  
This project is derived from [KelvinJin/iSwift](https://github.com/KelvinJin/iSwift), and its various forks, and some new work. Notable changes are:

  + Update to use Swift 4.1 itself
  + Updated to provide a Swift 4.1 kernel, for use in Jupyter
  + Also updated to provide a Swift for TensorFlow kernel, for use in Jupyter (in the docker image)
  + In the docker image, provides plain old tensorflow, by basing off the standard [Jupyter tensorflow-notebook](https://github.com/jupyter/docker-stacks/tree/master/tensorflow-notebook).
  + Mechanism to allow adding new Swift versions, just by writing new JSON kernelspecs.


### Multiple kernels for multiple Swifts

This is a quick note on how this fork supports multiple Swift versions.

First, the iSwift package does not itself provide the Swift REPL which
it feeds to Jupyter. iSwift essentially acts as an _adapter_ between
Jupyter and another executable which does provide that REPL. That
other executable is the `swift` interpreter. (In other words, it seems
to be merely a coincidence that iSwift is itself written in Swift.)

In general, you install a new language in Jupyter with a `kernel.json`
file, which specifies the command needed to launch the process which
talks to Jupyter. To use iSwift, you configure your `kernel.json` to
point to the iSwift executable.

The original iSwift was hardcoded to always adapt the standard `swift`
repl and forward its in/out to Jupyter. This version is a little
different, in that it looks for additional command line arguments and
uses those to determine which REPL to launch -- that is, which REPL
iSwift itself will adapt Jupyter _to_.

This allows you to provide multiple Swifts just by defining multiple
`kernel.json` files.

## Requirements

  + macOS/Linux
  + Swift 4.1
  + ZMQ
  + Jupyter 5.0

## macOS Installation

Clone this repo locally. And:

1. Follow [this](https://github.com/Zewo/ZeroMQ/blob/master/setup_env.sh) script to install the libzmq on your machine.

2. Build the project.

```
swift build
```

3. Currently, in order to run swift kernel locally, you need to create a file named
`kernel.json`. Put the following content to the file and replace the `Path/to/iSwift`
with your local clone path.

```json
{
 "argv": ["Path/to/iSwift/.build/debug/iSwift", "-f", "{connection_file}"],
 "display_name": "Swift",
 "language": "swift"
}
```

4. Install Jupyter kernel: (replace the `Folder/that/has/kernel/json` with
  the path of the folder that contains the `kernel.json` file)

```
jupyter-kernelspec install Folder/that/has/kernel.json
```

5. Run Jupyter Notebook (token needs to be empty):
```
jupyter notebook --NotebookApp.token=
```

## Linux Installation

1. Install Swift 3.0.
2. Check if you have libzmq installed.
3. Continue from step 2 in the section above.

## Docker Installation

Simply clone this repo and run `docker build -t iswift .`. It will build the docker image.

## Authors and Sources

- [Jin Wang](https://twitter.com/jinw1990), Original iSwift project (the hard part): 
- [Alexis Gallagher](https://twitter.com/alexisgallagher), Hacks to support Swift 4.1 and Swift for TensorFlow in Docker: 
- https://github.com/rayh/iSwift
- https://github.com/pvieito/iSwift


## Contribution

Contributions are welcome. Simply create an issue if you have ideas on how we
can improve iSwift.

## License
MIT
