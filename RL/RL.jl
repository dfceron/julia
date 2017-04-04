module RL

import PixelArts

abstract type AbstractRLEnv end
abstract type AbstractRLAgent end
export AbstractRLEnv, AbstractRLAgent

# RLEnv Class ==============================================================
type RLEnv <: AbstractRLEnv
    states::Any
    actions::Function # (state) -> (Actions available at s)
    step::Function # (state, action) -> (new_state, reward)
    task_end::Function # (state) -> (true/false) # controversial, should I use the end_states?....
    # additional constructors, task_end defaults to false function if not provided
    RLEnv() = new()
    RLEnv(states, actions, step) = new(states, actions, step, s -> false)
    RLEnv(states, actions, step, task_end) = new(states, actions, step, task_end)
end
export RLEnv

# Accesors 
states(env::AbstractRLEnv) = env.states
actions(env::AbstractRLEnv) = env.actions
step(env::AbstractRLEnv) = env.step
task_end(env::AbstractRLEnv) = env.task_end
export states, actions, step_fun, task_end

# Setters
#set_actions(env::RLEnv, actions::Function) = (agent.actions = actions)
#set_step(env::RLEnv, step::Function) = (agent.step = step)
#set_end_states(env::RLEnv, final_states::Any) = (agent.end_state = end_states)
# export set_states, set_actions, set_step, set_end_states

# RLAgent Class ==============================================================
type RLAgent <: AbstractRLAgent
    policy::Function # (state) -> (action)
    state::Any
    # constructor if state is missing
    RLAgent() = new()
    RLAgent(policy) = new(policy)
    RLAgent(policy, state) = new(policy, state)
end
export RLAgent

# Accesors
state(agent::AbstractRLAgent) = agent.state
policy(agent::AbstractRLAgent) = agent.policy
export state, policy

# Setters
#set_state(agent::AbstractRLAgent) = (agent.state = state)
#set_policy(agent::AbstractRLAgent) = (agent.policy = policy)
#export set_state, set_policy

# Class Validation ==================================================================
function validate(env::AbstractRLEnv)
    try env.states catch e 
        if (isa(e, UndefRefError) || isa(e, ErrorException)) info("Field states::Any missing") end 
    end
    try env.actions catch e 
        if (isa(e, UndefRefError) || isa(e, ErrorException)) info("Field actions::Function (s) -> (A(s)) missing") end 
    end
    try env.step catch e 
        if (isa(e, UndefRefError) || isa(e, ErrorException)) info("Field step::Function (s, a) -> (s', r) missing") end 
    end
    try env.task_end catch e
        if (isa(e, UndefRefError) || isa(e, ErrorException)) info("Field task_end::Function missing, for non-episodic tasks use s -> false") end 
    end
end

function validate(agent::AbstractRLAgent)
    try agent.policy catch e 
        if (isa(e, UndefRefError) || isa(e, ErrorException)) info("Field policy::Function (s) -> (a) missing from type") end
    end 
    try agent.state catch e 
       if (isa(e, UndefRefError) || isa(e, ErrorException)) info("Field state::Any missing from type") end 
     end
end
export validate

# Agent & Environment Interaction ================================================

function interact!(agent::AbstractRLAgent, env::AbstractRLEnv)
    action = agent.policy(agent.state)
    new_state, reward = env.step(agent.state, action)
    agent.state = new_state
    return new_state, reward, action
end
function interact!(agent::AbstractRLAgent, env::AbstractRLEnv, action::Any)
    new_state, reward = env.step(agent.state, action)
    agent.state = new_state 
    return new_state, reward
end
function interact(agent::AbstractRLAgent, env::AbstractRLEnv, state::Any)
    action = agent.policy(state)
    new_state, reward = env.step(state, action)
    return new_state, reward, action
end
function interact(agent::AbstractRLAgent, env::AbstractRLEnv, state::Any, action::Any)
    new_state, reward = env.step(state, action)
    return new_state, reward
end
export interact, interact!


print_backup(i, s, r, a) = println("step: $i, choosing $a, moving to state $s, obtaining reward $r")
function episode!(agent::AbstractRLAgent, env::AbstractRLEnv; max_steps = 10000, verbose = false)
    step = 0
    states, rewards, actions = [agent.state], [], []
    while !env.task_end(agent.state) && step < max_steps
        state, reward, action = interact!(agent, env)
        push!(states, state); push!(rewards, reward); push!(actions, action)
        if verbose print_backup(step, state, reward, action) end
        step += 1
    end
    # if step == max_steps warn("max_steps reached") end
    return states, rewards, actions
end
function episode!(agent::AbstractRLAgent, env::AbstractRLEnv, action::Any; max_steps = 10000, verbose = false)
    step = 0
    states, rewards, actions = [agent.state], [], [action]
    state, reward = interact!(agent, env, action)
    push!(states, state); push!(rewards, reward)
    while !env.task_end(agent.state) && step < max_steps
        state, reward, action = interact!(agent, env)
        push!(states, state); push!(rewards, reward); push!(actions, action)
        if verbose print_backup(step, state, reward, action) end
        step += 1
    end
    # if step == max_steps warn("max_steps reached") end
    return states, rewards, actions
end
function episode(agent::AbstractRLAgent, env::AbstractRLEnv, state::Any; max_steps = 10000, verbose = false)
    step = 0
    states, rewards, actions = [state], [], []
    while !env.task_end(state) && step < max_steps
        state, reward, action = interact(agent, env, state)
        push!(states, state); push!(rewards, reward); push!(actions, action)
        if verbose print_backup(step, state, reward, action) end
        step += 1
    end
    # if step == max_steps warn("max_steps reached") end
    return states, rewards, actions
end
function episode(agent::AbstractRLAgent, env::AbstractRLEnv, state::Any, action::Any; max_steps = 10000, verbose = false)
    step = 0
    states, rewards, actions = [state], [], [action]
    state, reward = interact(agent, env, state, action)
    push!(states, state); push!(rewards, reward)
    while !env.task_end(state) && step < max_steps
        state, reward, action = interact(agent, env, state)
        push!(states, state); push!(rewards, reward); push!(actions, action)
        if verbose print_backup(step, state, reward, action) end
        step += 1
    end
    # if step == max_steps warn("max_steps reached") end
    return states, rewards, actions
end
export episode!, episode

# Additional methods

# Todo First Visits


# Environments ==============================================

include("env.jl")

end