using Random, Test
using Distributions

function ShiftSimulationOld(N, x, y)
    SimCountOut = zeros(Float32, N)
    tmpVec = similar(x)
    MaxX = maximum(x)
    YLength = length(y) 
    RandVec = rand(N) .* MaxX
    for i=1:N
        tmpVec .= x .+ RandVec[i]
        tmpVec[findall(tmpVec .> MaxX)] .-= MaxX
        for j in y
            SimCountOut[i] += count((tmpVec .>= j) .& (tmpVec .<= j+0.5))
        end
    end
    return SimCountOut/YLength  
end

function ShiftSimulation(N, x, y)
    SimCountOut = zeros(Float32, N)
    tmpVec = similar(x)
    MaxX = maximum(x)
    YLength = length(y) 
    RandVec = rand(N) .* MaxX
    for i=1:N
        tmpVec .= x .+ RandVec[i]
        tmpVec[findall(tmpVec .> MaxX)] .-= MaxX
        sort!(tmpVec)
        SimCountOut[i] += DetectCount(tmpVec,y)
    end
    return SimCountOut/YLength  
end


# this function has the problem to count values twice if overlap of windows exists
function DetectCountOld(x, window)
    CountOut = 0
    for j in window
        CountOut += count((x .>= j) .& (x .<= (j+0.5)))
    end
    return CountOut
end


# fast minimalistic function to count occurence in window
function DetectCount(x, window)
    Nx = length(x)
    Nwindow = length(window)
    CountOut = 0
    j = 1
    i = 1
    while (j < Nx+1) & (i < Nwindow+1)
            if ((x[j] >= window[i]) & (x[j] <= (window[i]+0.5)))
                CountOut += 1
                j += 1
            elseif x[j] < window[i]
                j += 1
            else
                i += 1
            end
        end
    return CountOut
end


# test fast function
xtest = [0,0.1,0.11,0.12,0.4,0.41,0.42,0.7,0.71,0.72, 1.1, 1.2]
ytest = [0.1,0.6, 1.1]

Test.@test DetectCount(xtest, ytest) == 11
Test.@test DetectCount(0, 0) == 1
