module AssociationRules

using Formatting
using Base.Threads
using DataFrames

import Base.==
import Base.unique
import Base.display
import Base.isempty
import Base.find


export Rule, Sequence, IDList, PrefixNode, SeqRule, apriori, frequent, make_transactions, spade, make_sequences, sequential_rules, dataset

include("apriori.jl")
include("apriori_utils.jl")
include("parallel_tools.jl")
include("spade.jl")
include("spade_utils.jl")
include("sequential_rules.jl")

end # module
