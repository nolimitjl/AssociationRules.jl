

include("./src/AssociationRules.jl")

v = [sample(1:20, 5, replace = false) for x = 1:10_000];

@time res = par_apriori_gen(v[1:100], 4);
# Profile.clear_malloc_data()

@time res = par_apriori_gen(v, 4);



@time res = par_apriori_gen3(v[1:100], 4, 100);
# Profile.clear_malloc_data()

@time res = par_apriori_gen3(v, 4, 10_000);
