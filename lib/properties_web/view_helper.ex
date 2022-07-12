defmodule PropertiesWeb.ViewHelper do
  use Phoenix.HTML
  @number_regex ~r/\B(?=(\d{3})+(?!\d))/
  @building_type_map %{
    "01" => "Ranch",
    "02" => "Bi-level",
    "03" => "Split-level",
    "04" => "Cape-Cod",
    "05" => "Colonial",
    "06" => "Tudor",
    "07" => "Townhouse",
    "08" => "Residence (Old-style)",
    "09" => "Mansion",
    "10" => "Cottage",
    "11" => "Duplex (Old-style)",
    "12" => "Duplex (New-style)",
    "13" => "Duplex Cottage",
    "15" => "Triplex",
    "16" => "Apartment (4-6 Units)",
    "17" => "Townhouse Apartment",
    "18" => "Milwaukee Bungalow",
    "19" => "Apartment (7-9 Units)",
    "20" => "Apartment (10-15 Units)",
    "21" => "Apartment (16+ Units)",
    "22" => "Bungalow (Old-style)"
  }

  @land_use_map %{
    "0006" => "BILLBOARD",
    "0007" => "MALL ATRIUM",
    "0008" => "RIVERWALK",
    "0009" => "SKYWALKS",
    "0180" => "HORTICULTURAL SPECIALTIES",
    "0181" => "NURSERY PRODUCTS",
    "0279" => "ANIMAL SPECIALTIES, NOT ELSEWH",
    "0742" => "ANIMAL HOSPITALS",
    "0752" => "BOARDING KENNELS",
    "0780" => "LANDSCAPE SERVICES",
    "0781" => "LANDSCAPE PLANNING",
    "0782" => "LAWN AND GARDEN SERVICES",
    "0783" => "ORNAMENTAL SHRUB AND TREE SERV",
    "0831" => "FOREST NURSERIES AND GATHERING",
    "0851" => "FORESTRY SERVICES",
    "1442" => "CONSTRUCTION SAND AND GRAVEL",
    "1500" => "BUILDING CONSTRUCTN-GENERAL",
    "1521" => "GENRL CONTRACTRS-SNGL FAMLY",
    "1541" => "GENRL CONTRACTRS-INDUSTRIAL",
    "1542" => "GENERAL CONTRACTORS-NONRESIDEN",
    "1611" => "HIGHWAY AND STREET CONSTRUCTN",
    "1623" => "WATER, SEWER, PIPELINE, AND CO",
    "1629" => "HEAVY CONSTRUCTION",
    "1711" => "PLUMBG, HEATG, A/C CONTRACTOR",
    "1721" => "PAINTING CONTRACTORS",
    "1731" => "ELECTRICAL CONTRACTORS",
    "1741" => "MASONRY AND OTHER STONEWORK",
    "1742" => "PLASTERING, DRYWALL, ACOUSTICA",
    "1743" => "TERRAZZO, TILE, MARBLE, AND MO",
    "1751" => "CARPENTRY WORK",
    "1761" => "ROOFING, SIDING, SHEET MTL WRK",
    "1771" => "CONCRETE WORK",
    "1781" => "WATER WELL DRILLING",
    "1791" => "STRUCTURAL STEEL ERECTIO",
    "1793" => "GLASS AND GLAZING WORK",
    "1794" => "EXCAVATING AND FOUNDATION WRK",
    "1795" => "WRECKING AND DEMOLITION WORK",
    "1799" => "CONTRACTORS-SPECIAL TRADE",
    "2000" => "FOOD PRODUCTS",
    "2011" => "MEAT PACKING PLANTS",
    "2013" => "SAUSAGES AND PREPARED MEATS",
    "2022" => "CHEESE,NATURAL AND PROCESSED",
    "2023" => "DRY, CONDENSED, AND EVAPORATED",
    "2032" => "CANNED SPECIALTIES",
    "2035" => "PICKLED FRUITS AND VEGETABLES",
    "2037" => "FROZEN FRUITS, FRUIT JUICES AN",
    "2038" => "FROZEN SPECIALTIES, NOT ELSEWH",
    "2051" => "BREAD,BAKERY PROD",
    "2064" => "CANDY AND OTHER CONFECTIONERY",
    "2066" => "CHOCOLATE AND COCOA PROD",
    "2068" => "SALTED AND ROASTED NUTS AND SE",
    "2077" => "ANIMAL FATS AND OILS",
    "2080" => "BEVERAGES",
    "2082" => "MALT BEVERAGES",
    "2083" => "MALT",
    "2085" => "DISTILLED AND BLENDED LIQUORS",
    "2086" => "SOFT DRINKS-CANNED AND BTTLD",
    "2087" => "FLAVORING EXTRACTS AND FLAVORI",
    "2091" => "CANNED AND CURED FISH",
    "2097" => "MANUFACTURED ICE",
    "2099" => "FOOD PREPARATIONS",
    "2231" => "BROADWOVEN FABRIC MILLS, WOOL",
    "2241" => "NARROW FABRIC AND OTHER SMALLW",
    "2251" => "WOMEN'S FULL-LENGTH AND KNEE-L",
    "2252" => "HOSIERY, NOT ELSEWHERE CLASSIF",
    "2253" => "KNIT OUTERWEAR MILLS",
    "2259" => "KNITTING MLLS, NOT ELSEWHERE",
    "2281" => "YARN SPINNING MILLS",
    "2299" => "TEXTILE GOODS NOT CLASSIFIED",
    "2300" => "APPAREL, FABRIC PRODUCTS",
    "2335" => "WOMENS, MISSES; AND JUNIORS BL",
    "2394" => "CANVAS AND RELATED PROD",
    "2399" => "FABRICATED TEXTILE PRODUCTS",
    "2400" => "LUMBER, WOOD PRODUCTS/NO FURN",
    "2431" => "MILLWORK",
    "2434" => "WOOD KITCHEN CABINETS",
    "2448" => "WOOD PALLETS , SKIDS",
    "2491" => "WOOD PRESERVING",
    "2499" => "WOOD PRODUCTS",
    "2511" => "WOOD HOUSEHOLD FURNITURE",
    "2514" => "METAL HOUSEHOLD FURNITURE",
    "2531" => "PUBLIC BUILDING AND RELATED FU",
    "2542" => "METAL STORE UNITS,FIXTURES",
    "2631" => "PAPERBOARD MILLS",
    "2650" => "PAPERBOARD CONTAINERS-BOXES",
    "2652" => "SETUP PAPERBOARD BOXES",
    "2653" => "CORRUGATED,SOLID FIBER BOXES",
    "2657" => "FOLDING PAPERBOARD BOXES",
    "2672" => "COATED AND LAMINATED PAPER, NO",
    "2675" => "DIE-CUT PAPER AND PAPERBOARD A",
    "2677" => "ENVELOPES",
    "2679" => "CONVERTED PAPER AND PAPERBOARD",
    "2711" => "NEWSPAPERS-PUBLISH, PRINTING",
    "2721" => "PERIODICALS-PUBLISH AND PRINT",
    "2731" => "BOOK PUBLISHING, PRINTING",
    "2732" => "BOOK PRINTING",
    "2741" => "MISC. PUBLISHING",
    "2752" => "LITHOGRAPHIC-CMMRCL PRNTNG",
    "2753" => "COMMERCIAL PRINTING, LITHOGRAP",
    "2759" => "COMMERCIAL PRINTING-MISC.",
    "2761" => "MANIFOLD BUSINESS FORMS",
    "2789" => "BOOKBINDING,RELATED WORK",
    "2791" => "TYPESETTING",
    "2796" => "PLATEMAKING AND RELATED SERVIC",
    "2800" => "CHEMICALS AND ALLIED PRODUCTS",
    "2816" => "INORGANIC PIGMENTS",
    "2819" => "INDUSTRIAL INORGANIC CHEMICAL",
    "2833" => "MEDICINL CHEM -BOTANICAL PROD",
    "2834" => "PHARMACEUTICAL PREPARATIONS",
    "2841" => "SOAP AND OTHER DETERGENTS",
    "2842" => "POLISHES,SANITATION GOODS",
    "2844" => "TOILET PREPERATIONS",
    "2851" => "PAINTS AND ALLIED PROD.",
    "2861" => "GUM AND WOOD CHEMICALS",
    "2865" => "CYCLIC ORGANIC CRUDES AND INTE",
    "2869" => "INDUSTRIAL ORGANIC CHEMICALS",
    "2873" => "NITROGENOUS FERTILIZERS",
    "2891" => "SEALANTS AND ADHESIVES",
    "2893" => "PRINTING INK",
    "2899" => "CHEMICAL PREPERATIONS",
    "2900" => "PETROLEUM REFNG/RELATED INDUST",
    "2911" => "PETROLEUM REFINING",
    "2951" => "ASPHALT PAVING MIXTURES AND BL",
    "2992" => "LUBRICATING OILS,GREASES",
    "3000" => "RUBBER & MISC. PLASTIC PROD.",
    "3052" => "RUBBER AND PLASTICS HOSE AND B",
    "3053" => "GASKETS,SEALING,PACKING DEVCS.",
    "3069" => "FABRICATED RUBBER PRODUCTS",
    "3080" => "MISC. PLASTIC PRODUCTS",
    "3081" => "UNSUPPORTED PLASTICS FILM AND",
    "3082" => "UNSUPPORTED PLASTICS PROFILE S",
    "3083" => "LAMINATED PLASTICS PLATE, SHEE",
    "3089" => "PLASTIC PRODUCTS, NOT ELSEWHER",
    "3111" => "LEATHER TANNING,FINISHING",
    "3131" => "BOOT AND SHOE CUT STOCK AND FI",
    "3151" => "LEATHER GLOVES AND MITTENS",
    "3172" => "PERSONAL LEATHER GOODS, EXCEPT",
    "3199" => "LEATHER GOODS,  NOT ELSEWHERE",
    "3211" => "FLAT GLASS",
    "3229" => "PRESSED AND BLOWN GLASS AND GL",
    "3241" => "CEMENT, HYDRAULIC",
    "3271" => "CONCRETE BLOCK,BRICK",
    "3272" => "CONCRETE PRODUCTS",
    "3273" => "READY-MIXED CONCRETE",
    "3281" => "CUT STONE AND STONE PRODUCTS",
    "3291" => "ABRASIVE PRODUCTS",
    "3299" => "NONMETALLIC MINERAL PROD.",
    "3300" => "METALS-PRIMARY,FOUNDRIES",
    "3312" => "BLAST FURNACES,STEEL MILLS",
    "3316" => "COLD-ROLLED STEEL SHEET, STRIP",
    "3321" => "IRON FOUNDRIES-GRAY",
    "3322" => "IRON FOUNDRIES-MALLEABLE",
    "3324" => "STEEL INVESTMENT FOUNDRIES",
    "3325" => "STEEL FOUNDRIES",
    "3341" => "SECONDARY SMELTING AND REFING",
    "3356" => "NONFERROUS ROLLING,DRAWING",
    "3357" => "DRAWING AND INSULATING OF NONF",
    "3363" => "ALUMINUM DIE-CASTINGS",
    "3364" => "NONFERROUS DIE-CASTINGS, EXCEP",
    "3365" => "ALUMINUM FOUNDRIES",
    "3366" => "BRASS,BRONZE,COPPER FOUNDRIES",
    "3398" => "METAL HEAT TREATING",
    "3400" => "FABRICATED METAL PRODUCTS",
    "3411" => "METAL CANS",
    "3423" => "HAND AND EDGE TOOLS",
    "3429" => "HARDWARE",
    "3433" => "HEATING EQUIPMENT",
    "3441" => "FABRICATED STRUCTURAL METAL",
    "3442" => "METAL DOORS, SASH, FRAMES, MOL",
    "3443" => "PLATE WORK FABRICATED",
    "3444" => "SHEET METAL WORK",
    "3446" => "ARCHITECTURAL METAL WORK",
    "3449" => "MISCELLANEOUS STRUCTURAL METAL",
    "3451" => "SCREW MACHINE PROD.",
    "3452" => "BOLTS,NUTS,RIVETS,WASHERS",
    "3462" => "IRON,STEEL FORGINGS",
    "3469" => "METAL STAMPINGS",
    "3471" => "PLATING AND POLISHING",
    "3479" => "METAL COAT.,ALLIED SERV.",
    "3493" => "STEEL SPRINGS,EXCEPT WIRE",
    "3494" => "VALVES,PIPE FITTINGS",
    "3495" => "WIRE SPRINGS",
    "3496" => "FABRICATED WIRE PROD.,MISC.",
    "3498" => "FABRICATED PIPE AND PIPE FITTI",
    "3499" => "FABRICATED METAL PROD.",
    "3519" => "INTERNAL COMBUSTION ENGINES",
    "3531" => "CONSTUCTION MACHINERY",
    "3532" => "MINING MACHINERY AND EQUIPMENT",
    "3534" => "ELEVATORS,MOVING STAIRWAYS",
    "3535" => "CONVEYORS AND CONVEYING EQUIPM",
    "3536" => "OVERHEAD TRAVELING CRANES, HOI",
    "3537" => "INDUSTRIAL TRUCKS,TRACTORS",
    "3541" => "MACHINE TOOLS,METAL CUTTING",
    "3542" => "MACHINE TOOLS,METAL FORMING",
    "3544" => "SPCL.,DIES,TOOLS,JIGS,FXTRS.",
    #
    "7521" => "AUTO PARKING",
    "7523" => "PARKING LOT",
    "7525" => "PARKING STRUCTURE,GARAGE"
  }

  def land_use_map do
    @land_use_map
  end

  def number_with_commas(number) do
    number = to_string(number)
    Regex.replace(@number_regex, number, ",")
  end

  def air_conditioning(ac) when ac == 1, do: "Yes"
  def air_conditioning(_), do: "No"
  def parking_type(nil), do: "None"
  def parking_type(parking_type), do: parking_type
  def building_type(building_type) do
    Map.get(@building_type_map, building_type, "Unknown")
  end
  def land_use(land_use) do
    Map.get(@land_use_map, land_use, "Unknown")
  end

  def mapbox_static(latitude, longitude) do
    "https://api.mapbox.com/styles/v1/mapbox/streets-v10/static/geojson(%7B%22type%22%3A%22Point%22%2C%22coordinates%22%3A%5B#{
      longitude
    }%2C#{latitude}%5D%7D)/#{longitude},#{latitude},14/500x300?access_token=pk.eyJ1IjoibWl0Y2hlbGxoZW5rZSIsImEiOiJjam5ybXN5ZnQwOXpkM3BwYXo3ZDY4aHJzIn0.ktVRbqOVQpj75MqJPZueCA"
  end

  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, translate_error(error),
        class: "help-block",
        data: [phx_error_for: input_id(form, field)]
      )
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext "errors", "is invalid"
    #
    #     # Translate the number of files with plural rules
    #     dngettext "errors", "1 file", "%{count} files", count
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(PropertiesWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PropertiesWeb.Gettext, "errors", msg, opts)
    end
  end
end
