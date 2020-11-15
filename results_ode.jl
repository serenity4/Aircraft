using DifferentialEquations
using Plots
include("model_ode.jl")
include("ode_rk4.jl")

physical_data = physic_cst()
aircraft = avion()
aircraft_cst = MiniBee_cst(aircraft)


#########################################################
####            Version with julia solver            ####
#########################################################
f_ode = ODEFunction(f) # y a t il d'autres truc à mettre ? 
u_0 = SA[0,0,0,1,0,0,0,0,0,15,300]
t_span = (0,1)
p = SA[50,0,0,0]

@time begin
    problem_ode = ODEProblem(f_ode,u_0,t_span,p)
    sol = solve(problem_ode)
end

println(sol)

trajectory = sol[1:3,:]

plt = plot3d(
    1,
    title = "Trajectory",
    marker = 2,
)

@gif for i=1:size(trajectory)[2]
     push!(plt,trajectory[1,i], trajectory[2,i], trajectory[3,i])
 end every 20

@show(plt)

plt_coord = plot(trajectory[1,:], title="trajectory on the different axes")
plot!(trajectory[2,:])
plot!(trajectory[3,:])




#########################################################
####                Version with RK4                 ####
#########################################################

# initialisation
X = SA[0,0,0,1,0,0,0,15,0,0,300]
U0 = SA[100,0,0,0]
step = 0.01
# parameters of rk4
t = 0 
T = 20
dt = 1
#resolution
@time x_stockage = RK4(t,T,dt,X,U0,step,f)

println("Solution : ", x_stockage)


plt = plot3d(
    1,
    title = "Trajectory",
    marker = 2,
)

@gif for i=1:size(trajectory)[2]
     push!(plt,x_stockage[i,1], x_stockage[i,2], x_stockage[i,3])
 end every 20

@show(plt)

plt_coord = plot(x_stockage[:,1], title="trajectory on the different axes")
plot!(x_stockage[:,2])
plot!(x_stockage[:,3])