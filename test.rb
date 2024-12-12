$vars = {}
def true?(x) = ![0, nil, false, "", []].include?(x)
def run!(exe=true)
  @stream.slice! /\A(\s+|\#.*)+/
  @stream.slice! /\A\d+/ and return $&.to_i
  @stream.slice! /\A[a-z_][a-z_0-9]*/ and return $vars.fetch $&
  @stream.slice! /\A(?:'([^']*)'|"([^"]*)")/ and return $+
  @stream.slice! /\A(?:([TF])|N)[A-Z_]*/ and return $1&.then { _1 == 'T' }
  @stream.slice!(/\A@/) and return []

  case c=@stream.slice!(/\A([A-Z_]+|.)/)[0]
  when 'D' then p run!
  when 'W'
    tmp = @stream.dup
    while true? run!
      run!
      @stream = tmp.dup
    end
    run! false
  when ';' then run!; run!
  else
    fail "bad token start: #{c.inspect}"
  end

    # f = FNS[@src.slice!(/\A([A-Z_]+|.)/)] or abort "unknown token start: #{$&[0].inspect}"
    # Fn.new f, f.arity.times.map { parse! }
end

@stream = '; W 0 D 2 D 3'
run!
