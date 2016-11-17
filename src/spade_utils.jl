
function ==(x::IDList, y::IDList)
    res = x.sids == y.sids &&
          x.eids == y.eids &&
          x.patrn == y.patrn &&
          x.typ == y.typ &&
          x.supp == y.supp
    return res
end


function unique(v::Array{IDList, 1})
    out = Array{IDList, 1}(0)
    for i = 1:length(v)
        if !in(v[i], out)
            push!(out, v[i])
        end
    end
    return out
end


# function display(x::IDList)
#     if isempty(x)
#         println("$(x.pattern) has support 0")
#     else
#         last = x.sids[end]
#         nchar = 2 + length(string(last))
#
#         println("$(x.pattern)")
#         for i = 1:length(x.sids)
#             println(rpad(x.sids[i], nchar, " "), x.eids[i])
#         end
#     end
# end

# function display(x::Array{IDList,1})
#     for i = 1:length(x)
#         display(x[i])
#         println("\n")
#     end
# end



"""
This function behaves a bit like Python's str.rfind()
method; it gets the indices where the `needle` appears
in the `haystack`. Returns 0:-1 if `needle` is not found.
"""
function rfind(haystack::String, needle::String)
    n = length(haystack)
    nchar = length(needle)
    window = nchar - 1
    start_idx = 0
    stop_idx = -1
    for i = (n - window):-1:1
        if haystack[i:i+window] == needle
            start_idx = i
            stop_idx = i+window
            break
        end
    end
    return UnitRange{Int}(start_idx, stop_idx)
end

function rfind(haystack::String, needle::Char)
    last_idx = findlast(haystack, needle)
    return last_idx
end



function unique_items(s::Sequence)
    d = Dict{String, Int64}()
    for i = 1:length(s.items)
        for k in s.items[i]
            d[k] = get(d, k, 0) + 1
        end
    end
    return collect(keys(d))
end



function sanitize_items(items, excluded_strings = ["{", "}", ", "])
    res = items
    n = length(res)
    for i = 1:n
        for s in excluded_strings
            res[i] = replace(res[i], s, " ")
        end
    end
    return res
end

# itms1 = ["this -> is a {string}", "and {so} is -> {} this"]
# sanitize_items(itms1)


# These two find() functions are just for dev purposes
# to track down cases where we disagree with R
function find(x::Array{IDList, 1}, patrn::String)
    indcs = Array{Int, 1}(0)
    n = length(x)

    for i = 1:n
        if x[i].pattern == patrn
            push!(indcs, i)
        end
    end
    return indcs
end


function find(x::Array{IDList, 1}, patrn::Array{Array{String, 1}, 1})
    indcs = Array{Int, 1}(0)
    n = length(x)

    for i = 1:n
        if x[i].patrn == patrn
            push!(indcs, i)
        end
    end
    return indcs
end



"""
    make_sequences(dat; item_col, sid_col, eid_col, excluded_strings)

Given a data set, `dat`, in long format, this function extracts all
the sequences and returns an array of `Sequence` objects. By "long format"
we mean that each row represents a given item in a given sequence at a given
time. Thus, `dat` must have columns for item, sequence number, and time point

### Arguments
* `dat`: a two-dimensional array-type object (i.e., `Array{T,2}` or `DataFrame`)
* `item_col`: column index for actual item at a given time and in a given sequence.
* `sid_col`: sequence ID column index
* `eid_col`: event ID column index
* `excluded_strings`: vector of strings to be removed from the raw input data
"""
function make_sequences(dat; item_col = 1, sid_col = 2, eid_col = 3, excluded_strings = ["{", "}", ", "])
    seq_ids = unique(dat[:, sid_col])
    num_seqs = length(seq_ids)
    seq_arr = Array{Sequence, 1}(num_seqs)

    dat[:, item_col] = sanitize_items(dat[:, item_col], excluded_strings)

    for (i, sid) in enumerate(seq_ids)
        row_indcs = find(dat[:, sid_col] .== sid)

        dat_subset = dat[row_indcs, :]
        event_ids = unique(dat[row_indcs, eid_col])
        items = Array{Array{String, 1}, 1}(0)

        for eid in event_ids
            indcs = find(eid .== dat_subset[:, eid_col])
            items_arr = convert(Array{String, 1}, dat_subset[indcs, item_col])
            push!(items, sort(items_arr))
        end
        seq_arr[i] = Sequence(sid, event_ids, items)
    end
    return seq_arr
end

# d = readcsv("./data/zaki_data.csv", skipstart = 1)
#
# seq_array = make_sequences(d, 2, 3, 1)



# Given a vector of strings, this function returns
# a single string with all elements of the vector
# having been concatenated.
function join_strings(x::Array{String, 1})
    n = length(x)
    s = ""
    for i = 1:n
        if i < n
            s *= string(x[i], ",")
        elseif i == n
            s *= x[i]
        end
    end
    return s
end

# join_strings(["ab", "cd"])



# Given the pattern from an IDList, this function returns
# a string illustrating the temporal relation of the
# seqeunce. For example: "{A} -> {B,C} -> {D}".
function pattern_string(x::Array{Array{String, 1}, 1})
    n = length(x)
    s = ""
    for i = 1:n
        if i < n
            s *= string("{", join_strings(x[i]), "},")
        elseif i == n
            s *= string("{", join_strings(x[i]), "}")
        end
    end
    return s
end


function pattern_string(args...)
    n = length(args)
    s = ""
    for i = 1:n
        if i < n
            s *= string("{", join_strings(args[i]), "},")
        elseif i == n
            s *= string("{", join_strings(args[i]), "}")
        end
    end
    return s
end

# pattern_string(["ab", "cd"], ["de", "fg"])

pattern_string(s::String) = string("{", s, "}")


# This is our workhorse used in the nloops_gen(), which
# is a function that generates n nested loops.
function addpattern!(v, args...)
    s = pattern_string(args...)
    push!(v, s)
end



# This function gets the counts for each pattern
# we have in our frequent-pattern set.

function count_patterns(F::Array{Array{IDList, 1}, 1})
    m = length(F)
    cnt = Dict{String, Int}()
    for k = 1:m
        n = length(F[k])
        for i = 1:n
            cnt[pattern_string(F[k][i].patrn)] = F[k][i].supp_cnt
        end
    end
    cnt
end





# This function performs a sequence extension for patterns in
# a prefix tree. In essence, we take a single string `s` and
# append it as an array in the sequence pattern `seq`.
sequence_extension(seq::Array{Array{String,1},1}, s::String) = [seq; [[s]]]

s1 = [["A"], ["B", "C"]]
str = "D"
sequence_extension(s1, str)


# Given a sequence pattern in the form of a nested array, `seq`, and
# a single string, `s`, this function takes `s` and appends it to
# the last array in the nested array `seq`. Note that this function
# is a bit messy looking b/c I couldn't get type-inference to work
# without breaking the steps up a bit. So it goes.
function item_extension(seq::Array{Array{String,1},1}, s::String)
    old_last_arr = seq[end]
    new_last_arr::Array{String,1} = [old_last_arr; s]

    child_seq = [seq[1:end-1]; [sort!(new_last_arr)]]
    return child_seq
end

s1 = [["A"], ["B", "C"], ["D"]]
str = "E"
item_extension(s1, str)





# Given two pattern strings such as "{A,B} -> {C}" and
# "{A,B} -> {C} -> {D,E}", where one is a subset of the
# other, this function will extract the postfix from
# the second string, `p2`.
function extract_postfix(p1::String, p2::String)
    last_idx = length(p1)
    out = p2[last_idx+5:end]
    out
end

# extract_postfix("{A,B} -> {C}", "{A,B} -> {C} -> {D,E}")





function postfix(root::Array{Array{String,1},1}, descendant::Array{Array{String,1},1})
    post = Array{Array{String,1},1}(0)
    n = length(root)
    m = length(descendant)
    i = 1

    while i ≤ n
        if root[i] == descendant[i]
            i += 1
        else
            error("Prefix of root doesn't matach descendant")
        end
    end
    for j = i:m
        push!(post, descendant[j])
    end
    post
end

# a = [["a"], ["b"]]
# b = [["a"], ["b"], ["cd"], ["e"]]
# postfix(a, b)






# NOTE: The functions below are used to convert our output to
# match R's returned strings (e.g., "<{A}, {B}> => <{C}>").

function as_set_string(vect::Vector)
    out = "{"
    n = length(vect)
    for (i, x) in enumerate(vect)
        out *= x
        if i ≠ n
            out *= ","
        end
        if i == n
            out *= "}"
        end
    end
    out
end


function as_r_string(r::SeqRule)
    out = "<"
    n = length(r.prefix)
    for (i, timepoint) in enumerate(r.prefix)
        out *= as_set_string(timepoint)
        if i ≠ n
            out *= ","
        end
        if i == n
            out *= ">"
        end
    end
    out *= " => <"

    m = length(r.postfix)
    for (i, timepoint) in enumerate(r.postfix)
        out *= as_set_string(timepoint)
        if i ≠ m
            out *= ","
        end
        if i == m
            out *= ">"
        end
    end
    out
end


function as_r_string(seq::Array{Array{String,1},1})
    out = "<"
    n = length(seq)
    for (i, timepoint) in enumerate(seq)
        out *= as_set_string(timepoint)
        if i ≠ n
            out *= ","
        end
        if i == n
            out *= ">"
        end
    end
    out
end


function rules_to_dataframe(rules::Array{SeqRule,1})
    df = DataFrame()
    n = length(rules)

    df[:rules] = Array{String,1}(n)
    for i = 1:n
        df[i, :rules] = as_r_string(rules[i])
    end
    df
end
