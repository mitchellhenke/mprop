defmodule Properties.Indexer do
  @type gram_map :: %{optional(String.t) => MapSet.t}
  @type search_results :: list({String.t, float()})

  @gram_map File.read!("./priv/data/street_names_list.txt")
   |> String.split("\n", trim: true)
   |> Enum.reduce(%{}, fn(word, map) ->
     word = String.upcase(word)
     graphemes = String.graphemes("  #{word}  ")
                 |> Enum.map(&String.trim/1)
                 |> Enum.reject(&(&1 == ""))
     bigrams = Enum.chunk_every(graphemes, 2, 1)
     trigrams = Enum.chunk_every(graphemes, 3, 1)

     all_grams = bigrams ++ trigrams
     |> Enum.uniq

     gram_count = Enum.count(all_grams)

     Enum.reduce(all_grams, map, fn(gram, map) ->
       Map.update(map, gram, MapSet.new([{word, gram_count}]), fn(set) -> MapSet.put(set, {word, gram_count}) end)
     end)
    end)

  @spec search(String.t) :: search_results
  def search(word) do
    search(word, @gram_map)
  end

  @spec search(String.t, gram_map) :: search_results
  def search(word, gram_map) do
    grams = build_grams(word)
    Enum.reduce(grams, %{}, fn(gram, map) ->
      Map.get(gram_map, gram, [])
      |> Enum.reduce(map, fn({word, grams_count}, map) ->
        Map.update(map, word, 1/grams_count, &(&1 + 1/grams_count))
      end)
    end)
    |> Enum.sort(fn({_key, value}, {_key2, value2}) ->
      value >= value2
    end)
  end

  @spec build_grams(String.t) :: list(String.t)
  def build_grams(word) do
    word = String.upcase(word)
    graphemes = String.graphemes("  #{word}  ")
                |> Enum.map(&String.trim/1)
                |> Enum.reject(&(&1 == ""))
    bigrams = Enum.chunk_every(graphemes, 2, 1)
    trigrams = Enum.chunk_every(graphemes, 3, 1)
    bigrams ++ trigrams
    |> Enum.uniq
  end
end
