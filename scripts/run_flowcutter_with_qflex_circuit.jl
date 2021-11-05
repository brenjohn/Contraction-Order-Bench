using DrWatson
using DataStructures

import QXGraphDecompositions as qxg

# Load functions to read qflex qasm files.
include(srcdir("reading_qflex_qasm.jl"))

# Set up parameters to run flowcutter with.
allparams = Dict(
    "cirq_name" => "sycamore_53_20_0",
    "time" => [2^t for t = 2:8],
    "seed" => 42,
    "decompose" => [true, false],
    "hypergraph" => [true, false]
)
param_dicts = dict_list(allparams)


for params in param_dicts
    @unpack cirq_name, time, seed, decompose, hypergraph = params
    println("running for decompose, hypergraph, time = ", (decompose, hypergraph, time))

    # Create the TensorNetworkCircuit object for the circuit
    qasm_file = datadir("circuits", cirq_name * ".txt")
    tnc = create_circuit_from_qasm(qasm_file; decompose=decompose)

    # Create the line graph for the given tnc.
    lg, symbol_map = convert_to_line_graph(tnc; use_hyperedges=hypergraph)

    # Use flow cutter to try find a tree decomposition of the line graph.
    td = qxg.flow_cutter(lg, time; seed=seed)

    results = merge(params, Dict(String(k) => p for (k, p) in td))
    wsave(datadir("flowcutter_results", cirq_name, savename(params, "jld2", ignores="cirq_name")), results)
end