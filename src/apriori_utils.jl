

==(x::Rule, y::Rule) = x.p == y.p && x.q == y.q


function unique(v::Vector{Rule})
    out = Vector{Rule}(0)
    for i = 1:length(v)
        if !in(v[i], out)
            push!(out, v[i])
        end
    end
    return out
end


"""
This function converts a data matrix `X` into a
vector of transactions, where each row in the orginal
matrix is now an element of the vector. This is used
for pre-processing data prior to applying the a-priori
algorithm for association rule mining.
"""
function make_transactions(X::Array{Any,2})
    n, p = size(X)
    X = map(string, X)

    out = Array{Array{String, 1}, 1}(n)
    for i = 1:n
        out[i] = convert(Array{String, 1}, X[i, :])
    end
    return out
end


function make_transactions(X::DataFrame)
    n, p = size(X)
    Xstr = Array{String}(n, p)
    for j = 1:p
        Xstr[:, j] = map(string, X[:, j])
    end

    out = Array{Array{String, 1}, 1}(n)
    for i = 1:n
        out[i] = convert(Array{String, 1}, Xstr[i, :])
    end
    return out
end




function wrap_line(v, maxchar)
    if isempty(v)
        res = "{}"
    else
        res = replace(string(v), "[", "{")
        res = replace(res, "]", "}")
    end
    res = replace(res, r"\"|String|Any", "")
    n = length(res)
    out = ""
    str = 1
    stp = maxchar
    if n > maxchar
        keep_splitting = true

        while keep_splitting
            if stp < n
                # this regex finds the last comma
                chk = match(r",[^,]*$", res[str:stp])

                # In cases where we have single elements longer than
                # maxchar, `offset` will be of type Void.
                if isa(chk, RegexMatch)
                    offset = chk.offset
                elseif isa(chk, Void)
                    offset = maxchar
                end

                stp = str + offset - 1
            else
                stp = n
                keep_splitting = false
            end
            if keep_splitting
                out = string(out, res[str:stp], "\n")
            else
                n_char = maxchar - (stp - str) - 1
                padding = rpad(" ", n_char, " ")
                out = string(out, res[str:stp], padding)
            end
            str = stp + 1
            stp = str + maxchar - 1
            stp = stp > n ? n : stp
        end
    elseif n ≤ maxchar
        out = res
    end
    return out
end

# v1 = ["this here", "is", "my", "vector", "and", "this", "vector", "contains", "quite", "a", "number", "of", "variable-length", "terms", "such", "as", "these."]
# v2 = ["a", "number", "of", "variable-length", "terms", "such", "as", "these."]
# w1 = wrap_line(v1, 25)
# w2 = wrap_line(v2, 25)
# println(w1)


# Given two vectors of split lines (p and q), where the vectors
# are of the same length, this function prints out the lines and
# aligns them appropriately.
function print_equal_length(p_lines, q_lines, colwidth, i = 1, j = 1)
    np = length(p_lines)

    while i ≤ np
        if i ≠ np
            print(rpad(p_lines[i], colwidth, " "))
            println("    ", q_lines[j])
        else
            print(rpad(p_lines[i], colwidth, " "))
            print(" => ", rpad(q_lines[j], colwidth+1, " "))
        end
        i += 1
        j += 1
    end
end


function print_wrapped_lines(p_line, q_line, colwidth)
    p_lines = split(p_line, '\n', keep = true)
    q_lines = split(q_line, '\n', keep = true)
    np = length(p_lines)
    nq = length(q_lines)

    if np == nq
        print_equal_length(p_lines, q_lines, colwidth)
    elseif np > nq
        i = 1
        ndiff = np - nq

        while ndiff > 0
            println(rpad(p_lines[i], colwidth, " "))
            ndiff -= 1
            i += 1
        end
        print_equal_length(p_lines, q_lines, colwidth, i, 1)
    elseif np < nq
        j = 1
        ndiff = nq - np
        padding = lpad("", colwidth+4, " ")

        while ndiff > 0
            println(padding, rpad(q_lines[j], colwidth, " "))
            ndiff -= 1
            j += 1
        end
        print_equal_length(p_lines, q_lines, colwidth, 1, j)
    end
end

# print_wrapped_lines(wrap_line(v1, 15), wrap_line(v2, 15), 20)



function prettyprint_rulestats(r::Rule, plen, qlen, colwidth)
    p = wrap_line(r.p, colwidth)
    q = wrap_line(r.q, colwidth)
    fmt = "%0.4f"

    # print antecedent and consequent
    print_wrapped_lines(p, q, colwidth)

    # print the rule's stats
    println("$(sprintf1(fmt, r.supp)) $(sprintf1(fmt, r.conf)) $(sprintf1(fmt, r.lift))", )
end

# prettyprint_rulestats(rules[1], 10, 10, 30)


function display(rs::Vector{Rule}, colwidth = 30)
    if isempty(rs)
        return nothing
    end

    n = length(rs)

    maxlen_p = maximum(map(x -> length(wrap_line(x.p, colwidth)), rs))
    maxlen_q = maximum(map(x -> length(wrap_line(x.q, colwidth)), rs))

    # When column width greater than the max string length,
    # we use colwidth as the width of our columns.
    maxlen_p = maxlen_p < colwidth ? maxlen_p : colwidth
    maxlen_q = maxlen_q < colwidth ? maxlen_q : colwidth

    colwidth = max(maxlen_p, maxlen_q)

    println(rpad("lhs", colwidth, " "), "    ", rpad("rhs", colwidth, " "), " supp.  conf.  lift")
    for i = 1:n
        prettyprint_rulestats(rs[i], maxlen_p, maxlen_q, colwidth)
    end
end

# display(rules)


"""
    dataset(dataset_name::AbstractString)

This is a convenience function whose only purpose is to load example datasets provided with this package.

### Arguments
* `dataset_name`: A string specifying the dataset to be loaded (e.g., "zaki_data", "adult", etc).

The returned value will be a dataframe.
"""
function dataset(dataset_name::AbstractString)
    filename = joinpath(dirname(@__FILE__), "..", "data", "$dataset_name.csv")

    if !isfile(filename)
        error(@sprintf "Unable to locate file %s \n" filename)
    else
        return readtable(filename)
    end
end
