

using Base.Threads

# v = [[1, 2, 3], [1, 2, 3], [1, 2, 3],  [1, 2, 5], [1, 3, 4], [1, 4, 5], [2, 3, 4], [2, 3, 4], [2, 3, 5], [3, 4, 5]]
# v = [sample(1:20, 5) for x = 1:10_000];


function combine_dicts!(d, d2)
    all_keys = [collect(keys(d)); collect(keys(d2))]
    uniq_keys = unique(all_keys)

    for k in uniq_keys
        d[k] = get(d, k, 0) + get(d2, k, 0)
    end
end


# Given an integer and a number of chunks, this function
# returns a vector of ranges that partition 1:n into
# nchnks total chunks.
function gen_ranges(n, nchnks)
    step_size = round(Int64, (ceil(n/nchnks)))
    first_idx = 1
    last_idx = 1 + step_size
    range_vec = Array{Range, 1}(nchnks)
    for i = 1:nchnks
        range_vec[i] = range(first_idx, step_size)
        first_idx += step_size
        last_chk = first_idx + step_size
        step_size = last_chk > n ? (n - first_idx + 1) : step_size
    end
    return range_vec
end


function gen_ranges(first_idx, n, nchnks)
    num = n - first_idx + 1
    step_size = round(Int64, (ceil(num/nchnks)))

    last_idx = 1 + step_size
    range_vec = Array{Range, 1}(nchnks)
    for i = 1:nchnks
        range_vec[i] = range(first_idx, step_size)
        first_idx += step_size
        last_chk = first_idx + step_size
        step_size = last_chk > n ? (n - first_idx + 1) : step_size
    end
    return range_vec
end



# Given a vector of vectors, this function returns a
# Dict with counts representing the frequency of each
# individual value.
function count_values(u)
    out = Dict()
    for i = 1:length(u)
        for v in u[i]
            out[v] = get(out, v, 0) + 1
        end
    end
    out
end


function pcount_values(v)
    nt = nthreads()
    dict_vec = Vector{Dict}(nt)
    range_vec = gen_ranges(length(v), nt)

    @threads for j = 1:nt
        dict_vec[j] = count_values(v[range_vec[j]])
    end
    cnt_dict = Dict()

    for j = 2:nt
        combine_dicts!(dict_vec[1], dict_vec[j])
    end
    return dict_vec[1]
end

# @time count_values(v)
# @time pcount_values(v)
#
# d1 = count_values(v[1:50_000])
# d2 = count_values(v[50_001:100_000])



function init_nested_vectors(typ, num, num_inner_elem = 0)
    inner = Array{typ, 1}(num_inner_elem)
    outer = Array{Array, 1}(0)

    for i = 1:num
        push!(outer, copy(inner))
    end
    outer
end

# init_nested_vectors(Array, 4)


# This version of the function seems to work, but because of
# an issue with the type of `i` being inferred as `Box.Core`,
# the performance is no better than the serial implentation. This
# should be fixed once the Github issue #15276 is resolved.

function par_apriori_gen{M}(x::Array{Array{M, 1}, 1}, num_threads)
    n = length(x)
    m = length(x[1]) - 1
    C_arr = init_nested_vectors(Array, num_threads)

    for i = 1:n
        sort!(x[i])
        range_vec = gen_ranges(i+1, n, num_threads)

        @threads for t = 1:num_threads
            for j in range_vec[t]
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
                    push!(C_arr[t], sort!(c))
                end
            end
        end
    end
    C::Array{Array{M, 1}, 1} = reduce(vcat, C_arr)
    return C              # vector of candidate itemsets: C_{k}
end


function par_apriori_gen2{M}(x::Array{Array{M, 1}, 1}, num_threads)
    n = length(x)

    m = length(x[1]) - 1
    C_arr = Array{Array{M, 1}, 1}(0)

    for i = 1:n
        sort!(x[i])
        range_vec = gen_ranges(i+1, n, num_threads)

        @parallel for t in 1:num_threads
            for j in range_vec[t]

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
                    push!(C_arr[t], sort!(c))
                end
            end
        end
    end
    return C_arr              # vector of candidate itemsets: C_{k}
end

# v = [sample(1:20, 5, replace = false) for x = 1:10_000];




function _par_apriori_gen{M}(x::Array{Array{M, 1}, 1}, num_threads, i, range_vec)
    n = length(x)
    m = length(x[1]) - 1
    C_arr = init_nested_vectors(Array, num_threads)
    sort!(x[i])

    @threads for t = 1:num_threads
        for j in range_vec[t]
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
                push!(C_arr[t], sort!(c))
            end
        end
    end

    C::Array{Array{M, 1}, 1} = reduce(vcat, C_arr)
    return C              # vector of candidate itemsets: C_{k}
end



function par_apriori_gen3{M}(x::Array{Array{M, 1}, 1}, num_threads, n)
    C_arr = Array{Array{Array{M, 1}, 1}}(n)
    for i = 1:n
        range_vec = gen_ranges(i+1, n, num_threads)
        C_arr[i] = _par_apriori_gen(x, num_threads, i, range_vec)
    end
    res = reduce(vcat, C_arr)
end
