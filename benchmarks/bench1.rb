require 'benchmark'


array = (1..1000000).map { rand }

Benchmark.bmbm do |x|
  x.report("rindex") { array.rindex(array.min) }
  x.report("each_with_index")  { array.each_with_index.min  }
end