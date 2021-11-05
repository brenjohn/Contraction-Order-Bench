using DrWatson
using Plots
using DataFrames

# Load results
cirq_name = "sycamore_53_20_0"
df = collect_results(datadir("flowcutter_results", cirq_name))
sort!(df, :time)

# Plot treewidth vs time
plt = plot(title="flowcutter on $cirq_name", xlabel="time (seconds)", ylabel="treewidth", dpi=200)
for hyp in [true, false]
    for dec in [true, false]
        global plt
        times = df[(df.hypergraph .== hyp) .& (df.decompose .== dec), :time]
        treewidths = df[(df.hypergraph .== hyp) .& (df.decompose .== dec), :treewidth]

        plt = plot!(plt, times, treewidths, label="hypergraph=$(hyp)_decompose=$(dec)")
    end
end

png(plt, plotsdir("flowcutter_$cirq_name.png"))