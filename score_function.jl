using LinearAlgebra
include("ode_rk4.jl")


function J(X_storage,x_final,X_0,dt)
    Tmax = size(X_storage)[1]
    trajectory_time = dt * Tmax
    fuel_consumtion = abs(X_storage[Tmax,4]- X_0[11])
    is_finalState = norm(X_storage[Tmax,1:3] - x_final)
    J = is_finalState + fuel_consumtion + trajectory_time
    return J
end

#### faudrait peut etre modifier le rk4 pour que s'arrete selon lieu ? ---> question a se poser sur le x_final


physical_data = physic_cst()
aircraft = avion()
aircraft_cst = MiniBee_cst(aircraft)
# initialisation
X = SA[0,0,0,1,0,0,0,15,0,0,300]
U0 = SA[100,0,0,0]
step = 0.01
# parameters of rk4
t = 0 
T = 0.2
dt = 0.01
#resolution
@time X_stockage = RK4(t,T,dt,X,U0,f)

X_final = SA[0.791827;   0.0177039;    0.219864]


println("Test : ")
println("Attendu : (fuel)20+(dist)0+(temps)0.2")
println("Score = ",J(X_stockage,X_final,X,dt))

