using DrWatson
using DataStructures

using OMEinsumContractionOrders: optimize_code, TreeSA, MergeGreedy, uniformsize, timespace_complexity, GreedyMethod, KaHyParBipartite, SABipartite
using Yao
using YaoToEinsum: yao2einsum
using KaHyPar, Random

# Load functions to read qflex qasm files.
include(srcdir("reading_qflex_qasm_yao.jl"))
using .YaoQASMReader: yaocircuit_from_qasm

# Set up parameters to run flowcutter with.
allparams = Dict(
    "cirq_name" => "sycamore_53_20_0",
    "method" => [KaHyParBipartite(sc_target=51), SABipartite(sc_target=52), GreedyMethod(), TreeSA()],
)
param_dicts = dict_list(allparams)

for params in param_dicts
    Random.seed!(2)
    @unpack cirq_name, method = params
    println("running circuit $(cirq_name), method = $(method)")

    # Create the TensorNetworkCircuit object for the circuit
    qasm_file = datadir("circuits", cirq_name * ".txt")
    c = yaocircuit_from_qasm(qasm_file)
    eincode, xs = yao2einsum(c, initial_state=zeros(Int,nqubits(c)), final_state=zeros(Int,nqubits(c)))
    sizes = uniformsize(eincode, 2)
    time = @elapsed optcode = optimize_code(eincode, sizes, method, MergeGreedy())
    tc, sc= timespace_complexity(optcode, sizes)
    @show tc, sc

    results = merge(Dict(["method"=>string(typeof(method).name.name), "cirq_name"=>cirq_name, "time"=>time, "time_complexity"=>tc, "space_complexity"=>sc]))
    wsave(datadir("flowcutter_results", cirq_name, savename(Dict(["method"=>string(typeof(method).name.name)]), "jld2", ignores="cirq_name")), results)
end