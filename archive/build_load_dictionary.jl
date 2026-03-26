function build_load_dictionary()

    dir_root = "data/load/Paul_csvs/"
    readdir_result = readdir(dir_root)

    date_format = "y-m-dTHH:MM:SSzzzz"

    n_custs = length(readdir_result) - 1

    load_dict = Dict()

    for i in 1:n_custs
        #print(i)
        load_info = CSV.read(
            string(dir_root, readdir_result[i]),
            DataFrame
            )
        load_info.time = Time.(load_info.time, date_format)
        load_dict[i] = load_info
        #println(" -done")
    end

    return load_dict

end