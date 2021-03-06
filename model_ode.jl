include("debut.jl")

function f(dX,X,p,t=0)
    """
    dot X = f(X,U)
    modelling the physical behavior of the aircraft
    Input :
       X = [x1,x2,x3,  v1,v2,v3,  q1,q2,q3,q4, m] : position, speed, quaternion, masse
       U = [U1,  U2,U3,U4] : thrust and others forces for the rotation
    """

    physical_data, aircraft, Ut = p
    U = Ut(t,X)

    """Amélioration Cedric : pour gagner du temps sur les matrices : passer en StaticArrays (utiliser le constructeurs + nombre d'élément ou macro : @SArray([ , ]) )
    ce qu'on fait pour l'instant, on déclare une liste de StaticArrays

    Gagner encore plus de temps : pré-allouer des vecteurs bidons avant la création de fonction, passer en argument de f(X,U), puis re-remplir ( i.= @SArray)
    Dans ce cas là pas de possibilité de changer avec SArray donc utiliser MArray

    On veut lire X[7] seulement, donc on peut utiliser des @view de chaque composante
    Plus facile : @views i .= @SArray([ ])

    Si on fait des variables globales plus tard => penser à mettre const devant"""

    @views P_I2B = @SArray([2*(X[7]^2+X[8]^2)-1       2*(X[8]*X[9]-X[7]*X[10])  2*(X[8]*X[10]+X[9]*X[7]);
    2*(X[8]*X[9]+X[7]*X[10])  2*(X[7]^2+X[9]^2)-1       2*(X[9]*X[10]-X[8]*X[7]);
    2*(X[8]*X[10]-X[9]*X[7])  2*(X[9]*X[10]+X[8]*X[7])  2*(X[7]^2+X[10]^2)-1]
    )

    @views i = P_I2B[:,1]

    @views M = @SArray([0 -U[2] -U[3] -U[4] ;
                        U[2] 0 U[4] -U[3] ;
                        U[3] -U[4] 0 U[2] ;
                        U[4] U[3] -U[2] 0] )        # matrix for quaternion

    """ Cedric : changer noms de variables en q0, q1, .. ne change pas le temps de calcul """

    @views v_body = transpose(P_I2B) * X[4:6] # Peut faire uniquement la transposé car changement de base entre repères orthonormés
    norm2_v_body = sum(v_body .^ 2)

    @views alpha = asin(v_body[3]/ sqrt(norm2_v_body))
    @views beta = asin(v_body[2]/ sqrt(norm2_v_body))
    ca = cos(alpha)
    cb = cos(beta)
    sa = sin(alpha)
    sb = cos(beta)
    @views P_B2W = @SArray([ ca*cb -ca*sb -sa;
                    sb cb 0;
                    sa*cb -sa*sb ca])                            # "passage" matrix to wind coordinate to aircraft coordinate
    C_D = aircraft_cst.C_D0  + aircraft_cst.C_D_alpha2 * alpha^2
    C_C = aircraft_cst.C_C_beta * beta
    C_L = aircraft_cst.C_L_alpha * alpha
    Cst_DCL = @SArray([C_D , C_C , C_L])
    @views eta_a = rho(X[3], pressure, physical_data.r,physical_data.T) * aircraft_cst.Sw * 0.5
    @views norm2_speed = (X[4]^2+X[5]^2+X[6]^2)
    Fa = - eta_a .* norm2_v_body .* P_I2B * P_B2W * Cst_DCL  # aerodynamical forces

    @views dX[1:3] .= X[4:6]                                    # dot x = v
    @. @views dX[4:6] =  0*Fa/X[11] + physical_data.g  + U[1]/X[11] * (aircraft.kt*X[4:6] + i)
    @views dX[7:10] .= 1/2 .* M * X[7:10]  # .*q en utilisant @views q = X[7:10] / pour 1/2 .* avec .= au début
    @views dX[11] = -aircraft.kt * U[1]                        # dot m = -kt * trhust : variation of fuel
    return dX
end
