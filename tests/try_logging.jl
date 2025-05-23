macro show_locals()
	return Expr(:locals)
end
function test_varinfo()
	x = rand(1000)
	y = rand(1000)
	# Use the `@show` macro or manually print their memory usage
	for loc in Expr(:locals)
		print(loc)
	end
end
test_varinfo()
##
macro inspect_locals()
	quote
		local_vars = Dict()
		print(Base.@locals)
		for (var, val) in Base.@locals
			try
				local_vars[var] = (val, Base.summarysize(val))
			catch
				local_vars[var] = (val, "size unknown")
			end
		end
		local_vars
	end
end

function test()
	x = [1, 2, 3]
	y = "hello"
	z = Dict(1 => "a", 2 => "b")
	tot_info = []
	for (key, val) in Base.@locals
		push!(tot_info, "$(key): \n size: $(Base.summarysize(val))")
	end

	# locals_info = @inspect_locals()
	# for (var, (val, size)) in locals_info
	#     println("$var: $val ($(size) bytes)")
	# end
end
##
for i in 1
	b = 3
	for (key, val) in Base.@locals
		@info "$(key): \n size: $(Base.summarysize(val))"
	end
end
