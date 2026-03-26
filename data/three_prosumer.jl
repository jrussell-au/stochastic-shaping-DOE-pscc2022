include("30minpvdata.jl")

              load = Dict(1=> Dict(1=>Dict("load_bus"=>1,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>1,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>1,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         2=> Dict( 1=>Dict("load_bus"=>2,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>2,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>2,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         3=> Dict( 1=>Dict("load_bus"=>3,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>3,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>3,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         4=> Dict( 1=>Dict("load_bus"=>4,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>4,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>4,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         5=> Dict( 1=>Dict("load_bus"=>5,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>5,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>5,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         6=> Dict( 1=>Dict("load_bus"=>6,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>6,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>6,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         7=> Dict( 1=>Dict("load_bus"=>7,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   2=>Dict("load_bus"=>7,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   3=>Dict("load_bus"=>7,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                         8=> Dict( 1=>Dict("load_bus"=>8,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   2=>Dict("load_bus"=>8,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   3=>Dict("load_bus"=>8,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                         9=> Dict( 1=>Dict("load_bus"=>9,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   2=>Dict("load_bus"=>9,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   3=>Dict("load_bus"=>9,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                         10=> Dict(1=>Dict("load_bus"=>10,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>10,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>10,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         11=> Dict(1=>Dict("load_bus"=>11,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   2=>Dict("load_bus"=>11,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   3=>Dict("load_bus"=>11,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                         12=> Dict(1=>Dict("load_bus"=>12,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   2=>Dict("load_bus"=>12,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   3=>Dict("load_bus"=>12,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                         13=> Dict(1=>Dict("load_bus"=>13,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>13,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>13,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         14=> Dict(1=>Dict("load_bus"=>14,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   2=>Dict("load_bus"=>14,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   3=>Dict("load_bus"=>14,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                         15=> Dict(1=>Dict("load_bus"=>15,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>15,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>15,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         16=> Dict(1=>Dict("load_bus"=>16,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   2=>Dict("load_bus"=>16,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   3=>Dict("load_bus"=>16,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                         17=> Dict(1=>Dict("load_bus"=>17,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   2=>Dict("load_bus"=>17,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   3=>Dict("load_bus"=>17,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                         18=> Dict(1=>Dict("load_bus"=>18,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   2=>Dict("load_bus"=>18,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   3=>Dict("load_bus"=>18,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                         19=> Dict(1=>Dict("load_bus"=>19,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>19,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>19,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         20=> Dict(1=>Dict("load_bus"=>20,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   2=>Dict("load_bus"=>20,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   3=>Dict("load_bus"=>20,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                         21=> Dict(1=>Dict("load_bus"=>21,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   2=>Dict("load_bus"=>21,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   3=>Dict("load_bus"=>21,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                         22=> Dict(1=>Dict("load_bus"=>22,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   2=>Dict("load_bus"=>22,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   3=>Dict("load_bus"=>22,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                         23=> Dict(1=>Dict("load_bus"=>23,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>23,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>23,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         24=> Dict(1=>Dict("load_bus"=>24,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   2=>Dict("load_bus"=>24,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   3=>Dict("load_bus"=>24,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                         25=> Dict(1=>Dict("load_bus"=>25,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>25,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>25,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         26=> Dict(1=>Dict("load_bus"=>26,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>26,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>26,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         27=> Dict(1=>Dict("load_bus"=>27,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>27,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>27,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         28=> Dict(1=>Dict("load_bus"=>28,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   2=>Dict("load_bus"=>28,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   3=>Dict("load_bus"=>28,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                         29=> Dict(1=>Dict("load_bus"=>29,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   2=>Dict("load_bus"=>29,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                   3=>Dict("load_bus"=>29,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                        30=> Dict(1=>Dict("load_bus"=>30,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>30,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>30,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        31=> Dict(1=>Dict("load_bus"=>31,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>31,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>31,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        32=> Dict(1=>Dict("load_bus"=>32,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>32,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>32,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        33=> Dict(1=>Dict("load_bus"=>33,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>33,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>33,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        34=> Dict(1=>Dict("load_bus"=>34,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>34,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>34,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        35=> Dict(1=>Dict("load_bus"=>35,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  2=>Dict("load_bus"=>35,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  3=>Dict("load_bus"=>35,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                        36=> Dict(1=>Dict("load_bus"=>36,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  2=>Dict("load_bus"=>36,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  3=>Dict("load_bus"=>36,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                        37=> Dict(1=>Dict("load_bus"=>37,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  2=>Dict("load_bus"=>37,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  3=>Dict("load_bus"=>37,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                        38=> Dict(1=>Dict("load_bus"=>38,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>38,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>38,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        39=> Dict(1=>Dict("load_bus"=>39,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  2=>Dict("load_bus"=>39,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  3=>Dict("load_bus"=>39,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                        40=> Dict(1=>Dict("load_bus"=>40,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  2=>Dict("load_bus"=>40,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  3=>Dict("load_bus"=>40,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                        41=> Dict(1=>Dict("load_bus"=>41,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>41,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  3=>Dict("load_bus"=>41,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                        42=> Dict(1=>Dict("load_bus"=>42,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>42,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>42,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        43=> Dict(1=>Dict("load_bus"=>43,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>43,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>43,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        44=> Dict(1=>Dict("load_bus"=>44,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>44,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>44,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        45=> Dict(1=>Dict("load_bus"=>45,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  2=>Dict("load_bus"=>45,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  3=>Dict("load_bus"=>45,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                        46=> Dict(1=>Dict("load_bus"=>46,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  2=>Dict("load_bus"=>46,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  3=>Dict("load_bus"=>46,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                        47=> Dict(1=>Dict("load_bus"=>47,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>47,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>47,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        48=> Dict(1=>Dict("load_bus"=>48,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  2=>Dict("load_bus"=>48,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  3=>Dict("load_bus"=>48,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                        49=> Dict(1=>Dict("load_bus"=>49,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  2=>Dict("load_bus"=>49,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  3=>Dict("load_bus"=>49,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                        50=> Dict(1=>Dict("load_bus"=>50,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  2=>Dict("load_bus"=>50,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  3=>Dict("load_bus"=>50,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                        51=> Dict(1=>Dict("load_bus"=>51,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  2=>Dict("load_bus"=>51,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  3=>Dict("load_bus"=>51,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                        52=> Dict(1=>Dict("load_bus"=>52,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>52,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>52,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        53=> Dict(1=>Dict("load_bus"=>53,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>53,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>53,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        54=> Dict(1=>Dict("load_bus"=>54,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  2=>Dict("load_bus"=>54,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  3=>Dict("load_bus"=>54,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                        55=> Dict(1=>Dict("load_bus"=>55,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  2=>Dict("load_bus"=>55,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  3=>Dict("load_bus"=>55,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0)),

                        56=>Dict(1=>Dict("load_bus"=>56,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                 2=>Dict("load_bus"=>56,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                 3=>Dict("load_bus"=>56,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        57=>Dict(1=>Dict("load_bus"=>57,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                 2=>Dict("load_bus"=>57,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                 3=>Dict("load_bus"=>57,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        58=>Dict(1=>Dict("load_bus"=>58,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                 2=>Dict("load_bus"=>58,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                 3=>Dict("load_bus"=>58,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        59=>Dict(1=>Dict("load_bus"=>59,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                 2=>Dict("load_bus"=>59,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                 3=>Dict("load_bus"=>59,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        60 =>Dict(1=>Dict("load_bus"=>60,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>60,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>60,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        61 =>Dict(1=>Dict("load_bus"=>61,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>61,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  3=>Dict("load_bus"=>61,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                        62=> Dict(1=>Dict("load_bus"=>62,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>62,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>62,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        63=>Dict(1=>Dict("load_bus"=>63,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                 2=>Dict("load_bus"=>63,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                 3=>Dict("load_bus"=>63,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        64=> Dict(1=>Dict("load_bus"=>64,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>64,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                  3=>Dict("load_bus"=>64,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                         65=> Dict(1=>Dict("load_bus"=>65,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   2=>Dict("load_bus"=>65,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1),
                                   3=>Dict("load_bus"=>65,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 1)),

                         66=> Dict(1=>Dict("load_bus"=>66,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>66,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>66,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                         67=> Dict(1=>Dict("load_bus"=>67,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   2=>Dict("load_bus"=>67,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                   3=>Dict("load_bus"=>67,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        68=> Dict(1=>Dict("load_bus"=>68,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  2=>Dict("load_bus"=>68,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
                                  3=>Dict("load_bus"=>68,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0)),

                        69=> Dict(1=>Dict("load_bus"=>69,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  2=>Dict("load_bus"=>69,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0),
                                  3=>Dict("load_bus"=>69,"pd"=>1,"qd"=>0, "pv" => 1, "battery" => 0))
        );
 a=0
    for i in keys(load)
        for j in keys(load[i])
            #if load[i][j]["battery"]==1
                if load[i][j]["pv"]==1
                   global a=a+1
               end
            #end
        end
    end


s= [solar solar solar solar solar solar solar solar solar solar solar solar solar solar solar solar solar solar solar solar]


           SOLAR= zeros(48,207)
           for j in 1:207, t in 1:48
               global SOLAR[t,j]= sum(s[i,j]/6 for i in (6*t-5):6*t);
           end
           spv=SOLAR';



d= [demand demand demand demand demand demand demand demand]


           DEMAND= zeros(48,207)
           for j in 1:207, t in 1:48
               global DEMAND[t,j]= sum(d[i,j]/6 for i in (6*t-5):6*t);
           end
           lpf=DEMAND'



           TEP1=[108.6, 95.82, 90.48, 75.02, 67.46, 76.5, 76.5, 78.47, 77.24, 81.14, 82.17,
                          106.97, 112.27, 108.93, 115.6, 114.66, 111.83, 94.2, 90.01, 102.22, 93.46,
                          93.66, 80.61, 74.46, 79.6, 102.73, 104.26, 114.17, 118.08, 117.84, 114.65,
                          83.7, 104.57, 109.37, 103.97, 88.35, 104.58, 96, 100.04, 102.66, 99.32, 85.71,
                          93.1, 86.44, 100.95, 86.64, 84.64, 93.39];

TEP=TEP1

#TEP=zeros(24)
#for i in 1:24
#    TEP[i]= sum(TEP1[j]/2 for j in (2*i-1):2*i);
#end





           TUR=[9.45255, 8.81462, 38.75653, 64.94392, 70.37165, 34.79907, 68.88422, 41.53488, 20.71242, 12.79569, 10.12096, 8.81638, 9.61297,
                  21.29109, 12.96928, 8.81462, 10.09911, 35.42014, 81.96196, 14.7726, 9.40365, 8.28667, 9.5203, 11.37889, 8.90616, 16.4538,
                  10.47607, 8.82359, 8.81411, 10.96433, 7.65213, 11.73802, 31.52093, 55.43023, 8.83, 16.3714, 8.88708, 8.81462,
                  13.60164, 23.27158, 10.38471, 10.51745, 33.00282, 83.24854, 8.87622, 8.82615, 8.82872, 10.7407];

           TDR=[13.90667, 6.55667, 8.74979, 9.68067, 9.60833, 13.16, 8.73, 8.40146, 8.72607, 13.76661, 7.81792, 11.69257, 8.60828, 7.365,
                    8.75553, 8.7816, 9.22105, 10.11823, 8.99225, 11.73727, 11.51433, 8.77673, 12.14331, 8.73, 7.93029, 8.11528, 14.23146, 7.13255,
                    8.73, 8.25592, 14.25187, 14.74, 11.57323, 13.37167, 7.74889, 9.56833, 8.31472, 8.31827, 8.36771, 8.71367, 8.275, 12.34657, 12.62167,
                    8.73, 14.12146, 8.9157, 7.76831, 8.215];


                    TDR61=[0.01161, 0.00488, 0.00297, 0, 0, 0, 0, 0, 0.00452, 0.02008, 0.03, 0.03, 0.01476, 0.0168, 0.00647, 0.00666, 0.00991, 0.00707,
                    0, 0, 0.01628, 0.01539, 0.01331, 0.00853, 0.00873, 0.02016, 0.00999, 0.01506, 0.00525, 0.01666, 0.02006, 0.00991, 0.00623,
                    0, 0.03, 0.02024, 0.03, 0.00504, 0.00677, 0.02022, 0.02029, 0.00982, 0, 0, 0.01438, 0.03, 0.03, 0.03 ];

                    TUR61=[4.2828, 5.22168, 1.13716, 0.89528, 0.83824, 0.95032, 0.8381, 0.82373, 19.66929, 234.40142, 4.15135, 141.11408, 2.00895,
                    16.36178, 5.94529, 4.41669, 4.16719, 1.14504, 1.24569, 99.5081, 249.19799, 2.92052, 3.19048, 4.28615, 1.69209, 1.13838,
                    82.41081, 222.21018, 14.4661, 4.05913, 32.06854, 1.2785, 1.1497, 0.88699, 3.25087, 1.14769, 203.71076, 5.02789, 1.6243, 7.03755,
                    15.25048, 1.45454, 0.9687, 0.88208, 46.61231, 3.30312, 3.52276, 3.60312
                    ];


                    TDR51=[0.6737, 0.32812, 2.02799, 0.36621, 0.15737, 0.55993, 0.14824, 0.43164, 0.23386, 0.24266, 0.40828, 3.90252, 0.75976, 0.44,
                    0.41495, 0.43502, 0.22724, 1.55801, 0.14, 0.21582, 0.33658, 0.22981, 0.32218, 0.43502, 0.2897, 0.8, 0.40841, 0.26165, 0.19499,
                    0.27716, 0.53006, 0.8, 0.74075, 0.49317, 0.44325, 0.8, 0.3579, 0.43499, 0.43669, 0.25308, 0.43166, 0.8, 0.73969, 0.14,
                    0.31664, 0.52971, 0.39449, 0.40354 ];

                    TUR51=[4.26124, 3.07072, 1.40382, 2.54943, 2.73886, 1.19279, 2.52075, 2.25165, 1.33241, 1.46293, 1.5047, 3.02056, 5.5193, 2.83354,
                    2.02796, 3.01825, 5.41943, 1.42385, 3.54324, 1.92256, 1.50934, 1.51221, 1.32066, 7.23679, 5.61822, 1.43244, 1.34381, 1.31919,
                    5.69119, 2.04906, 6.30721, 4.37439, 1.45208, 1.94988, 1.38552, 1.50124, 1.61582, 3.0229, 14.69679, 4.74085, 5.84286, 7.80491,
                    1.16687, 2.63114, 1.28769, 3.02307, 2.02221, 1.39947 ];

                    TDR601=[0.07, 0.03356, 0.0417, 0.04, 0.03226, 0.04, 0.03, 0.03878, 0.04, 0.05672, 0.097, 0.08335, 0.05691, 0.04422, 0.04, 0.03679,
                    0.04, 0.04849, 0.0209, 0.04667, 0.05, 0.0668, 0.07, 0.03857, 0.04, 0.04834, 0.05327, 0.07, 0.04, 0.0419, 0.04169, 0.05165,
                    0.04, 0.04, 0.10441, 0.04672, 0.07, 0.04, 0.04, 0.04, 0.04494, 0.04335, 0.04, 0.03, 0.04835, 0.08891, 0.09471, 0.13363];

                    TUR601=[2.95828, 21.40484, 3.39871, 1.55381, 1.64923, 3.84993, 1.56555, 1.46296, 1.50158, 1.42081, 1.54527, 2.9584, 3.09329,
                    8.95867, 15.51737, 15.05833, 4.27049, 3.32593, 3.61924, 2.1183, 1.42299, 1.37928, 1.46531, 6.24912, 2.87377, 3.27342, 2.30947,
                    1.45089, 27.41325, 3.43885, 3.33421, 3.36832, 3.35757, 1.58584, 1.53809, 3.33663, 1.45682, 16.47785, 3.04947, 4.31064, 11.209,
                    3.6102, 3.62625, 1.84664, 2.99499, 1.62376, 1.60589, 1.54287];

                    rise6=TUR61


                    lower6=TDR61

                    rise60=TUR601

                    lower60=TDR601

                    rise5=TUR51

                    lower5=TDR51


                    riseprice=[rise6 rise60 rise5]
                    riseprice=riseprice'
                    lowerprice=[lower6 lower60 lower5]
                    lowerprice=lowerprice'
