
# Performance tuning

v = [[1, 2, 3], [1, 2, 3], [1, 2, 3], [2, 3, 5], [1, 3, 4], [1, 2, 5], [2, 3, 4], [1, 4, 5], [3, 4, 5]]
v = [[1, 2], [1, 3], [2, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 2, 3, 4], [1, 2, 3, 5], [2, 3, 4, 6]]
# v = [rand([1, 2, 3, 4, 5], 10) for x = 1:1000];
# @code_warntype freq_itemsets(v, 0.5)


# testing freq_itemsets()
v = [[1, 2, 3], [1, 2, 3], [1, 2, 3],  [1, 2, 5], [1, 3, 4], [1, 4, 5], [2, 3, 4], [2, 3, 4], [2, 3, 5], [3, 4, 5]]
freq_itemsets(v, 0.2)


# testing gen_rules()
rules = Vector{Rule}(0)
freq = [1, 2]
consq = [Int[], [1], [2], [3], [4], [5]]
trans = [[1, 2], [1, 3], [2, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 2, 3, 4], [1, 2, 3, 5], [2, 3, 4, 6]]
ap_genrules!(freq, consq, trans, 0.20, 0.01, rules)
rules

rules = Vector{Rule}(0)
freq = [1, 2, 3, 4]
consq = [[1], [2], [3], [4]]
trans = [[1], [2], [1, 2], [1, 3], [2, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [1, 2, 3, 4], [1, 2, 3, 5], [2, 3, 4, 6]]
ap_genrules!(freq, consq, trans, 0.2, 0.01, rules)
rules


rule1 = Vector{Rule}(0)
@time gen_onerules!([1], [[1], [2], [3]], rule1, [[1, 2], [2, 3], [1, 3]], 0.2, 0.01)


v = [rand([1, 2, 3, 4, 5, 6], 10) for x = 1:100];
rules = apriori(v, 0.01, 0.08)
show_rulestats(rules)



# Example using UCI Adult dataset

using DataFrames

d = readtable("./data/adult.csv", nastrings = ["?"])
complete_cases!(d)

dmat = convert(Array, d)
transactions = make_transactions(dmat)
@time rules = apriori(transactions[1:1000], 0.60, 0.8);

display(rules)
