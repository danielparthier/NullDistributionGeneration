using Random, Test, Distributions

"""
    ShiftSimulationOld(N, x, y)

"Old" function for estimating the Null-distribution of events happening in a given time window (start to start+0.5s).
(Not recommended - use `ShiftSimulation`)

# Arguments
- `N::Int`: The number of simulations to run.
- `x::Vector{Float32}`: A vector of a timeseries.
- `y::Vector{Float32}`: A vector of starting times for the event window.

# Returns
- `SimCountOut::Vector{Float32}`: A vector of counts for each range in `y`, normalized by the length of `y`.
"""
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

"""
    ShiftSimulation(N, x, y)

Function for estimating the Null-distribution of events happening in a given time window (start to start+0.5s).

# Arguments
- `N::Int`: The number of simulations to run.
- `x::Vector{Float32}`: A vector of a timeseries.
- `y::Vector{Float32}`: A vector of starting times for the event window.

# Returns
- `SimCountOut::Vector{Float32}`: A vector of counts for each range in `y`, normalized by the length of `y`.
"""
function ShiftSimulation(N, x, y)
    SimCountOut = zeros(Float32, N)
    tmpVec = similar(x)
    MaxX = maximum(x)
    YLength = length(y) 
    RandVec = rand(N) .* MaxX
    for i=1:N
        @inbounds tmpVec .= x .+ RandVec[i]
        OverMax!(tmpVec, MaxX)
        @inbounds SimCountOut[i] += DetectCount(tmpVec,y)
    end
    return SimCountOut/YLength  
end

"""
    OverMax!(x, cutoff)

Helper function to subtract cutoff value by reference from x when x is larger the the cutoff.
"""
function OverMax!(x, cutoff)
    sort!(x)
    i=1
    N=length(x)
    while (i < N+1) && (x[i] <= cutoff) 
        i += 1    
    end
    if(i<=N)
        tmpX = @view x[i:N]
        tmpX .-= cutoff
        sort!(x)
    end
    return nothing
end

"""
    DetectCountOld(x, window)

Helper function to count events in a given window (start to start+0.5s). This function might count event twice if window overlaps.
"""
function DetectCountOld(x, window)
    CountOut = 0
    for j in window
        CountOut += count((x .>= j) .& (x .<= (j+0.5)))
    end
    return CountOut
end

"""
    DetectCount(x, window)

Helper function to count events in a given window (start to start+0.5s).
"""
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
