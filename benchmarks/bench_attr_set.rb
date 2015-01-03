require 'benchmark'

class A

  attr_accessor :b

  def initialize
    @a = rand(100)
    @b = rand(100)
    @c = rand(100)
  end

  def test_1
    100_000.times do |i|
      @a = rand(1000)
    end
  end

  def test_2
    100_000.times do |i|
      b = rand(1000)
    end
  end

  def test_3
    100_000.times do |i|

      instance_variable_set("@b", rand(1000))
    end
  end

  def test_4
    100_000.times do |i|

      send("b=", rand(1000))
    end
  end

end

a_class = A.new

Benchmark.bmbm do |x|
  x.report('@') { a_class.test_1 }
  x.report('accessor')  { a_class.test_2  }
  x.report('instance')  { a_class.test_3  }
  x.report('send')  { a_class.test_4  }
end

