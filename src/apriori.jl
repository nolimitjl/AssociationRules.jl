
type Rule
    p::Array            # antecedent (rhs)
    q::Array            # consequent (lhs)
    supp::Float64
    conf::Float64
    lift::Float64
end


# Support Count: σ(x) = | {t_i|x ⊆ t_i, t_i ∈ T}|
function σ(x::Array, T)
    res = 0
    for t in T
        if x ⊆ t
            res += 1
        end
    end
    return res
end

# Support Count: σ(x) = | {t_i|x ⊆ t_i, t_i ∈ T}|
function σ(x::String, T)
    res = 0
    for t in T
        if x in t
            res += 1
        end
    end
    return res
end

# Support Count: σ(x) = | {t_i|x ⊆ t_i, t_i ∈ T}|
function σ{U<:Number}(x::U, T)
    res = 0
    for t in T
        if x in t
            res += 1
        end
    end
    return res
end



# Support of rule x -> y, for which x ∩ y = ∅
function supp(x, y, T)
    den = length(T)
    num = σ(union(x, y), T)
    return num/den
end

# Confidence of rule x -> y, for which x ∩ y = ∅
function conf(x, y, T)
    num = σ(union(x, y), T)
    den = σ(x, T)
    return num/den
end


# Lift of rule x -> y, for which x ∩ y = ∅
# Requires confidence has already been computed
function lift(confidence, y, T)
    den = σ(y, T)/length(T)
    return confidence/den
end


# Given a vector of transactions (each is a vector), this
# function returns a single array with all the unique items.

function get_unique_items{M}(T::Array{Array{M, 1}, 1})
    dict = Dict{M, Int}()

    # loop over transactions, store each item in I
    for t in T
        for i in t
            dict[i] = 1
        end
    end
    return [x for x in keys(dict)]
end

# l = [sample([1, 2, 3, 4, 5], 4) for x in 1:10000]
# @code_warntype get_unique_items(l)
# @time get_unique_items(l)

# Given C_{k-1}, which is a vector of transactions (and each
# transaction is a vector), this function returns the candidate
# frequent item sets C_k
function apriori_gen{M}(x::Array{Array{M, 1}, 1})
    n = length(x)
    # if n < 1
    #     return Array{Array{M, 1}, 1}(0)
    # end
    m = length(x[1]) - 1
    C = Array{Array{M, 1}, 1}(0)

    for i = 1:n
        sort!(x[i])

        for j = (i+1):n
            sort!(x[j])
            keep_candidate = true

            # length k candidate itemsets are created by merging pairs of
            # length k - 1 itemsets if their first k - 2 elements identical
            for l in 1:m

                # see if all k - 1 elements are identical
                if x[i][l] != x[j][l] || x[i][m+1] == x[j][m+1]
                    keep_candidate = false
                    break
                end
            end
            if keep_candidate
                c::Array{M, 1} = vcat(x[i], x[j][end])
                push!(C, sort!(c))
            end
        end
    end
    return C              # vector of candidate itemsets: C_{k}
end

# v = [sample(1:10, 5, replace = false) for x = 1:100];
# @code_warntype apriori_gen(v)
# @time apriori_gen(v);









# Find frequent itemsets from transactions
# T: array of transactions (each is a set)
# minsup: minimum support
# NOTE: This function agrees with R
"""
    frequent(T, minsup)

Given an array of arrys holding transactions, this function returns the
frequent item sets.

### Arguments
* `T`: array of arrays of transactions
* `minsup`: minimum support needed to be considered frequent
"""
function frequent{M}(T::Array{Array{M, 1}, 1}, minsup::Float64)

    I = get_unique_items(T)

    # Find freq-itemset when k = 1: F_k = {i : i ∈ I ∧ σ({i}) ≥ N × minsup}
    F = Array{Array{Array{M, 1}, 1}, 1}(0)
    N = length(T)
    min_n = N * minsup

    push!(F, map(x -> [x], filter(i -> σ(i, T) ≥ min_n, I)))

    persist = true
    while persist
        C_k = apriori_gen(F[end]) # Generate candidate set C_k from F_{k-1}
        F_k = filter(c -> σ(c, T) ≥ min_n, C_k)
        if !isempty(F_k)
            push!(F, F_k) # Eliminate infrequent candidates, then set to F_k
        else
            persist = false
        end
    end
    return F
end

# v = [[1, 2, 3], [1, 2, 3], [1, 2, 3], [2, 3, 5], [1, 3, 4], [1, 2, 5], [2, 3, 4], [1, 4, 5], [3, 4, 5]]
# v = [[1, 2], [1, 3], [2, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 2, 3, 4], [1, 2, 3, 5], [2, 3, 4, 6]]
# v = [rand([1, 2, 3, 4, 5], 10) for x = 1:1000];
# @code_warntype frequent(v, 0.5)



# v = [[1, 2, 3], [1, 2, 3], [1, 2, 3],  [1, 2, 5], [1, 3, 4], [1, 4, 5], [2, 3, 4], [2, 3, 4], [2, 3, 5], [3, 4, 5]]
# frequent(v, 0.2)








# fk: frequent itemset
# Hm: Array of rule consequents (also arrays)
# T: Array of transactions
# minsupp: Minimum support threshold
# minconf: Minimum confidence threshold
# R: Array of rules

# fk::Vector{M},
# Hm::Vector{Vector{M}},
# T::Vector{Vector{M}},
# minsupp,
# minconf,
# R
function ap_genrules!(fk, Hm, T, minsupp, minconf, R)
    k = length(fk)
    if isempty(Hm)
        return nothing
    end
    m = length(Hm[1])

    if k > m+1
        H_mplus1 = apriori_gen(Hm)
        indcs_to_drop = Array{Int}(0)

        for (idx, h_mp1) in enumerate(H_mplus1)
            p = setdiff(fk, h_mp1)
            xconf = conf(p, h_mp1, T)

            if xconf ≥ minconf
                xsupp = supp(p, h_mp1, T)

                if xsupp ≥ minsupp
                    xlift = lift(xconf, h_mp1, T)
                    push!(R, Rule(p, h_mp1, xsupp, xconf, xlift))
                end
            else
                push!(indcs_to_drop, idx)
            end
        end

        # remove the indices of consequents with low confidence
        reverse!(indcs_to_drop)
        for indx in indcs_to_drop
            deleteat!(H_mplus1, indx)
        end
        ap_genrules!(fk, H_mplus1, T, minsupp, minconf, R)
    end
end

# rules = Vector{Rule}(0)
# freq = [1, 2]
# consq = [Int[], [1], [2], [3], [4], [5]]
# trans = [[1, 2], [1, 3], [2, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 2, 3, 4], [1, 2, 3, 5], [2, 3, 4, 6]]
# @code_warntype ap_genrules!(freq, consq, trans, 0.20, 0.01, rules)
# rules

# rules = Vector{Rule}(0)
# freq = [1, 2, 3, 4]
# consq = [[1], [2], [3], [4]]
# trans = [[1], [2], [1, 2], [1, 3], [2, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 2, 3, 4], [1, 2, 3, 5], [2, 3, 4, 6]]
# ap_genrules!(freq, consq, trans, 0.2, 0.01, rules)
# rules

# fk::Vector{M},
# H1::Vector{Vector{M}},
# R::Vector{Rule},
# T,
# minsupp,
# minconf

function gen_onerules!(fk, H1, R, T, minsupp, minconf)
    m = length(H1)
    for j = 1:m
        xconf = conf(fk, H1[j], T)
        if !(H1[j][1] in fk) && xconf ≥ minconf
            xsupp = supp(fk, H1[j], T)
            if xsupp ≥ minsupp
                xlift = lift(xconf, H1[j], T)
                push!(R, Rule(fk, H1[j], xsupp, xconf, xlift))
            end
        end
    end
end

# rule1 = Vector{Rule}(0)
# gen_onerules!([1], [[1], [2], [3]], rule1, [[1, 2], [2, 3], [1, 3]], 0.1, 0.01)


# Generate rules from frequent itemsets
# F: 3-level nested vectors of frequent itemsets
# T: transaction list
# minconf: minimum confidence threshold
# multi_consquents: whether or not to compute rules with multiple consequents
function gen_rules{M}(F::Array{Array{Array{M, 1}, 1}, 1}, T, minsupp, minconf, multi_consquents = true)
    k_max = length(F)
    R = Array{Rule, 1}(0)

    for k = 1:k_max
        H1 = map(x -> [x], get_unique_items(F[k]))

        for f in F[k]
            gen_onerules!(f, H1, R, T, minsupp, minconf)
            if multi_consquents
                ap_genrules!(f, H1, T, minsupp, minconf, R)
            end
        end
    end
    return unique(R)
end

# v = [[1, 2], [1, 3], [1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 2, 3, 4], [1, 2, 3, 5],
#      [2, 4, 5, 6], [1, 3, 5, 6], [2, 3, 4, 5, 6], [1, 3, 4, 5, 6], [2, 3, 4, 5, 6]]
#
# fr = frequent(v, 0.2)
# rules = gen_rules(fr, v, 0.1, 0.8, false)
#
# display(rules, v)

# rs = Vector{Rule}(0)
# a = Rule([1], [2])
# b = Rule([1], [2])
# push!(rs, a)
# push!(rs, b)



# This function has constant memory footprint regardless
# of the input size of T (for fixed minsupp and minconf)
"""
    apriori(T, minsupp, minconf, multi_consquents = true)

This function implements the a-priori algorithm (Agrawal & Srikant, 1994) for
generating association rules using transactional-type data.

### Arguments
* `T`: array of arrays of transactions
* `minsupp`: minimum support threshold to be considered a frequent item set
* `minconf`: minimum confidence threshold for association rules
* `multi_consquents`: boolean indicating whether or not to generate multi-item consequents, default is `true`

"""
function apriori(T, minsupp, minconf, multi_consquents = true)
    F = frequent(T, minsupp)
    R = gen_rules(F, T, minsupp, minconf, multi_consquents)
    return R
end


#
