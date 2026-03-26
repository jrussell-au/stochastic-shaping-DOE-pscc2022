include("30minpvdata.jl")

              network.load = Dict(1=> Dict(1=>Dict("load_bus"=>1,"pd"=>1,"qd"=>0, "pv" => 0, "battery" => 0),
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