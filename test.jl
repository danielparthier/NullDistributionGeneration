using Distributions, Plots, Random, Statistics
using BenchmarkTools, Test
function CreateLicks()
    cumsum(shuffle([rand(Gamma(280, 1/20), 40); rand(Gamma(2, 1/7), 120)]))
end

function CreatePictures()
    cumsum(shuffle(rand(Gamma(30, 1/2), 40)))
end

Simulations = 10000

Licks = CreateLicks()
PictureSlot = CreatePictures()


# Speed comparison shows strong advantage for ShiftSimulation
Random.seed!(1)
@benchmark ShiftSimulation(10000, $Licks, $PictureSlot) seconds=10
Random.seed!(1)
@benchmark ShiftSimulationOld(10000, $Licks, $PictureSlot) seconds=10

Random.seed!(1)
histogram(ShiftSimulation(Simulations, Licks, PictureSlot))
Random.seed!(1)
histogram(ShiftSimulationOld(Simulations, Licks, PictureSlot))


#= short test of functions
ShiftSimulationOld will count double if windows overlap!
This will be fine most of the time when using natural data.
ShiftSimulation is recommended though because of accuracy and speed=#
TestX = [1.0, 5,10,25,30,40,50,60]
TestY = [1.0,5,10,25,30,40,50,60]
Random.seed!(1)
Out = ShiftSimulation(Simulations, TestX, TestY)
Random.seed!(1)
OutOld = ShiftSimulationOld(Simulations, TestX, TestY)
Test.@test mean(Out) == mean(OutOld)

# Structure for test output
mutable struct TestOutput{Float64}
    Output1::Array{Float64}
    Output2::Array{Float64}
    Timing1::Array{Float64}
    Timing2::Array{Float64}
    Simulations::Int64
end

# Compare output of the two functions
function testRuns(Licks, PictureSlot, N::Int64)
    test1 = zeros(Float32, N)
    test2 = zeros(Float32, N)
    time1 = zeros(Float32, N)
    time2 = zeros(Float32, N)
    for i in 1:N
        Random.seed!(i)
        tmp = @timed mean(ShiftSimulation(10000, Licks, PictureSlot))
        test1[i] += tmp[1]
        time1[i] += tmp[2]
        Random.seed!(i)
        tmp = @timed mean(ShiftSimulationOld(10000, Licks, PictureSlot))
        test2[i] += tmp[1]
        time2[i] += tmp[2]
    end
    return TestOutput(test1, test2, time1*1000, time2*1000, N)
end

testThat = testRuns(Licks, PictureSlot, 1000);

begin
    println("Values")
    println("New - median: ", median(testThat.Output1), " ⨦ ", median(abs.(testThat.Output1 .- median(testThat.Output1))))
    println("Old - median: ", median(testThat.Output2), " ⨦ ", median(abs.(testThat.Output2 .- median(testThat.Output2))))
    println("New - mean: ", mean(testThat.Output1), " ⨦ ",std(testThat.Output1))
    println("Old - mean: ", mean(testThat.Output2), " ⨦ ", std(testThat.Output2))
end

begin
    println("Time (ms)")
    println("New - median: ", median(testThat.Timing1), " ⨦ ", median(abs.(testThat.Timing1 .- median(testThat.Timing1))))
    println("Old - median: ", median(testThat.Timing2), " ⨦ ", median(abs.(testThat.Timing2 .- median(testThat.Timing2))))
    println("New - mean: ", mean(testThat.Timing1), " ⨦ ",std(testThat.Timing1))
    println("Old - mean: ", mean(testThat.Timing2), " ⨦ ", std(testThat.Timing2))
end

# plot values and time of function
plot(histogram(testThat.Output1, bins=range(0.1,0.15,100)), histogram(testThat.Output2, bins=range(0.1,0.15,100)))
begin
    histogram(testThat.Timing1, bins=range(0,100,100),label="ShiftStimulation", lw=0.1)
    histogram!(testThat.Timing2, bins=range(0,500,100), label="ShiftStimulationOld",lw=0.1)
    xlabel!("Time (ms)")
    title!("Benchmark Timings")
end

# Output is identical
Test.@test testThat.Output1 == testThat.Output2

length(unique(testThat.Output1))
length(unique(testThat.Output2))
