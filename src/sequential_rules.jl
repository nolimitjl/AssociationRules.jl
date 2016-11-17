# NOTE: This code is meant to be used to generate sequential rules
# from the frequent sequences generated by the SPADE algorithm.


# ==(x::SequenceRule, y::SequenceRule) = x.rule == y.rule && x.conf == y.conf
#
# function unique(v::Array{SequenceRule, 1})
#     out = Array{SequenceRule, 1}(0)
#     for i = 1:length(v)
#         if !in(v[i], out)
#             push!(out, v[i])
#         end
#     end
#     return out
# end


==(x::SeqRule, y::SeqRule) = x.prefix == y.prefix && x.postfix == y.postfix && x.conf == y.conf

function unique(v::Array{SeqRule, 1})
    out = Array{SeqRule, 1}(0)
    for i = 1:length(v)
        if !in(v[i], out)
            push!(out, v[i])
        end
    end
    return out
end



# NOTE: The gen_rules1() function is quite inefficient. In
# particular, it's runtime is O(n*m*2^k) where k is the number
# of elements in the pattern, m is the number of patterns for a
# given pattern length k, and n is the number of different pattern
# lengths. Additionally, though this corresponds to the pseudocode
# Zaki provides in his orginal paper, it is not the implementation
# that appears in the arulesSequence package.

function gen_rules1(F::Array{Array{IDList, 1}, 1}, min_conf)
    supp_cnt = count_patterns(F)
    rules = String[]

    # Check the confidence for all sub-patterns
    # from all of our frequent patterns
    for k = 1:length(F)
        for i = 1:length(F[k])
            sub_patrns = gen_combin_subpatterns(F[k][i].patrn)
            for s in sub_patrns
                if s ≠ ""
                    cnt = get(supp_cnt, s, 0)
                    conf = isfinite(cnt) ? F[k][i].supp_cnt/cnt : -Inf

                    if conf ≥ min_conf
                        push!(rules, "$s => $(pattern_string(F[k][i].patrn))")
                    end
                end
            end
        end
    end
    rules
end

# rules = gen_rules1(res, 0)


function create_children(node::PrefixNode, uniq_items::Array{String,1}, supp_cnt)
    seq_ext_children = Array{PrefixNode,1}(0)
    item_ext_children = Array{PrefixNode,1}(0)

    for item in uniq_items
        seq_patrn = sequence_extension(node.pattern, item)

        # computing support
        seq_string = pattern_string(seq_patrn)
        seq_supp = get(supp_cnt, seq_string, 0)

        # only append children with non-zero support
        if seq_supp > 0
            seq_extd_child = PrefixNode(seq_patrn)
            seq_extd_child.support = seq_supp
            push!(seq_ext_children, seq_extd_child)
        end

        itm_patrn = item_extension(node.pattern, item)
        itm_string = pattern_string(itm_patrn)
        itm_supp = get(supp_cnt, itm_string, 0)

        # We only create an item-extended child if this item
        # doesn't already appear in the last array of our our
        # parent (i.e., `node`). Otherwise, we would either be
        # duplicating an entry in the last array, or be making
        # an exact duplicate of our parent (assuming we only allow
        # unique entries in the pattern's arrays).
        if itm_supp > 0 && item ∉ node.pattern[end]
            item_extd_child = PrefixNode(itm_patrn)
            item_extd_child.support = itm_supp
            push!(item_ext_children, item_extd_child)
        end
    end
    return (seq_ext_children, item_ext_children)
end

# xroot = PrefixNode([["A"]])
# xsupp_cnt = Dict("{A} -> {B}" => 1,
#                  "{A} -> {C}" => 1,
#                  "{A} -> {D}" => 1)
# @code_warntype create_children(xroot, ["A", "B", "C", "D"], xsupp_cnt)


function growtree!(root, uniq_items, supp_cnt, depth = 0, maxdepth = 1)
    root.seq_ext_children, root.item_ext_children = create_children(root, uniq_items, supp_cnt)
    allchildren = [root.seq_ext_children; root.item_ext_children]

    for child in allchildren
        # push!(tree, child)

        if depth+1 < maxdepth
            growtree!(child, uniq_items, supp_cnt, depth+1, maxdepth)
        end
    end
end

# xroot = PrefixNode([["A"]])
# xsupp_cnt = Dict("{A} -> {B}" => 1,
#                  "{A} -> {C}" => 1,
#                  "{A} -> {D}" => 1)
# @code_warntype growtree!(xroot, ["A", "B", "C", "D"], xsupp_cnt, 0, 3)


function build_tree(F::Array{Array{IDList,1},1}, maxdepth)
    supp_cnt = count_patterns(F)
    uniq_items = String[]

    # NOTE: This loop is an embarassment. This is all to get the unique items
    # from the frequent sequences. The same unique item vector is created by
    # the spade() function. It should be passed to here.
    for k = 1:length(F)
        for i = 1:length(F[k])
            for j = 1:length(F[k][i].patrn)
                for l = 1:length(F[k][i].patrn[j])
                    if F[k][i].patrn[j][l] ∉ uniq_items
                        push!(uniq_items, F[k][i].patrn[j][l])
                    end
                end
            end
        end
    end

    root = PrefixNode([[""]])
    root.seq_ext_children = PrefixNode[]

    for itm in uniq_items
        child_node1 = PrefixNode([[itm]])
        child_node1.support = supp_cnt[pattern_string(itm)]
        push!(root.seq_ext_children, child_node1)
        growtree!(child_node1, uniq_items, supp_cnt, 1, maxdepth)
    end
    return root
end

# @time build_tree(res3, 20);
# @code_warntype build_tree(res, 20);



function generate_sr_from_tree_root!(sp_root::PrefixNode, rules, min_conf)
    if isdefined(sp_root, :seq_ext_children)
        for seq_child in sp_root.seq_ext_children
            # println(seq_child)

            generate_sr_from_subtree!(sp_root, seq_child, rules, min_conf)
        end
    end

    if isdefined(sp_root, :item_ext_children)
        for itm_child in sp_root.item_ext_children
            generate_sr_from_tree_root!(itm_child, rules, min_conf)
        end
    end
end


function generate_sr_from_subtree!(pre, seq_child, rules, min_conf, one_elem_consq = true)
    conf = seq_child.support/pre.support

    if conf ≥ min_conf
        post = postfix(pre.pattern, seq_child.pattern)
        if one_elem_consq
            if length(post) == 1
                new_rule = SeqRule(pre.pattern, post, conf)
                if new_rule ∉ rules
                    push!(rules, new_rule)
                end
            end
        elseif !one_elem_consq
            new_rule = SeqRule(pre.pattern, post, conf)
            if new_rule ∉ rules
                push!(rules, new_rule)
            end
        end

        if isdefined(seq_child, :seq_ext_children)
            if !isempty(seq_child.seq_ext_children)
                for grandchild in seq_child.seq_ext_children

                    # adding this very speculative (and based on a guess)
                    generate_sr_from_subtree!(seq_child, grandchild, rules, min_conf)

                    generate_sr_from_subtree!(pre, grandchild, rules, min_conf)
                end
            end
        end

        if isdefined(seq_child, :item_ext_children)
            if !isempty(seq_child.item_ext_children)
                for grandchild in seq_child.item_ext_children
                    generate_sr_from_subtree!(pre, grandchild, rules, min_conf)
                end
            end
        end
    end
end



# t = build_tree(res, 20)
# xrules = []
# @code_warntype generate_sr_from_subtree!(t.seq_ext_children[1], t.seq_ext_children[1].seq_ext_children[1], xrules, 0.01)
# @code_warntype generate_sr_from_tree_root!(t.seq_ext_children[1], xrules, 0.01)


# NOTE: The sequential_rules() function currently builds a
# prefix tree and then traverses the tree generating rules.
# This could be made more efficient and cache-friendly by
# building and traversing the tree in the same pass.
"""
    sequential_rules(F; min_conf, maxdepth)

This function takes an array of arrays with `IDList` objects and
returns an array of sequential rules.

### Arguments
* `F`: an array of arrays of `IDList` generated by `spade()` function
* `min_conf`: minimum level of confidence rules must have
* `maxlength`: maximum number of elements a rule must have (e.g., `maxlength = 3`
    gives rules such as <{A},{B}> => <{C}> or <{D,E}> => <{F}>.
"""
function sequential_rules(F, min_conf = 0.1, maxlength = 5)
    root = build_tree(F, maxlength)
    rules = Array{SeqRule,1}(0)

    for i = 1:length(root.seq_ext_children)
        generate_sr_from_tree_root!(root.seq_ext_children[i], rules, min_conf)
    end
    rules
end

# @code_warntype sequential_rules(res, 0.01)
# @time sequential_rules(res2, 0.01, 20);
