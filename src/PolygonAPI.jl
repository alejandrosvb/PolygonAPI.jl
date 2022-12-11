module PolygonAPI

using HTTP, JSON, TimesDates, Dates
using  UUIDs, Printf
import Base.show

#= Abstract -> EndPoint =#
abstract type EndPoint end
##
struct LIVE <: EndPoint end 
##

#= EndPoint -> PolygonApi =#
EndPoint(::Type{T}) where {T<:EndPoint} = T == LIVE ? "https://api.polygon.io" : nothing

#= Credentials =# 
struct Credentials 
    ENDPOINT::Type{T} where {T<:EndPoint}
    KEY_ID::String
    REAL_TIME::Bool
    MAX_RANGE::Int
end

#= Environment -> Credentials =#
credentials() = Credentials(
    getproperty(PolygonApi, Symbol(ENV["POLY_API_ENDPOINT"])),
    ENV["POLY_API_KEY_ID"],
    parse(Bool, ENV["POLY_REAL_TIME"]),
    parse(Int, ENV["POLY_MAX_RANGE"])
)


#= Credentials -> PolygonApi =#
HEADER(c::Credentials)::Dict = Dict("Authorization"=>join(["Bearer", c.KEY_ID], " "))
ENDPOINT(c::Credentials)::String = EndPoint(c.ENDPOINT)

include("Aggregations.jl")
include("Markets.jl")
include("Tickers.jl")

end
