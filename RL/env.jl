function env_right_turn()
    array = readcsv(joinpath(dirname(@__FILE__), "files", "right_turn.csv"))
    colour_dict = readcsv(joinpath(dirname(@__FILE__), "files", "right_turn_colours.csv"))
    colour_dict = Dict{String, String}(zip(colour_dict[:,1], colour_dict[:,2]))
    colour_array = map(x -> colour_dict[x], array)
    m, n = size(array)
    states = [[i,j] for i in 1:m for j in 1:n]
    end_states = [x for x in states if array[x...] == "F"]
    function step(state, action)
        i, j = state # julia trick
        if (action == "up" && i > 1) i = i - 1 end
        if (action == "down" && i < m) i = i + 1 end
        if (action == "left" && j > 1) j = j - 1 end
        if (action == "right" && j < n) j = j + 1 end
        new_state = [i, j]
        reward = -1 # default
        if array[i, j] == "*" reward = -10 end
        if array[i, j] == "F" reward = 0 end
        return new_state, reward
    end
    actions(state) = ["up", "down", "left", "right"]
    task_end(state) = (state in end_states)
    right_turn = RLEnv(states, actions, step, task_end)
    return right_turn, colour_array
end

export env_right_turn
    
function env_circuit()
    array = readcsv(joinpath(dirname(@__FILE__), "files", "circuit.csv"))
    colour_dict = readcsv(joinpath(dirname(@__FILE__), "files", "circuit_colours.csv"))
    colour_dict = Dict{String, String}(zip(colour_dict[:,1], colour_dict[:,2]))
    colour_array = map(x -> colour_dict[x], array)
    m, n = size(array)
    states = [[i,j] for i in 1:m for j in 1:n]
    function step(state, action)
        i, j = state # julia trick
        x, y = i - m/2, j - n/2
        current_angle = angle(complex(x, y))
        if (action == "up" && i > 1) i = i - 1 end
        if (action == "down" && i < m) i = i + 1 end
        if (action == "left" && j > 1) j = j - 1 end
        if (action == "right" && j < n) j = j + 1 end
        new_state = [i, j]
        x, y = i - m/2, j - n/2
        new_angle = angle(complex(x, y))
        reward = new_angle - current_angle
        if i == 0 && j == 0 reward = -10 end
        if array[i, j] == "*" reward = -1 end
        return new_state, reward
    end
    actions(state) = ["up", "down", "left", "right"]
    task_end(state) = false
    circuit = RLEnv(states, actions, step, task_end)
    return  circuit, colour_array
end
   
export env_circuit

function get_env(env_id::String)
    if env_id == "circuit"
        return env_circuit()
    end
    if env_id == "right_turn"
        return env_right_turn()
    end
end

export get_env

