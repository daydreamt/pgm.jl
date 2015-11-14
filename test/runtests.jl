tests = ["factor_test", "pgm_test"]

examples = ["misconception"]

for t in tests
    fpath = "$t.jl"
    println("running $fpath ...")
    include(fpath)
end

for e in examples
    fpath = "../examples/$e.jl"
    println("running $fpath ...")
    include(fpath)
    println("Successfully ran $fpath")
end
