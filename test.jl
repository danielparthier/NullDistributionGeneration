using Distributions, Plots, Random, Statistics
using BenchmarkTools
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


# Compare output of the two functions
function testRuns(Licks, PictureSlot)
    test1 = zeros(Float32, 1000)
    test2 = zeros(Float32, 1000)
    for i in 1:1000
        Random.seed!(i)
        test1[i] = mean(ShiftSimulation(1000, Licks, PictureSlot))
        Random.seed!(i)
        test2[i] = mean(ShiftSimulationOld(1000, Licks, PictureSlot))
    end
    return test1, test2
end

testThat = testRuns(Licks, PictureSlot)

println("Test1 - median: ", median(testThat[1]), " ⨦ ", median(abs.(testThat[1] .- median(testThat[1]))))
println("Test2 - median: ", median(testThat[2]), " ⨦ ", median(abs.(testThat[2] .- median(testThat[2]))))
println("Test1 - mean: ", mean(testThat[1]), " ⨦ ",std(testThat[1]))
println("Test2 - mean: ", mean(testThat[2]), " ⨦ ", std(testThat[2]))
histogram(testThat[1], bins=range(0.1,0.2,100))
histogram(testThat[2], bins=range(0.1,0.2,100))

length(unique(testThat[1]))
length(unique(testThat[2]))
