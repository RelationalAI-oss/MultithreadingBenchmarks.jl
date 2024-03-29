# MultithreadingBenchmarks

[![Build Status](https://travis-ci.com/RelationalAI-oss/MultithreadingBenchmarks.jl.svg?branch=master)](https://travis-ci.com/RelationalAI-oss/MultithreadingBenchmarks.jl)

## Results

The results from different experiments are written up as Issues in this package. The experiment writeups are all linked from the top-level experiment tracking issue, here:
- [MultithreadingBenchmarks.jl#1: \[Tracking Issue\] Julia Cooperative Multithreading Benchmarks](https://github.com/RelationalAI-oss/MultithreadingBenchmarks.jl/issues/1)


## Instructions for Running the Benchmark
The benchmark suite is set up to run via `Pkg.test()`:
```julia
(MultithreadingBenchmarks) pkg> test
```
The testfile simply invokes `test/runbench.jl` which can also be invoked manually.

### Configuration
However, currently, _which experiments are run_ is configured in `test/runbench.jl`, and is currently controlled by just commenting out the various experiments in that file (Sorry!). So just make sure when you run `test/runbench.jl` that the experiments are configured how you want them to be! :)

The test should automatically scale to the number of cores on your machine, though you may want to edit the `const NUM_DATAPOINTS = 9` to be smaller if you have fewer cores.

