using StatsBase                 # just for sample()
import AssociationRules
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


# test sequential-rule building algorithm
seqrules = sequential_rules(res, 0.01, 5)
@assert length(seqrules) == 3886

seqrules2 = sequential_rules(res2, 0.01, 5)
@assert length(seqrules2) == 28



# testing SPADE algorithm with subset of Zaki data
zaki_data = readcsv("../data/zaki_data_extra.csv", skipstart = 1)
seqs3 = make_sequences(zaki_data, sid_col = 2, eid_col = 3, item_col = 1)
@time res3 = spade(seqs3, 0.2, 5);


# test sequential-rule building algorithm
@time seqrules3 = sequential_rules(res3, 0.01, 5);
length(seqrules3)

letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N"]
n = 1000
nseq = 20
ntime = 50
zaki_rep_data = hcat(rand(letters, n), rand(collect(1:nseq), n), rand(collect(1:ntime), n))

seqs4 = make_sequences(zaki_rep_data, sid_col = 2, eid_col = 3, item_col = 1)
@time res4 = spade(seqs4, 0.2, 5);



function benchmark1(n)
    nseq = 10
    ntime = 10
    maxdepth = 10
    letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"]

    dat = hcat(rand(letters, n), rand(collect(1:nseq), n), rand(collect(1:ntime), n))
    seqs = make_sequences(dat, sid_col = 2, eid_col = 3, item_col = 1);
    @time x = spade(seqs, 0.2, maxdepth);
    return nothing
end

benchmark1(100)
