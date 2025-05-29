# frozen_string_literal: true

# Problem:
#
# > fn = proc { |first| puts first  }
# > fn.call(:first, :second, :third)
# first
#
# :second and :third was ignored. It's ok.
#
# > fn = proc { puts "test"  }
# > fn.call(first: :first, second: :second, third: :third)
# test
#
# And it's ok.
#
# > fn = proc { |&block| block.call }
# > fn.call(first: :first, second: :second, third: :third) { puts "test" }
# test
#
# And this is ok too.
#
# > fn = proc { |first:| puts first  }
# > fn.call(first: :first, second: :second, third: :third)
# ArgumentError (unknown keywords: :second, :third)
#
# ¯\_(ツ)_/¯
#
# ❤ Ruby ❤
#
# Next code solve this problem for procs without word arguments,
# only keywords and block.

module TableSync::Utils
  module_function

  def proc_keywords_resolver(&proc_for_wrap)
    available_keywords = proc_for_wrap.parameters
      .select { |type, _name| type == :keyreq }
      .map { |_type, name| name }

    proc do |keywords = {}, &block|
      proc_for_wrap.call(**keywords.slice(*available_keywords), &block)
    end
  end
end
