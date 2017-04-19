function right_turn_env()
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
    
type circuit <: AbstractRLEnv
    states
    actions
    step
    task_end
    begin_states
    array
end

function circuit_env()
    array = readcsv(joinpath(dirname(@__FILE__), "files", "circuit.csv"))
    colour_dict = readcsv(joinpath(dirname(@__FILE__), "files", "circuit_colours.csv"))
    colour_dict = Dict{String, String}(zip(colour_dict[:,1], colour_dict[:,2]))
    colour_array = map(x -> colour_dict[x], array)
    m, n = size(array)
    states = [[i,j] for i in 1:m for j in 1:n]
    begin_states = [x for x in states if array[x...] == "F"]
    end_states = begin_states
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
        if i == 0 && j == 0 reward += -10 end
        if array[i, j] == "*" reward += -1 end
        return new_state, reward
    end
    actions(state) = ["up", "down", "left", "right"]
    task_end(state) = (state in end_states)
    return circuit(states, actions, step, task_end, begin_states, array)
end
export circuit_env

function render(c::circuit, start_pos, height = 400, width = 400)
    h, w = size(c.array)
    canvas_id = "circuit" * randstring(3)
    create_canvas(canvas_id, h, w, height, width)
    p = [[i, j] for i in 1:h for j in 1:w]
    colour_map = Dict("" => "brown", "*" => "green", "F" => "red")
    colour_array = [colour_map[x] for x in c.array]
    add_pixels(canvas_id, colour_array)
    # root = joinpath(dirname(@__FILE__), "files", "Images")
    root = joinpath("RL", "files", "Images")
    racer_id = canvas_id * "racer"
    add_pixel_image(racer_id, canvas_id, start_pos..., "$root/car.png")
    return canvas_id
end

function animate(c::circuit, canvas_id::String, states; speed = 0.1, max_time = 60)
    h, w = size(c.array)
    n = size(states, 1)
    elapsed = 0.
    racer_id = canvas_id * "racer"
    i = 1
    root = joinpath("RL", "files", "Images")
    while i <= n && elapsed < max_time 
        tic()
        translate_element(racer_id, states[i]...)
        sleep(speed)
        elapsed += toq()
        i += 1
    end
end

function greedy_arrow_plot(c::circuit, greedy)
    # assuming greedy is a set of greedy actions
    rotation = Dict("up" => 90, "down" => 270, "right" => 0, "left" => 180)
    s *= ""
    for s in c.states 
        for a in greedy[s]
            s *= add_pixel_arrow("""arrow$(join(s,"_"))""", rtcanvas, s..., rotation[a], disp = false) 
        end 
    end
    jsdisp(s)
end
export greedy_arrow_plot

type grid_adventure <: AbstractRLEnv
    states
    actions
    step
    task_end
    begin_states
    exits
    blocks
    coins
    bombs
    array
end

function expand_grid(set::Array, k::Int) 
    if k <= 0 error("k must be greater than zero") end
    return (k == 1) ? set : [[s; x] for s in set for x in expand_grid(set, k - 1)]
end

function rand_grid_adventure(height::Int, width::Int; nexits = 1, nblocks = 0, ncoins = 0, nbombs = 0)
    nexits < 1 && error("there must be at least one exit") 
    h, w = height, width
    array = [[i,j] for i in 1:h, j in 1:w]
    grid = [x for x in array]
    tot = nexits + nblocks + ncoins + nbombs
    idx = randperm(h * w)[1:tot]
    exits = grid[idx[1:nexits]]
    blocks = nblocks > 0 ? grid[idx[(nexits + 1):(nexits + nblocks)]] : []
    coins = ncoins > 0 ? grid[idx[(nexits + nblocks + 1):(nexits + nblocks + ncoins)]] : []
    bombs = nbombs > 0 ? grid[idx[((nexits + nblocks + ncoins + 1):tot)]] : []
    begin_states = [[[1,1], [1 for x in coins], [1 for x in bombs]]]
    active_coins_states = (ncoins <= 0) ? [] : expand_grid([1, 0], ncoins)
    active_bombs_states = (nbombs <= 0) ? [] : expand_grid([1, 0], nbombs)
    states = [[x, ((size(y,1)>1)?y:[y]), ((size(z,1)>1)?z:[z])] for x in grid for y in active_coins_states for z in active_bombs_states]
    actions(s) = ["up", "left", "right", "down"]
    task_end(s) = s[1] in exits
    function step(state, action)
        i, j = state[1] 
        active_coins = coins[find(state[2])]
        active_bombs = bombs[find(state[3])]
        if (action == "up" && i > 1 && [i - 1, j] ∉ blocks) i = i - 1 end
        if (action == "down" && i < h && [i + 1, j] ∉ blocks) i = i + 1 end
        if (action == "left" && j > 1 && [i, j - 1] ∉ blocks) j = j - 1 end
        if (action == "right" && j < w && [i, j + 1] ∉ blocks) j = j + 1 end
        new_state = deepcopy(state)
        new_state[1] = [i, j]
        reward = -1 # default
        if ([i, j] ∈ active_coins) 
            reward = 50 
            coinidx = find([x == [i,j] for x in coins])
            new_state[2][coinidx] = 0
        end
        if ([i, j] ∈ active_bombs) 
            reward = -100 
            bombidx = find([x == [i,j] for x in bombs])
            new_state[3][bombidx] = 0
        end
        if ([i, j] ∈ exits) 
            reward = 0 
        end
        return new_state, reward
    end
    return grid_adventure(states, actions, step, task_end, begin_states, exits, blocks, coins, bombs, array)
end
export rand_grid_adventure
    
function render(g::grid_adventure, start_pos, height = 400, width = 400)
    h, w = size(g.array)
    canvas_id = "grid_adventure" * randstring(3)
    create_canvas(canvas_id, h, w, height, width)
    attr = Dict("width" => 1, "height" => 1)
    style = Dict("fill" => "white", "stroke-width" => 0.1, "stroke" => "black")
    p = [[i, j] for i in 1:h for j in 1:w]
    s = add_pixels(canvas_id, p, attr = attr, style = style, disp = false)
    # root = joinpath(dirname(@__FILE__), "files", "Images")
    root = joinpath("RL", "files", "Images")
    for pos in g.exits
        s*= add_pixel_image("""exit$(join(pos, "_"))""", canvas_id, pos..., "$root/exit.png", disp = false) 
    end
    for pos in g.bombs 
        s*= add_pixel_image("""bomb$(join(pos, "_"))""", canvas_id, pos..., "$root/bomb.png", disp = false) 
    end
    for pos in g.coins 
        s*= add_pixel_image("""coin$(join(pos, "_"))""", canvas_id, pos..., "$root/coin.png", disp = false) 
    end
    for pos in g.blocks 
        s*= add_pixel_image("""block$(join(pos, "_"))""", canvas_id, pos..., "$root/wall.png", disp = false) 
    end
    jsdisp(s)
    racer_id = canvas_id * "racer"
    add_pixel_cross(racer_id, canvas_id, start_pos..., "blue")
    return canvas_id
end


function animate(g::grid_adventure, canvas_id::String, states; speed = 0.1, max_time = 60)
    h, w = size(g.array)
    pos = [x[1] for x in states]
    coins = [x[2] for x in states]
    bombs = [x[3] for x in states]
    n = size(pos, 1)
    elapsed = 0.
    racer_id = canvas_id * "racer"
    i = 1
    root = joinpath("RL", "files", "Images")
    while i <= n && elapsed < max_time 
        tic()
        translate_element(racer_id, pos[i]...)
        if !g.task_end(states[i])
            for (k, c) in enumerate(coins[i])            
                c == 0 && remove_element_by_id("""coin$(join(g.coins[k], "_"))""")
            end
            for (k, b) in enumerate(bombs[i])
                b == 0 && remove_element_by_id("""bomb$(join(g.bombs[k], "_"))""")            
            end
        else
            s = ""
            for p in g.bombs 
                s*= add_pixel_image("""bomb$(join(p, "_"))""", canvas_id, p..., "$root/bomb.png", disp = false) 
            end
            for p in g.coins 
                s*= add_pixel_image("""coin$(join(p, "_"))""", canvas_id, p..., "$root/coin.png", disp = false) 
            end
            jsdisp(s)
        end
        sleep(speed)
        elapsed += toq()
        i += 1
    end
end

#function init_state(g::grid_adventure, pos = [1, 1])
##    return [pos, [true for x in g.coins], [true for x in g.bombs]] 
#end
#export init_state


function get_env(env_id::String)
    if env_id == "circuit"
        return env_circuit()
    end
    if env_id == "right_turn"
        return env_right_turn()
    end
end
export get_env

export render, animate