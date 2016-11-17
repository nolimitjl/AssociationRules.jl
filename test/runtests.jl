using StatsBase                 # just for sample()
using AssociationRules
# testing a-priori algorithm
transactions = [sample(1:10, 5, replace = false) for x in 1:100_000]
fk = frequent(transactions, 0.1)

groceries = ["milk", "bread", "eggs", "apples", "oranges", "beer"]
transactions = [sample(groceries, 4, replace = false) for x in 1:1000]
fk = frequent(transactions, 0.1)

rules1 = apriori(transactions, 0.1, 0.4, false);        # false for only single-item consequents
display(rules1)

# reading data from .csv
adult_data = readcsv("../data/adult.csv", skipstart = 1)
adult_trans = make_transactions(adult_data[1:1000, :])  # take only sub-set of data for convenience
rules2 = apriori(adult_trans, 0.2, 0.8)
display(rules2)



# testing SPADE algorithm
zaki_data = readcsv("../data/zaki_data.csv", skipstart = 1)
seqs = make_sequences(zaki_data, sid_col = 2, eid_col = 3, item_col = 1)
@time res = spade(seqs, 0.2, 20);

@assert length(res[1]) == 8
@assert length(res[2]) == 57
@assert length(res[3]) == 191
@assert length(res[4]) == 444
@assert length(res[5]) == 743
@assert length(res[6]) == 897
@assert length(res[7]) == 784


# testing SPADE algorithm with subset of Zaki data
zaki_data = readcsv("../data/zaki_subset_data.csv", skipstart = 1)
seqs2 = make_sequences(zaki_data, sid_col = 2, eid_col = 3, item_col = 1)
@time res2 = spade(seqs2, 0.2, 6);

