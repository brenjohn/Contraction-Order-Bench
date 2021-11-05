using QXTools

const GATE_TENSORS = Dict{Symbol, Array{ComplexF64}}()

GATE_TENSORS[:i] = [1 0; 0 1]
GATE_TENSORS[:x] = [0 1; 1 0]
GATE_TENSORS[:y] = [0 -1im; 1im 0]
GATE_TENSORS[:z] = [1 0; 0 -1]

# GATE_TENSORS[:x_1_2] = [1+1im 1-1im; 1-1im 1+1im]/2
# GATE_TENSORS[:y_1_2] = [1+1im -1-1im; 1+1im 1+1im]/2

GATE_TENSORS[:x_1_2] = [1 -1im; -1im 1]/sqrt(2)
GATE_TENSORS[:y_1_2] = [1 -1; 1 1]/sqrt(2)
GATE_TENSORS[:hz_1_2] = [1 1+1im; 1-1im 1]/2

GATE_TENSORS[:h] = [1 1; 1 -1]/sqrt(2)
GATE_TENSORS[:s] = [1 0; 0 1im]
GATE_TENSORS[:t] = [1 0; 0 (1 + 1im)/sqrt(2)]

GATE_TENSORS[:cx] = [1 0 0 0; 0 0 0 1; 0 0 1 0; 0 1 0 0]
GATE_TENSORS[:cz] = [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 -1]

rz(theta) = [exp(-1im*theta/2) 0; 0 exp(1im*theta/2)]
fsim(theta, phi) = [1 0 0 0; 0 cos(theta) -1im*sin(theta) 0; 0 -1im*sin(theta) cos(theta) 0; 0 0 0 exp(-1im*phi)]

"""
    create_circuit_from_qasm(qasm_str::String)

Function to create the tensor network circuit described in the given qasm file.
"""
function create_circuit_from_qasm(qasm_file::String; decompose=true)
    qasm_string = open(f -> read(f, String), qasm_file)
    qasm_lines = split(qasm_string, "\n")

    num_qubits = parse(Int, qasm_lines[1])
    # circ = QXZoo.Circuit.Circ(num_qubits)
    tnc = QXTools.TensorNetworkCircuit(num_qubits)

    qubit_map = Dict{Int, Int}(-1 => 0)

    for line in qasm_lines[2:end]
        words = filter(x->length(x)>0, split(line, ['(', ')', ' ', ',']))
        if length(words) > 0
            targets, tensor = parse_words(words, qubit_map)
            push!(tnc, targets, tensor)
        end
    end

    QXTools.QXTns.add_input!(tnc)
    QXTools.QXTns.add_output!(tnc)
    tnc
end

"""
Map the given target qubits to indices according to qubit_map

If the target qubit isn't mapped to anything, increment the total number of qubits and map to total number.
"""
function transform_targets!(targets, qubit_map)
    for i = 1:length(targets)
        if haskey(qubit_map, targets[i])
            targets[i] = qubit_map[targets[i]]
        else
            qubit_map[-1] += 1
            qubit_map[targets[i]] = qubit_map[-1]
            targets[i] = qubit_map[-1]
        end
    end
    targets
end

function parse_words(words, qubit_map)
    if words[2] == "fsim"
        theta = parse(Float64, words[3])
        phi = parse(Float64, words[4])
        tensor = fsim(theta, phi)
        targets = parse.(Int, words[5:6])

    elseif words[2] == "rz"
        theta = parse(Float64, words[3])
        tensor = rz(theta)
        targets = parse.(Int, words[4:end])

    else
        gate_symbol = Symbol(words[2])
        targets = parse.(Int, words[3:end])
        tensor = GATE_TENSORS[gate_symbol]
    end

    transform_targets!(targets, qubit_map)
    targets, tensor
end