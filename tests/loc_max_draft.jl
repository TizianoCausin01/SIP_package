##
using Combinatorics

##
V = 2
max_freq = 10^2
myDict = Dict{BitVector, Int}()
for i = 0:2^V
    st_vec = BitVector(undef,2^V)
    if i == 0
        fill!(st_vec,0)
        myDict[st_vec] = rand(1:max_freq)

    elseif i == 2^V
        fill!(st_vec,1)
        myDict[st_vec] = rand(1:max_freq)
    else
        st_vec[1:i] .= 1
        st_vec[i+1:2^V] .= 0
        combin = Combinatorics.permutations(st_vec)
        for ii in combin
            myDict[BitVector(ii)] = rand(1:max_freq)
        end
        combin = nothing
    end
end
##
function del_wins(myDict, win)
    for position = 1 : length(win) # changes one element at the time
       win = flip_element(win, position) # flips the window
       if haskey(myDict, win)
           delete!(myDict, win) # if it's still there, deletes the elements with lower probability 
       end
       win = flip_element(win, position) # returns the initial win (it was less expensive than copying the key)
    end 
end

function flip_element(win, position)
    if win[position] == 1
        win[position] = 0
    elseif win[position] == 0
        win[position] = 1
    end
    return win
end


## find max e store it
myDict[[1,1,1,1]]= 10000
myDict[[0,0,0,0]] = 12000
##
loc_max = Array{Vector{Bool}}(undef, 0)

while ~isempty(myDict)
    freq, key = findmax(myDict)
    push!(loc_max, collect(key))
    delete!(myDict, key)
    del_wins(myDict, key)
end
##

## eliminate max and all other 'close' win 

## reiterate + ground case